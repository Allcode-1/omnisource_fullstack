from fastapi import APIRouter, Depends, HTTPException, status
from app.schemas.content import UnifiedContent
from app.services.library_service import LibraryService
from app.api.deps import get_current_user 
from app.models.user import User
from app.models.content_meta import Playlist, ContentMetadata


router = APIRouter(prefix="/actions", tags=["Actions"])
library_service = LibraryService()


@router.post("/like")
async def toggle_like(
    content: UnifiedContent, 
    current_user: User = Depends(get_current_user)
):
    # like or unlike toggle
    return await library_service.toggle_like(str(current_user.id), content)


@router.get("/favorites")
async def get_favorites(
    type: str = None, 
    current_user: User = Depends(get_current_user)
):
    # get list of all liked content
    return await library_service.get_user_favorites(str(current_user.id), type)


@router.post("/playlists")
async def create_new_playlist(
    title: str, 
    description: str = None, 
    current_user: User = Depends(get_current_user)
):
    # create empty playlist for user
    return await library_service.create_playlist(str(current_user.id), title, description)


@router.get("/playlists")
async def get_my_playlists(current_user: User = Depends(get_current_user)):
    # show all user playlists with content inside
    return await library_service.get_user_playlists(str(current_user.id))


@router.get("/playlists/{playlist_id}")
async def get_playlist_details(
    playlist_id: str,
    user=Depends(get_current_user)
):
    # 1. search playlist
    playlist = await Playlist.get(playlist_id)
    
    if not playlist or playlist.user_id != str(user.id):
        raise HTTPException(status_code=404, detail="Playlist not found")

    # 2. get all data about playlist (content inside)
    full_items = await ContentMetadata.find(
        {"ext_id": {"$in": playlist.items}}
    ).to_list()

    # 3. return playlist with all data with it
    return {
        "id": str(playlist.id),
        "title": playlist.title,
        "description": playlist.description,
        "is_public": playlist.is_public,
        "items": full_items  
    }


@router.delete("/playlists/{playlist_id}")
async def delete_playlist(
    playlist_id: str, 
    current_user: User = Depends(get_current_user)
):
    playlist = await Playlist.get(playlist_id)
    if not playlist or playlist.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Playlist not found or access denied")
    
    await playlist.delete()
    return {"message": "Playlist deleted"}


@router.post("/playlists/{playlist_id}/add")
async def add_item_to_playlist(
    playlist_id: str,
    content: UnifiedContent,
    current_user: User = Depends(get_current_user)
):
    # check owner before adding
    playlist = await Playlist.get(playlist_id)
    if not playlist or playlist.user_id != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not your playlist!")
        
    return await library_service.add_to_playlist(playlist_id, content)

@router.delete("/playlists/{playlist_id}/remove/{ext_id}")
async def remove_item_from_playlist(
    playlist_id: str,
    ext_id: str,
    current_user: User = Depends(get_current_user)
):
    playlist = await Playlist.get(playlist_id)
    if not playlist or playlist.user_id != str(current_user.id):
        raise HTTPException(status_code=403, detail="Access denied")
    
    if ext_id in playlist.items:
        playlist.items.remove(ext_id)
        await playlist.save()
    
    return playlist