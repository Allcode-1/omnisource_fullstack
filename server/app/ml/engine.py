import asyncio
from typing import Optional, List
from app.models.interaction import Interaction
from app.models.content_meta import ContentMetadata
from app.ml.similarity import SimilarityManager
from app.ml.vectorizer import get_vectorizer
from app.schemas.content import UnifiedContent
from app.services.content_service import ContentService
from beanie.operators import In
import numpy as np
from app.core.logging import get_logger

logger = get_logger(__name__)


class RecommenderEngine:
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

        interaction_weight_by_id: dict[str, float] = {}
        liked_ids = set()
        for interaction in interactions:
            if not interaction.ext_id or interaction.ext_id == "app":
                continue
            base_weight = self.EVENT_WEIGHTS.get(interaction.type, 0.1)
            final_weight = float(interaction.weight or base_weight)
            interaction_weight_by_id[interaction.ext_id] = (
                interaction_weight_by_id.get(interaction.ext_id, 0.0) + final_weight
            )
            if interaction.type == "like":
                liked_ids.add(interaction.ext_id)

        if not interaction_weight_by_id:
            logger.info("No vectorizable interactions for user=%s", user_id)
            return []

        interaction_docs = await ContentMetadata.find(
            In(ContentMetadata.ext_id, list(interaction_weight_by_id.keys()))
        ).to_list()

        weighted_vectors = []
        total_weight = 0.0
        for doc in interaction_docs:
            if not doc.features_vector:
                continue
            weight = interaction_weight_by_id.get(doc.ext_id, 0.0)
            if weight <= 0:
                continue
            weighted_vectors.append(np.array(doc.features_vector) * weight)
            total_weight += weight

        if not weighted_vectors or total_weight == 0:
            logger.info("No vectors in interaction docs for user=%s", user_id)
            return []

        user_profile_vector = (np.sum(weighted_vectors, axis=0) / total_weight).tolist()

        # Exclude content already interacted with heavily.
        candidates_query = ContentMetadata.find(
            {"ext_id": {"$nin": list(interaction_weight_by_id.keys())}}
        )
        if content_type and content_type != "all":
            candidates_query = candidates_query.find(ContentMetadata.type == content_type)
        candidates = await candidates_query.to_list()

        scored_results = []
        for item in candidates:
            if not item.features_vector:
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
            "ML filtering completed: user_id=%s events=%s candidates=%s scored=%s returned=%s",
            user_id,
            len(interactions),
            len(candidates),
            len(scored_results),
            min(limit, len(scored_results)),
        )
        return [item for _, item in scored_results[:limit]]

    async def get_deep_research(
        self,
        tag: str,
        content_type: Optional[str] = None,
        limit: int = 20,
    ) -> List[UnifiedContent]:
        logger.info(
            "Deep research started: tag=%s type=%s limit=%s",
            tag,
            content_type,
            limit,
        )

        tag_vector = await asyncio.to_thread(get_vectorizer().get_embedding, tag)
        if not tag_vector:
            logger.warning("Tag vector is empty for tag=%s. Using discovery fallback.", tag)
            fallback = await self.content_service.get_discovery(tag)
            if content_type and content_type != "all":
                fallback = [item for item in fallback if item.type == content_type]
            return fallback[:limit]

        query = ContentMetadata.find()
        if content_type and content_type != "all":
            query = query.find(ContentMetadata.type == content_type)
        candidates = await query.to_list()

        scored_results = []
        for item in candidates:
            if not item.features_vector:
                continue

            score = self.similarity.calculate_cosine_similarity(tag_vector, item.features_vector)
            scored_results.append((score, item))

        scored_results.sort(key=lambda x: x[0], reverse=True)
        filtered = [item for score, item in scored_results if score > 0]

        if not filtered:
            logger.info("No vector matches for tag=%s. Using discovery fallback.", tag)
            fallback = await self.content_service.get_discovery(tag)
            if content_type and content_type != "all":
                fallback = [item for item in fallback if item.type == content_type]
            return fallback[:limit]

        result = [self._to_unified_content(item) for item in filtered[:limit]]
        logger.info(
            "Deep research filtering completed: tag=%s candidates=%s matched=%s returned=%s",
            tag,
            len(candidates),
            len(filtered),
            len(result),
        )
        return result

    async def close(self) -> None:
        await self.content_service.close()
