from fastapi import APIRouter, Query
from typing import List, Dict
from app.services.content_service import ContentService
from app.schemas.content import UnifiedContent

router = APIRouter(prefix="/content", tags=["content"])
service = ContentService()

@router.get("/search", response_model=List[UnifiedContent])
async def search(query: str = Query(..., min_length=2)):
    return await service.get_unified_search(query)

@router.get("/home")
async def home():
    return await service.get_home_data()

@router.get("/discover", response_model=List[UnifiedContent])
async def discover(tag: str = Query(...)):
    return await service.get_discovery(tag)

@router.get("/trending", response_model=List[UnifiedContent])
async def trending():
    # return mix from homepage
    data = await service.get_home_data()
    return sorted(data["trending_movies"] + data["popular_books"] + data["top_tracks"], key=lambda x: x.rating or 0, reverse=True)