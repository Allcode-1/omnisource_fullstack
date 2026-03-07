import httpx
import asyncio
from typing import Dict, Any
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

class TMDBClient:
    def __init__(self):
        self.api_key = settings.TMDB_API_KEY
        self.base_url = "https://api.themoviedb.org/3"
        self.headers = {
            "accept": "application/json",
            "Content-Type": "application/json"
        }
        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(10.0, connect=3.0, read=10.0),
            limits=httpx.Limits(max_connections=30, max_keepalive_connections=15),
        )

    async def _make_request(self, endpoint: str, params: Dict[str, Any]) -> Dict[str, Any]:
        default_params = {
            "api_key": self.api_key,
            "language": "en-US"
        }
        combined_params = {**default_params, **params}
        url = f"{self.base_url}/{endpoint}"

        for attempt in range(3):
            try:
                response = await self._client.get(
                    url,
                    headers=self.headers,
                    params=combined_params,
                )
                if response.status_code == 200:
                    return response.json()

                if response.status_code in (429, 500, 502, 503, 504) and attempt < 2:
                    await asyncio.sleep(0.3 * (attempt + 1))
                    continue

                logger.warning(
                    "TMDB API non-200 endpoint=%s status=%s body=%s",
                    endpoint,
                    response.status_code,
                    response.text[:200],
                )
                break
            except Exception as exc:
                if attempt < 2:
                    await asyncio.sleep(0.3 * (attempt + 1))
                    continue
                message = str(exc).strip() or type(exc).__name__
                logger.warning("TMDB request failed endpoint=%s error=%s", endpoint, message)

        return {"results": []}

    async def search_movies(self, query: str) -> Dict[str, Any]:
        if not query:
            return {"results": []}
        return await self._make_request("search/movie", {"query": query, "page": 1})

    async def get_popular_movies(self) -> Dict[str, Any]:
        return await self._make_request("trending/movie/day", {})

    async def get_top_rated_movies(self) -> Dict[str, Any]:
        return await self._make_request("movie/top_rated", {})

    async def get_movie_details(self, movie_id: int) -> Dict[str, Any]:
        return await self._make_request(f"movie/{movie_id}", {})

    async def close(self) -> None:
        await self._client.aclose()

tmdb_client = TMDBClient()
