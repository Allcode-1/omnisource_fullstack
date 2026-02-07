import httpx
from typing import Dict, Any, Optional
from app.core.config import settings

class TMDBClient:
    def __init__(self):
        self.token = settings.TMDB_API_KEY
        self.base_url = "https://api.themoviedb.org/3"
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "accept": "application/json"
        }

    async def _make_request(self, endpoint: str, params: Dict[str, Any]) -> Dict[str, Any]:
        # basic parametres that ALWAYS needed
        default_params = {
            "language": "en-US",
            "include_adult": "false"
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
                response.raise_for_status()
                return response.json()
            except Exception as e:
                print(f"TMDB Error on {endpoint}: {e}")
                return {"results": []}

    async def search_movies(self, query: str) -> Dict[str, Any]:
        # non filters, only request
        if not query:
            return {"results": []}
        return await self._make_request("search/movie", {"query": query, "page": 1})

    async def get_popular_movies(self) -> Dict[str, Any]:
        # trending than popular, more stable
        # trending/movie/day returns most actual content for today
        return await self._make_request("trending/movie/day", {})

    async def get_movie_details(self, movie_id: int) -> Dict[str, Any]:
        return await self._make_request(f"movie/{movie_id}", {})