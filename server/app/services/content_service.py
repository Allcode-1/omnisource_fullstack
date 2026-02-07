import asyncio
from typing import List, Dict, Any
from app.integrations.tmdb import TMDBClient
from app.integrations.google_books import GoogleBooksClient
from app.integrations.spotify import SpotifyClient
from app.utils.mappers import ContentMapper
from app.utils.sanitizer import ContentSanitizer
from app.schemas.content import UnifiedContent
from app.core.tags import get_tag_queries
from app.core.redis import redis_client 



class ContentService:
    def __init__(self):
        self.tmdb = TMDBClient()
        self.books = GoogleBooksClient()
        self.spotify = SpotifyClient()
        self.mapper = ContentMapper()
        self.sanitizer = ContentSanitizer()

    async def get_unified_search(self, query: str) -> List[UnifiedContent]:
        cache_key = f"search:{query.lower().strip()}"
        cached = await redis_client.get_cache(cache_key)
        if cached:
            return [UnifiedContent(**item) for item in cached]

        tasks = [
            self.tmdb.search_movies(query), 
            self.books.search_books(query), 
            self.spotify.search_tracks(query)
        ]
        movies_raw, books_raw, tracks_raw = await asyncio.gather(*tasks, return_exceptions=True)
        
        results = []
        if isinstance(movies_raw, dict): 
            results.extend([self.mapper.map_tmdb(m) for m in movies_raw.get("results", [])])
        if isinstance(books_raw, dict): 
            results.extend([self.mapper.map_google_books(b) for b in books_raw.get("items", [])])
        if isinstance(tracks_raw, dict): 
            results.extend([self.mapper.map_spotify(t) for t in tracks_raw.get("tracks", {}).get("items", [])])
        
        sorted_results = sorted(results, key=lambda x: x.rating or 0, reverse=True)
        
        await redis_client.set_cache(cache_key, [r.model_dump() for r in sorted_results], expire=600)
        return sorted_results



    async def get_home_data(self) -> Dict[str, List[UnifiedContent]]:
        cache_key = "home_data_v1"
        cached = await redis_client.get_cache(cache_key)
        if cached:
            return cached

        tasks = [
            self.tmdb.get_popular_movies(), 
            self.books.search_books("subject:fiction"), 
            self.spotify.search_tracks("year:2026") 
        ]
        m, b, t = await asyncio.gather(*tasks, return_exceptions=True)

        def process_raw_data(raw, mapper_func, type_key):
            if not isinstance(raw, dict): return []
            if type_key == "movie": items = raw.get("results", [])
            elif type_key == "book": items = raw.get("items", [])
            else: items = raw.get("tracks", {}).get("items", [])

            mapped = [mapper_func(i) for i in items]
            cleaned = [i for i in mapped if self.sanitizer.is_valid(i)]
            return self.sanitizer.get_unique(cleaned, limit=10)
        
        res = {
            "trending_movies": process_raw_data(m, self.mapper.map_tmdb, "movie"),
            "popular_books": process_raw_data(b, self.mapper.map_google_books, "book"),
            "top_tracks": process_raw_data(t, self.mapper.map_spotify, "music")
        }

        serializable_res = {k: [i.model_dump() for i in v] for k, v in res.items()}
        await redis_client.set_cache(cache_key, serializable_res, expire=1800)
        return res



    async def get_discovery(self, tag: str) -> List[UnifiedContent]:
        cache_key = f"discovery:{tag.lower()}"
        cached = await redis_client.get_cache(cache_key)
        if cached:
            return [UnifiedContent(**item) for item in cached]

        queries = get_tag_queries(tag)
        tasks = [
            self.tmdb.search_movies(queries.tmdb_keyword),
            self.books.search_books(f"subject:{queries.google_books_subject}"),
            self.spotify.search_tracks(f"genre:{queries.spotify_genre}")
        ]
        
        m, b, t = await asyncio.gather(*tasks, return_exceptions=True)
        
        all_results = []
        if isinstance(m, dict): all_results.extend([self.mapper.map_tmdb(i) for i in m.get("results", [])])
        if isinstance(b, dict): all_results.extend([self.mapper.map_google_books(i) for i in b.get("items", [])])
        if isinstance(t, dict): all_results.extend([self.mapper.map_spotify(i) for i in t.get("tracks", {}).get("items", [])])

        cleaned = [i for i in all_results if self.sanitizer.is_valid(i)]
        unique_results = self.sanitizer.get_unique(cleaned, limit=30)

        await redis_client.set_cache(cache_key, [r.model_dump() for r in unique_results], expire=3600)
        return unique_results