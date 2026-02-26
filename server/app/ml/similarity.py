import numpy as np

class SimilarityManager:
    @staticmethod
    def calculate_cosine_similarity(vec1: list[float], vec2: list[float]) -> float:
        if not vec1 or not vec2:
            return 0.0
        
        a = np.array(vec1)
        b = np.array(vec2)
        
        dot_product = np.dot(a, b)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        
        if norm_a == 0 or norm_b == 0:
            return 0.0
            
        return float(dot_product / (norm_a * norm_b))

    @staticmethod
    def genres_to_vector(all_genres: list[str], target_genres: list[str]) -> list[float]:
        # simple bynar code: 1 if true and 0 if false
        return [1.0 if genre in target_genres else 0.0 for genre in all_genres]