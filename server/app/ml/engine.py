from typing import Optional, List
from app.models.interaction import Interaction
from app.models.content_meta import ContentMetadata
from app.ml.similarity import SimilarityManager
from app.ml.vectorizer import vectorizer
from app.schemas.content import UnifiedContent
from app.services.content_service import ContentService
from beanie.operators import In
import logging
import numpy as np

logger = logging.getLogger(__name__)


class RecommenderEngine:
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

        # 1. get all likes of current user
        user_likes = await Interaction.find(
            Interaction.user_id == user_id,
            Interaction.type == "like"
        ).to_list()

        if not user_likes:
            # if no likes return available content (optionally filtered by type)
            query = ContentMetadata.find()
            if content_type and content_type != "all":
                query = query.find(ContentMetadata.type == content_type)

            fallback = await query.limit(limit).to_list()
            logger.info(
                "No likes found for user=%s. Returning fallback_count=%s",
                user_id,
                len(fallback),
            )
            return fallback

        # 2. get vectors of liked content
        liked_ids = [i.ext_id for i in user_likes]
        liked_content = await ContentMetadata.find(In(ContentMetadata.ext_id, liked_ids)).to_list()

        user_vectors = [c.features_vector for c in liked_content if c.features_vector]

        if not user_vectors:
            logger.info("No vectors for liked content. user_id=%s", user_id)
            return []

        # 3. create user profile vector by averaging liked content vectors
        user_profile_vector = np.mean(user_vectors, axis=0).tolist()

        # 4. search for content that user didnt liked yet
        candidates_query = ContentMetadata.find(
            {"ext_id": {"$nin": liked_ids}} 
        )
        if content_type and content_type != "all":
            candidates_query = candidates_query.find(ContentMetadata.type == content_type)
        candidates = await candidates_query.to_list()

        # 5. score similarity between user profile and possible content
        scored_results = []
        for item in candidates:
            if not item.features_vector:
                continue
            
            score = self.similarity.calculate_cosine_similarity(user_profile_vector, item.features_vector)
            scored_results.append((score, item))

        # sort by score from top to bottom and return top results
        scored_results.sort(key=lambda x: x[0], reverse=True)

        logger.info(
            "ML filtering completed: user_id=%s candidates=%s scored=%s returned=%s",
            user_id,
            len(candidates),
            len(scored_results),
            min(limit, len(scored_results)),
        )
        return [item for score, item in scored_results[:limit]]

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

        tag_vector = vectorizer.get_embedding(tag)
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
