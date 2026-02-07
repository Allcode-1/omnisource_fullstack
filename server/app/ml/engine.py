from typing import Optional, List 
from app.models.interaction import Interaction
from app.models.content_meta import ContentMetadata
from app.ml.similarity import SimilarityManager
from beanie.operators import In 
import numpy as np
import logging

logger = logging.getLogger(__name__)

class RecommenderEngine:
    def __init__(self):
        self.similarity = SimilarityManager()

    async def get_recommendations(self, user_id: str, content_type: Optional[str] = None, limit: int = 10):
        # 1. get all likes of current user
        user_likes = await Interaction.find(
            Interaction.user_id == user_id,
            Interaction.type == "like"
        ).to_list()

        if not user_likes:
            # if no likes return popular content of the same type
            return await ContentMetadata.find(ContentMetadata.type == content_type).limit(limit).to_list()

        # 2. get vectors of liked content
        liked_ids = [i.ext_id for i in user_likes]
        liked_content = await ContentMetadata.find(In(ContentMetadata.ext_id, liked_ids)).to_list()
        
        user_vectors = [c.features_vector for c in liked_content if c.features_vector]
        
        if not user_vectors:
            return []

        # 3. create user profile vector by averaging liked content vectors
        user_profile_vector = np.mean(user_vectors, axis=0).tolist()

        # 4. search for content that user didnt liked yet
        candidates = await ContentMetadata.find(
            {"ext_id": {"$nin": liked_ids}} 
        ).to_list()

        # 5. score similarity between user profile and possible content
        scored_results = []
        for item in candidates:
            if not item.features_vector:
                continue
            
            score = self.similarity.calculate_cosine_similarity(user_profile_vector, item.features_vector)
            scored_results.append((score, item))

        # sort by score from top to bottom and return top results
        scored_results.sort(key=lambda x: x[0], reverse=True)
        
        return [item for score, item in scored_results[:limit]]