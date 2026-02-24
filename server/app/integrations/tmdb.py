import httpx
from typing import Dict, Any
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class TMDBClient:
    def __init__(self):
        self.api_key = settings.TMDB_API_KEY
        self.base_url = "https://api.themoviedb.org/3"
        self.headers = {
            "accept": "application/json",
            "Content-Type": "application/json"
        }

    async def _make_request(self, endpoint: str, params: Dict[str, Any]) -> Dict[str, Any]:
        default_params = {
            "api_key": self.api_key,
            "language": "en-US"
        }
        combined_params = {**default_params, **params}
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(
                    f"{self.base_url}/{endpoint}",
                    headers=self.headers,
                    params=combined_params,
                    timeout=10.0
                )
                
                if response.status_code != 200:
                    logger.error(
                        "TMDB API Error: %s - %s",
                        response.status_code,
                        response.text,
                    )
                
                response.raise_for_status()
                return response.json()
            except Exception as e:
                logger.exception("TMDB request failed on %s: %s", endpoint, e)
                return {"results": []}

    async def search_movies(self, query: str) -> Dict[str, Any]:
        if not query: return {"results": []}
        return await self._make_request("search/movie", {"query": query, "page": 1})

    async def get_popular_movies(self) -> Dict[str, Any]:
        return await self._make_request("trending/movie/day", {})

    async def get_top_rated_movies(self) -> Dict[str, Any]:
        return await self._make_request("movie/top_rated", {})

    async def get_movie_details(self, movie_id: int) -> Dict[str, Any]:
        return await self._make_request(f"movie/{movie_id}", {})

tmdb_client = TMDBClient()
