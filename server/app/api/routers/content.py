from fastapi import APIRouter, Query
from typing import List, Dict
from app.services.content_service import ContentService
from app.schemas.content import UnifiedContent

router = APIRouter(prefix="/content", tags=["content"])
service = ContentService()

@router.get("/search", response_model=List[UnifiedContent])
async def search(
    query: str = Query(..., min_length=2),
    type: str = Query("all") 
):
    return await service.get_unified_search(query, type)

@router.get("/home")
async def home(type: str = Query("all")):
    return await service.get_home_data(type)

@router.get("/discover", response_model=List[UnifiedContent])
async def discover(tag: str = Query(...)):
    return await service.get_discovery(tag)

@router.get("/trending", response_model=List[UnifiedContent])
async def trending(type: str = Query("all")):
    data = await service.get_home_data(type)
    all_items = []
    for category_list in data.values():
        all_items.extend(category_list)
    
    unique_items = {item.external_id: item for item in all_items}.values()
    result = list(unique_items)
    
    return sorted(result, key=lambda x: getattr(x, "rating", 0) or 0, reverse=True)

@router.get("/recommendations", response_model=List[UnifiedContent])
async def recommendations(type: str = Query("all")):
    return await service.get_recommendations(type)