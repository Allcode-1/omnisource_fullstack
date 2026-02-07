import re
import torch
import numpy as np
from typing import List, Optional
from sentence_transformers import SentenceTransformer
import logging

logger = logging.getLogger(__name__)

class ContentVectorizer:
    def __init__(self, model_name: str = 'paraphrase-multilingual-MiniLM-L12-v2'):
        self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        # load model with specified device
        self.model = SentenceTransformer(model_name, device=self.device)
        logger.info(f"🚀 Vectorizer initialized on {self.device}")

    def _clean_text(self, text: str) -> str:
        # cleaning text: lowercasing, removing HTML tags and punctuation
        if not text:
            return ""
        text = text.lower()
        text = re.sub(r'<.*?>', '', text)  # delete html
        text = re.sub(r'[^\w\s]', '', text) # delete punctuation
        return text.strip()

    def get_embedding(self, text: str) -> List[float]:
        # vector generating for single text
        cleaned = self._clean_text(text)
        if not cleaned:
            return []
        
        with torch.no_grad(): # no gradients for economy
            embedding = self.model.encode(cleaned, convert_to_numpy=True)
        return embedding.tolist()

    def get_batch_embeddings(self, texts: List[str]) -> List[List[float]]:
        # vector generating for batch of texts
        cleaned_texts = [self._clean_text(t) for t in texts if t]
        if not cleaned_texts:
            return []

        with torch.no_grad():
            embeddings = self.model.encode(cleaned_texts, batch_size=32, show_progress_bar=False)
        return embeddings.tolist()

# create singletone for speed
vectorizer = ContentVectorizer()