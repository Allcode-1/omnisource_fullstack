import asyncio
from typing import List, Dict, Any, Awaitable, Callable, TypeVar
from app.integrations.tmdb import TMDBClient
from app.integrations.google_books import GoogleBooksClient
from app.integrations.spotify import SpotifyClient
from app.utils.mappers import ContentMapper
from app.utils.sanitizer import ContentSanitizer
from app.schemas.content import UnifiedContent
from app.core.tags import get_tag_queries
from app.core.redis import redis_client
from app.core.logging import get_logger

logger = get_logger(__name__)
_T = TypeVar("_T")

class ContentService:
    def __init__(self):
        self.tmdb = TMDBClient()
        self.books = GoogleBooksClient()
        self.spotify = SpotifyClient()
        self.mapper = ContentMapper()
        self.sanitizer = ContentSanitizer()
        self._inflight_search: dict[str, asyncio.Task[list[UnifiedContent]]] = {}
        self._inflight_home: dict[str, asyncio.Task[dict[str, list[UnifiedContent]]]] = {}
        self._inflight_discovery: dict[str, asyncio.Task[list[UnifiedContent]]] = {}
        self._inflight_recommendations: dict[str, asyncio.Task[list[UnifiedContent]]] = {}

    async def _run_dedup(
        self,
        key: str,
        store: dict[str, asyncio.Task[_T]],
        factory: Callable[[], Awaitable[_T]],
    ) -> _T:
        task = store.get(key)
        if task is None:
            task = asyncio.create_task(factory())
            store[key] = task
        try:
            return await task
        finally:
            if store.get(key) is task:
                store.pop(key, None)

    async def get_unified_search(self, query: str, type: str = "all") -> List[UnifiedContent]:
        cache_key = f"search:{type}:{query.lower().strip()}"
        cached = await redis_client.get_cache(cache_key)
        if cached:
            return [UnifiedContent(**item) for item in cached]

        async def _build() -> list[UnifiedContent]:
            tasks = []
            i_map = []

            if type in ["all", "movie"]:
                tasks.append(self.tmdb.search_movies(query))
                i_map.append("movie")

            if type in ["all", "book"]:
                tasks.append(self.books.search_books(query))
                i_map.append("book")

            if type in ["all", "music"]:
                tasks.append(self.spotify.search_tracks(query))
                i_map.append("music")

            if not tasks:
                return []

            results_raw = await asyncio.gather(*tasks, return_exceptions=True)

            results = []
            for idx, raw in enumerate(results_raw):
                if isinstance(raw, Exception) or not isinstance(raw, dict):
                    continue

                current_type = i_map[idx]

                if current_type == "movie":
                    for item in raw.get("results", []):
                        try:
                            results.append(self.mapper.map_tmdb(item))
                        except Exception:
                            continue
                elif current_type == "book":
                    for item in raw.get("items", []):
                        try:
                            results.append(self.mapper.map_google_books(item))
                        except Exception:
                            continue
                elif current_type == "music":
                    for item in raw.get("tracks", {}).get("items", []):
                        try:
                            results.append(self.mapper.map_spotify(item))
                        except Exception:
                            continue

            valid_results = [
                r for r in results if r.external_id and r.title and self.sanitizer.is_valid(r)
            ]
            sorted_results = sorted(valid_results, key=lambda x: x.rating or 0, reverse=True)
            await redis_client.set_cache(
                cache_key,
                [r.model_dump() for r in sorted_results],
                expire=600,
            )
            return sorted_results

        return await self._run_dedup(cache_key, self._inflight_search, _build)

    async def get_home_data(self, type: str = "all") -> Dict[str, List[UnifiedContent]]:
        cache_key = f"home_data_v2_{type}"
        cached = await redis_client.get_cache(cache_key)
        if cached:
            return {k: [UnifiedContent(**i) for i in v] for k, v in cached.items()}

        async def _build() -> dict[str, list[UnifiedContent]]:
            tasks = [
                self.tmdb.get_popular_movies(),
                self.tmdb.get_top_rated_movies(),
                self.tmdb.search_movies("Action"),
                self.spotify.search_tracks("tag:new"),
                self.spotify.search_tracks("genre:rock"),
                self.spotify.search_tracks("genre:pop"),
                self.books.search_books("subject:fiction"),
                self.books.search_books("subject:thriller"),
                self.books.search_books("subject:history"),
            ]

            raw_res = await asyncio.gather(*tasks, return_exceptions=True)

            def wrap(data, mapper_func, type_key):
                if type != "all" and type_key != type:
                    return []
                if isinstance(data, Exception) or not isinstance(data, dict):
                    return []

                if type_key == "movie":
                    items = data.get("results", [])
                elif type_key == "book":
                    items = data.get("items", [])
                else:
                    tracks = data.get("tracks")
                    items = tracks.get("items", []) if isinstance(tracks, dict) else []

                mapped = []
                for item in items:
                    try:
                        mapped_item = mapper_func(item)
                        if (
                            mapped_item.external_id
                            and mapped_item.title
                            and self.sanitizer.is_valid(mapped_item)
                        ):
                            mapped.append(mapped_item)
                    except Exception:
                        continue
                return mapped[:15]

            result = {
                "Trending Now": wrap(raw_res[0], self.mapper.map_tmdb, "movie")
                + wrap(raw_res[3], self.mapper.map_spotify, "music")
                + wrap(raw_res[6], self.mapper.map_google_books, "book"),
                "Editor's Choice": wrap(raw_res[1], self.mapper.map_tmdb, "movie")
                + wrap(raw_res[4], self.mapper.map_spotify, "music")
                + wrap(raw_res[7], self.mapper.map_google_books, "book"),
                "New Releases": wrap(raw_res[3], self.mapper.map_spotify, "music")
                + wrap(raw_res[0], self.mapper.map_tmdb, "movie"),
                "Action & High Energy": wrap(raw_res[2], self.mapper.map_tmdb, "movie")
                + wrap(raw_res[5], self.mapper.map_spotify, "music"),
                "Must Read Classics": wrap(raw_res[6], self.mapper.map_google_books, "book"),
                "Discover Something New": wrap(raw_res[8], self.mapper.map_google_books, "book")
                + wrap(raw_res[1], self.mapper.map_tmdb, "movie")
                + wrap(raw_res[4], self.mapper.map_spotify, "music"),
            }

            filtered = {key: value for key, value in result.items() if value}
            serializable = {key: [item.model_dump() for item in value] for key, value in filtered.items()}
            await redis_client.set_cache(cache_key, serializable, expire=1800)
            return filtered

        return await self._run_dedup(cache_key, self._inflight_home, _build)

    async def get_discovery(self, tag: str) -> List[UnifiedContent]:
        cache_key = f"discovery:{tag.lower().strip()}"
        cached = await redis_client.get_cache(cache_key)
        if cached:
            return [UnifiedContent(**item) for item in cached]

        async def _build() -> list[UnifiedContent]:
            queries = get_tag_queries(tag)
            tasks = [
                self.tmdb.search_movies(queries.tmdb_keyword),
                self.books.search_books(f"subject:{queries.google_books_subject}"),
                self.spotify.search_tracks(f"genre:{queries.spotify_genre}"),
            ]
            results_raw = await asyncio.gather(*tasks, return_exceptions=True)
            results = []
            for index, raw in enumerate(results_raw):
                if isinstance(raw, Exception) or not isinstance(raw, dict):
                    continue
                try:
                    if index == 0:
                        for item in raw.get("results", []):
                            results.append(self.mapper.map_tmdb(item))
                    elif index == 1:
                        for item in raw.get("items", []):
                            results.append(self.mapper.map_google_books(item))
                    elif index == 2:
                        tracks = raw.get("tracks")
                        items = tracks.get("items", []) if isinstance(tracks, dict) else []
                        for item in items:
                            results.append(self.mapper.map_spotify(item))
                except Exception:
                    continue

            filtered = [
                item
                for item in results
                if item.external_id and item.title and self.sanitizer.is_valid(item)
            ]
            unique_items = self.sanitizer.get_unique(filtered, limit=30)
            await redis_client.set_cache(
                cache_key,
                [item.model_dump() for item in unique_items],
                expire=1200,
            )
            return unique_items

        return await self._run_dedup(cache_key, self._inflight_discovery, _build)

    async def get_recommendations(self, type: str = "all") -> List[UnifiedContent]:
        cache_key = f"recs_v2_{type}"
        cached = await redis_client.get_cache(cache_key)
        if cached:
            return [UnifiedContent(**item) for item in cached]

        async def _build() -> list[UnifiedContent]:
            results = []
            try:
                if type == "movie":
                    raw = await self.tmdb.get_top_rated_movies()
                    results = [self.mapper.map_tmdb(m) for m in (raw or {}).get("results", [])]
                elif type == "music":
                    raw = await self.spotify.search_tracks("tag:new")
                    tracks = (raw or {}).get("tracks", {})
                    track_items = tracks.get("items", []) if isinstance(tracks, dict) else []
                    results = [self.mapper.map_spotify(track) for track in track_items]
                elif type == "book":
                    raw = await self.books.search_books("subject:recommended")
                    results = [self.mapper.map_google_books(book) for book in (raw or {}).get("items", [])]
                else:
                    m_raw, s_raw, b_raw = await asyncio.gather(
                        self.tmdb.get_top_rated_movies(),
                        self.spotify.search_tracks("tag:new"),
                        self.books.search_books("subject:fiction"),
                        return_exceptions=True,
                    )
                    if not isinstance(m_raw, Exception) and m_raw:
                        results.extend([self.mapper.map_tmdb(m) for m in m_raw.get("results", [])[:5]])
                    if not isinstance(s_raw, Exception) and s_raw:
                        tracks = s_raw.get("tracks", {})
                        track_items = tracks.get("items", []) if isinstance(tracks, dict) else []
                        results.extend([self.mapper.map_spotify(track) for track in track_items[:5]])
                    if not isinstance(b_raw, Exception) and b_raw:
                        results.extend([self.mapper.map_google_books(book) for book in b_raw.get("items", [])[:5]])

            except Exception as exc:
                logger.exception("Critical service error in get_recommendations: %s", exc)
                return []

            valid_results = [item for item in results if self.sanitizer.is_valid(item)]
            if valid_results:
                await redis_client.set_cache(
                    cache_key,
                    [item.model_dump() for item in valid_results],
                    expire=600,
                )
            return valid_results

        return await self._run_dedup(cache_key, self._inflight_recommendations, _build)

    async def close(self) -> None:
        await asyncio.gather(
            self.tmdb.close(),
            self.books.close(),
            self.spotify.close(),
            return_exceptions=True,
        )
