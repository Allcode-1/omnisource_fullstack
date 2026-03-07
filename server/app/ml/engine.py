import asyncio
from collections import Counter
from typing import Optional, List
from app.models.interaction import Interaction
from app.models.content_meta import ContentMetadata
from app.core.content_keys import make_content_key, split_content_key
from app.ml.similarity import SimilarityManager
from app.ml.vectorizer import get_vectorizer
from app.schemas.content import UnifiedContent
from app.core.redis import redis_client
from app.services.content_service import ContentService
from beanie.operators import In
import numpy as np
from app.core.logging import get_logger

logger = get_logger(__name__)


class RecommenderEngine:
    MIN_DEEP_VECTOR_CANDIDATES = 25

    EVENT_WEIGHTS = {
        "view": 0.2,
        "open_detail": 0.5,
        "dwell_time": 0.3,
        "like": 1.0,
        "playlist_add": 0.8,
    }

    def __init__(self):
        self.similarity = SimilarityManager()
        self.content_service = ContentService()

    @staticmethod
    def _to_unified_content(item: ContentMetadata) -> UnifiedContent:
        return UnifiedContent(
            id=f"{item.type}_{item.ext_id}",
            external_id=item.ext_id,
            type=item.type,
            title=item.title,
            subtitle=item.subtitle or item.type.capitalize(),
            description=None,
            image_url=item.image_url,
            rating=item.rating or 0.0,
            genres=item.genres or [],
            release_date=item.release_date,
        )

    async def get_recommendations(
        self,
        user_id: str,
        content_type: Optional[str] = None,
        limit: int = 10,
    ):
        logger.info(
            "Building recommendations: user_id=%s type=%s limit=%s",
            user_id,
            content_type,
            limit,
        )

        interactions = await Interaction.find(
            Interaction.user_id == user_id,
            In(Interaction.type, list(self.EVENT_WEIGHTS.keys())),
        ).to_list()

        if not interactions:
            query = ContentMetadata.find()
            if content_type and content_type != "all":
                query = query.find(ContentMetadata.type == content_type)

            fallback = await query.limit(limit).to_list()
            logger.info(
                "No interactions found for user=%s. Returning fallback_count=%s",
                user_id,
                len(fallback),
            )
            return fallback

        interaction_weight_by_ref: dict[str, float] = {}
        for interaction in interactions:
            if not interaction.ext_id or interaction.ext_id == "app":
                continue
            content_ref = (
                getattr(interaction, "content_key", None)
                or make_content_key(getattr(interaction, "content_type", None), interaction.ext_id)
                or interaction.ext_id
            )
            if not content_ref:
                continue
            base_weight = self.EVENT_WEIGHTS.get(interaction.type, 0.1)
            final_weight = float(interaction.weight or base_weight)
            interaction_weight_by_ref[content_ref] = (
                interaction_weight_by_ref.get(content_ref, 0.0) + final_weight
            )

        if not interaction_weight_by_ref:
            logger.info("No vectorizable interactions for user=%s", user_id)
            return []

        supports_content_key = hasattr(ContentMetadata, "content_key")
        interaction_refs = list(interaction_weight_by_ref.keys())
        if supports_content_key:
            interaction_or_filters: list[dict] = []
            keyed_refs = [ref for ref in interaction_refs if ":" in ref]
            legacy_refs = [ref for ref in interaction_refs if ":" not in ref]
            if keyed_refs:
                interaction_or_filters.append({"content_key": {"$in": keyed_refs}})
            if legacy_refs:
                interaction_or_filters.append({"ext_id": {"$in": legacy_refs}})
            for ref in interaction_refs:
                ref_type, ref_ext_id = split_content_key(ref)
                if ref_type and ref_ext_id:
                    interaction_or_filters.append({"type": ref_type, "ext_id": ref_ext_id})
            if not interaction_or_filters:
                logger.info("No metadata refs to build profile for user=%s", user_id)
                return []
            interaction_docs = await ContentMetadata.find({"$or": interaction_or_filters}).to_list()
        else:
            ref_ext_ids: list[str] = []
            for ref in interaction_refs:
                ref_type, ref_ext_id = split_content_key(ref)
                ref_ext_ids.append(ref_ext_id if ref_type and ref_ext_id else ref)
            if not ref_ext_ids:
                logger.info("No metadata refs to build profile for user=%s", user_id)
                return []
            interaction_docs = await ContentMetadata.find(
                In(ContentMetadata.ext_id, list(dict.fromkeys(ref_ext_ids))),
            ).to_list()

        weighted_vectors = []
        vector_dims: Counter[int] = Counter()
        for doc in interaction_docs:
            if not doc.features_vector:
                continue
            doc_ref = (
                getattr(doc, "content_key", None)
                or make_content_key(doc.type, doc.ext_id)
                or doc.ext_id
            )
            weight = interaction_weight_by_ref.get(
                doc_ref,
                interaction_weight_by_ref.get(doc.ext_id, 0.0),
            )
            if weight <= 0:
                continue
            vector_dims[len(doc.features_vector)] += 1
            weighted_vectors.append((np.array(doc.features_vector), weight))

        if not weighted_vectors:
            logger.info("No vectors in interaction docs for user=%s", user_id)
            return []

        target_dim = vector_dims.most_common(1)[0][0]
        total_weight = 0.0
        compatible_weighted_vectors = []
        skipped_history_mismatch = 0
        for vector, weight in weighted_vectors:
            if vector.shape[0] != target_dim:
                skipped_history_mismatch += 1
                continue
            compatible_weighted_vectors.append(vector * weight)
            total_weight += weight

        if not compatible_weighted_vectors or total_weight == 0:
            logger.info("No vectors in interaction docs for user=%s", user_id)
            return []

        user_profile_vector = (
            np.sum(compatible_weighted_vectors, axis=0) / total_weight
        ).tolist()

        # Exclude already seen content and skip docs without vectors.
        candidates_filter: dict[str, object] = {
            "features_vector.0": {"$exists": True},
        }
        if not supports_content_key:
            excluded_ext_ids = [
                split_content_key(ref)[1] if split_content_key(ref)[1] else ref
                for ref in interaction_weight_by_ref.keys()
            ]
            candidates_filter["ext_id"] = {"$nin": excluded_ext_ids}
        if content_type and content_type != "all":
            candidates_filter["type"] = content_type
        candidates = await ContentMetadata.find(candidates_filter).to_list()

        seen_refs = set(interaction_weight_by_ref.keys())
        scored_results = []
        skipped_candidates_mismatch = 0
        for item in candidates:
            if not item.features_vector:
                continue
            item_ref = (
                getattr(item, "content_key", None)
                or make_content_key(item.type, item.ext_id)
                or item.ext_id
            )
            if item_ref in seen_refs or item.ext_id in seen_refs:
                continue
            if len(item.features_vector) != target_dim:
                skipped_candidates_mismatch += 1
                continue

            similarity_score = self.similarity.calculate_cosine_similarity(
                user_profile_vector,
                item.features_vector,
            )
            rating_score = max(0.0, min((item.rating or 0.0) / 10.0, 1.0))
            hybrid_score = similarity_score * 0.85 + rating_score * 0.15
            scored_results.append((hybrid_score, item))

        scored_results.sort(key=lambda x: x[0], reverse=True)

        logger.info(
            "ML filtering completed: user_id=%s events=%s candidates=%s scored=%s returned=%s target_dim=%s skipped_history_mismatch=%s skipped_candidates_mismatch=%s",
            user_id,
            len(interactions),
            len(candidates),
            len(scored_results),
            min(limit, len(scored_results)),
            target_dim,
            skipped_history_mismatch,
            skipped_candidates_mismatch,
        )
        return [item for _, item in scored_results[:limit]]

    async def get_deep_research(
        self,
        tag: str,
        content_type: Optional[str] = None,
        limit: int = 20,
    ) -> List[UnifiedContent]:
        normalized_tag = tag.strip().lower()
        resolved_type = content_type if content_type and content_type != "all" else "all"
        cache_key = f"deep_research:{resolved_type}:{limit}:{normalized_tag}"
        cached = await redis_client.get_cache(cache_key)
        if isinstance(cached, list):
            return [UnifiedContent.model_validate(item) for item in cached]

        logger.info(
            "Deep research started: tag=%s type=%s limit=%s",
            tag,
            content_type,
            limit,
        )

        def _filter_discovery(items: List[UnifiedContent]) -> List[UnifiedContent]:
            if content_type and content_type != "all":
                return [item for item in items if item.type == content_type]
            return items

        async def _return_discovery(reason: str) -> List[UnifiedContent]:
            logger.info(
                "Using discovery fallback for tag=%s reason=%s type=%s",
                tag,
                reason,
                content_type,
            )
            fallback = _filter_discovery(await self.content_service.get_discovery(tag))
            result = fallback[:limit]
            await redis_client.set_cache(
                cache_key,
                [item.model_dump() for item in result],
                expire=900,
            )
            return result

        tag_vector = await asyncio.to_thread(get_vectorizer().get_embedding, tag)
        if not tag_vector:
            logger.warning("Tag vector is empty for tag=%s", tag)
            return await _return_discovery("empty_tag_vector")
        tag_dim = len(tag_vector)

        query_filter: dict[str, object] = {"features_vector.0": {"$exists": True}}
        if content_type and content_type != "all":
            query_filter["type"] = content_type
        candidates = await ContentMetadata.find(query_filter).to_list()
        compatible_candidates = [
            item
            for item in candidates
            if item.features_vector and len(item.features_vector) == tag_dim
        ]

        if len(compatible_candidates) < self.MIN_DEEP_VECTOR_CANDIDATES:
            return await _return_discovery(
                f"small_vector_pool_{len(compatible_candidates)}"
            )

        scored_results = []
        for item in compatible_candidates:
            if not item.features_vector:
                continue

            score = self.similarity.calculate_cosine_similarity(tag_vector, item.features_vector)
            scored_results.append((score, item))

        scored_results.sort(key=lambda x: x[0], reverse=True)
        filtered = [item for score, item in scored_results if score > 0]

        if not filtered:
            return await _return_discovery("no_positive_scores")

        result = [self._to_unified_content(item) for item in filtered[:limit]]
        if len(result) < limit:
            # Fill the tail with tag-based discovery to avoid undersized result sets.
            discovery = _filter_discovery(await self.content_service.get_discovery(tag))
            merged: dict[str, UnifiedContent] = {
                f"{item.type}:{item.external_id}": item for item in result
            }
            for item in discovery:
                key = f"{item.type}:{item.external_id}"
                if key in merged:
                    continue
                merged[key] = item
                if len(merged) >= limit:
                    break
            result = list(merged.values())[:limit]

        await redis_client.set_cache(
            cache_key,
            [item.model_dump() for item in result],
            expire=900,
        )
        logger.info(
            "Deep research filtering completed: tag=%s candidates=%s compatible_candidates=%s matched=%s returned=%s",
            tag,
            len(candidates),
            len(compatible_candidates),
            len(filtered),
            len(result),
        )
        return result

    async def close(self) -> None:
        await self.content_service.close()
