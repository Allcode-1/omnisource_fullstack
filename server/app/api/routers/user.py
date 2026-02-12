from fastapi import APIRouter, Depends, status
from app.models.user import User
from app.models.interaction import Interaction
from app.models.content_meta import Playlist
from app.schemas.user import UserRead, UserUpdate, OnboardingComplete
from app.api.deps import get_current_user

router = APIRouter(prefix="/user", tags=["user"])

@router.get("/me", response_model=UserRead)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.patch("/update", response_model=UserRead)
async def update_user(data: UserUpdate, current_user: User = Depends(get_current_user)):
    update_dict = data.model_dump(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(current_user, key, value)
    
    await current_user.save()
    return current_user

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(current_user: User = Depends(get_current_user)):
    # 1. delete all likes and interactions of user
    await Interaction.find(Interaction.user_id == str(current_user.id)).delete()
    
    # 2. delete all playlists of user
    await Playlist.find(Playlist.user_id == str(current_user.id)).delete()
    
    # 3. delete user itself
    await current_user.delete()
    
    return None

@router.post("/complete-onboarding", response_model=UserRead)
async def complete_onboarding(
    data: OnboardingComplete, 
    current_user: User = Depends(get_current_user)
):
    current_user.interests = data.interests
    current_user.is_onboarding_completed = True
    await current_user.save()
    return current_user

@router.get("/tags")
async def get_available_tags():
    from app.core.tags import MASTER_TAGS 
    return list(MASTER_TAGS.keys())