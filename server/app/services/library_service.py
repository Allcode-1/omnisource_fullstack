import asyncio
from typing import List

from beanie.operators import In
from app.core.redis import redis_client
from app.models.content_meta import ContentMetadata, Playlist
from app.models.interaction import Interaction
from app.schemas.content import UnifiedContent
from app.ml.vectorizer import get_vectorizer
from app.core.logging import get_logger

logger = get_logger(__name__)


class LibraryService:
    @staticmethod
    def _favorites_cache_key(user_id: str, content_type: str | None) -> str:
        return f"favorites:{user_id}:{content_type or 'all'}"

    @staticmethod
    def _playlist_details_cache_key(user_id: str, playlist_id: str) -> str:
        return f"playlist_details:{user_id}:{playlist_id}"

    @staticmethod
    def _to_unified(doc: ContentMetadata) -> UnifiedContent:
        return UnifiedContent(
            id=f"{doc.type}_{doc.ext_id}",
            external_id=doc.ext_id,
            type=doc.type,
            title=doc.title,
            subtitle=doc.subtitle or doc.type.capitalize(),
            description=None,
            image_url=doc.image_url,
            rating=doc.rating or 0.0,
            genres=doc.genres or [],
            release_date=doc.release_date,
        )

    async def _invalidate_user_library_cache(
        self,
        user_id: str,
        playlist_id: str | None = None,
    ) -> None:
        await redis_client.delete_by_prefix(f"favorites:{user_id}:")
        if playlist_id:
            await redis_client.delete_cache(
                self._playlist_details_cache_key(user_id, playlist_id),
            )
        else:
            await redis_client.delete_by_prefix(f"playlist_details:{user_id}:")

    async def toggle_like(self, user_id: str, content: UnifiedContent):
        # 1. garant, if content metadata exists in our db for ml
        meta = await ContentMetadata.find_one(ContentMetadata.ext_id == content.external_id)
        if not meta:
            vector = await asyncio.to_thread(
                get_vectorizer().get_embedding,
                f"{content.title} {content.description or ''}",
            )
            meta = ContentMetadata(
                ext_id=content.external_id,
                type=content.type,
                title=content.title,
                subtitle=content.subtitle,
                image_url=content.image_url,
                rating=content.rating or 0.0,
                features_vector=vector
            )
            await meta.insert()

        # 2. check if like alr exists
        existing_like = await Interaction.find_one(
            Interaction.user_id == user_id,
            Interaction.ext_id == content.external_id,
            Interaction.type == "like"
        )

        if existing_like:
            await existing_like.delete()
            await self._invalidate_user_library_cache(user_id)
            logger.info("Removed like user=%s ext_id=%s", user_id, content.external_id)
            return {"status": "removed", "message": "Removed from favorites"}
        
        # 3. create new like with weight 1.0 (important for ml)
        new_like = Interaction(
            user_id=user_id,
            ext_id=content.external_id,
            type="like",
            weight=1.0 
        )
        await new_like.insert()
        await self._invalidate_user_library_cache(user_id)
        logger.info("Added like user=%s ext_id=%s", user_id, content.external_id)
        return {"status": "added", "message": "Added to favorites"}

    async def get_user_favorites(self, user_id: str, content_type: str = None):
        cache_key = self._favorites_cache_key(user_id, content_type)
        cached = await redis_client.get_cache(cache_key)
        if isinstance(cached, list):
            return [UnifiedContent.model_validate(item) for item in cached]

        # 1. get all likes of user
        interactions = await Interaction.find(
            Interaction.user_id == user_id,
            Interaction.type == "like",
        ).sort("-created_at").to_list()

        ordered_ids: list[str] = []
        seen_ids: set[str] = set()
        for interaction in interactions:
            ext_id = interaction.ext_id
            if not ext_id or ext_id in seen_ids:
                continue
            seen_ids.add(ext_id)
            ordered_ids.append(ext_id)

        if not ordered_ids:
            await redis_client.set_cache(cache_key, [], expire=120)
            return []  # if no likes - return empty list

        # 2. In operator to get all content metadata for those ids
        query = ContentMetadata.find(In(ContentMetadata.ext_id, ordered_ids))

        if content_type:
            query = query.find(ContentMetadata.type == content_type)

        docs = await query.to_list()
        rank = {ext_id: index for index, ext_id in enumerate(ordered_ids)}
        docs.sort(key=lambda doc: rank.get(doc.ext_id, 10**9))
        favorites = [self._to_unified(doc) for doc in docs]

        await redis_client.set_cache(
            cache_key,
            [item.model_dump(by_alias=True) for item in favorites],
            expire=120,
        )
        return favorites

    
    async def create_playlist(self, user_id: str, title: str, description: str = None):
        # create new playlist 
        clean_title = title.strip()
        if not clean_title:
            return {"status": "error", "message": "Playlist title is required"}
        playlist = Playlist(
            user_id=user_id,
            title=clean_title,
            description=description,
            items=[]  # empty list for start
        )
        await playlist.insert()
        await self._invalidate_user_library_cache(user_id)
        logger.info("Playlist created user=%s playlist_id=%s", user_id, playlist.id)
        return playlist

    async def get_user_playlists(self, user_id: str):
        # get all playlists of user
        return await Playlist.find(Playlist.user_id == user_id).to_list()

    async def update_playlist(
        self,
        user_id: str,
        playlist_id: str,
        title: str | None = None,
        description: str | None = None,
    ):
        playlist = await Playlist.get(playlist_id)
        if not playlist or playlist.user_id != user_id:
            return {"status": "error", "message": "Playlist not found"}

        if title is not None:
            clean_title = title.strip()
            if not clean_title:
                return {"status": "error", "message": "Playlist title is required"}
            playlist.title = clean_title
        if description is not None:
            playlist.description = description

        await playlist.save()
        await self._invalidate_user_library_cache(user_id, playlist_id)
        logger.info("Playlist updated user=%s playlist_id=%s", user_id, playlist_id)
        return playlist

    async def get_playlist_details(self, user_id: str, playlist_id: str):
        cache_key = self._playlist_details_cache_key(user_id, playlist_id)
        cached = await redis_client.get_cache(cache_key)
        if isinstance(cached, dict):
            return cached

        playlist = await Playlist.get(playlist_id)
        if not playlist or playlist.user_id != user_id:
            return None

        full_items = await ContentMetadata.find({"ext_id": {"$in": playlist.items}}).to_list()
        by_id = {item.ext_id: item for item in full_items}
        ordered_items = [
            self._to_unified(by_id[item_id])
            for item_id in playlist.items
            if item_id in by_id
        ]

        payload = {
            "id": str(playlist.id),
            "title": playlist.title,
            "description": playlist.description,
            "items": [item.model_dump(by_alias=True) for item in ordered_items],
        }
        await redis_client.set_cache(cache_key, payload, expire=120)
        return payload

    async def add_to_playlist(self, playlist_id: str, content: UnifiedContent):
        # 1. make sure content metadata exists for ml
        meta = await ContentMetadata.find_one(ContentMetadata.ext_id == content.external_id)
        if not meta:
            meta = ContentMetadata(
                ext_id=content.external_id,
                type=content.type,
                title=content.title,
                subtitle=content.subtitle,
                image_url=content.image_url,
                rating=content.rating or 0.0
            )
            await meta.insert()

        # 2. find playlist and add content if not already there
        playlist = await Playlist.get(playlist_id)
        if not playlist:
            return {"status": "error", "message": "Playlist not found"}
        
        if content.external_id not in playlist.items:
            playlist.items.append(content.external_id)
            await playlist.save()
            await self._invalidate_user_library_cache(playlist.user_id, playlist_id)
            logger.info("Added ext_id=%s to playlist=%s", content.external_id, playlist_id)
            return {"status": "success", "message": f"Added to {playlist.title}"}
        
        return {"status": "exists", "message": "Already in playlist"}

    async def remove_from_playlist(self, user_id: str, playlist_id: str, ext_id: str):
        playlist = await Playlist.get(playlist_id)
        if not playlist or playlist.user_id != user_id:
            return {"status": "error", "message": "Playlist not found"}

        if ext_id in playlist.items:
            playlist.items.remove(ext_id)
            await playlist.save()
            await self._invalidate_user_library_cache(user_id, playlist_id)

        return {"status": "success"}

    async def delete_playlist(self, user_id: str, playlist_id: str):
        playlist = await Playlist.get(playlist_id)
        if not playlist or playlist.user_id != user_id:
            return {"status": "error", "message": "Playlist not found"}
        await playlist.delete()
        await self._invalidate_user_library_cache(user_id, playlist_id)
        return {"status": "success"}
