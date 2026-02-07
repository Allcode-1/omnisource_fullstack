from app.models.content_meta import ContentMetadata, Playlist
from app.models.interaction import Interaction
from app.schemas.content import UnifiedContent
from typing import List
from beanie.operators import In
from app.ml.vectorizer import vectorizer

class LibraryService:
    async def toggle_like(self, user_id: str, content: UnifiedContent):
        # 1. garant, if content metadata exists in our db for ml
        meta = await ContentMetadata.find_one(ContentMetadata.ext_id == content.external_id)
        if not meta:
            vector = vectorizer.get_embedding(f"{content.title} {content.description or ''}")
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
            return {"status": "removed", "message": "Removed from favorites"}
        
        # 3. create new like with weight 1.0 (important for ml)
        new_like = Interaction(
            user_id=user_id,
            ext_id=content.external_id,
            type="like",
            weight=1.0 
        )
        await new_like.insert()
        return {"status": "added", "message": "Added to favorites"}

    async def get_user_favorites(self, user_id: str, content_type: str = None):
        # 1. get all likes of user
        interactions = await Interaction.find(
            Interaction.user_id == user_id, 
            Interaction.type == "like"
        ).to_list()
        
        ids = [i.ext_id for i in interactions]
        
        if not ids:
            return [] # if no likes - return empty list

        # 2. In operator to get all content metadata for those ids
        query = ContentMetadata.find(In(ContentMetadata.ext_id, ids))
        
        if content_type:
            query = query.find(ContentMetadata.type == content_type)
            
        return await query.to_list()

    
    async def create_playlist(self, user_id: str, title: str, description: str = None):
        # create new playlist 
        playlist = Playlist(
            user_id=user_id,
            title=title,
            description=description,
            items=[]  # empty list for start
        )
        await playlist.insert()
        return playlist

    async def get_user_playlists(self, user_id: str):
        # get all playlists of user
        return await Playlist.find(Playlist.user_id == user_id).to_list()

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
            return {"status": "success", "message": f"Added to {playlist.title}"}
        
        return {"status": "exists", "message": "Already in playlist"}