from fastapi import APIRouter, Depends
from app.ml.engine import RecommenderEngine
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter(prefix="/recommendations", tags=["ML Recommendations"])
engine = RecommenderEngine()

@router.get("/")
async def get_my_recommendations(current_user: User = Depends(get_current_user)):
    return await engine.get_recommendations(str(current_user.id))