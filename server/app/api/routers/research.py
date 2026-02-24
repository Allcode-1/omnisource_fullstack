from typing import List, Optional
from fastapi import APIRouter, Query
from app.ml.engine import RecommenderEngine
from app.schemas.content import UnifiedContent

router = APIRouter(prefix="/research", tags=["Research"])
engine = RecommenderEngine()


@router.get("/deep", response_model=List[UnifiedContent])
async def deep_research(
    tag: str = Query(..., min_length=2),
    type: Optional[str] = Query("all"),
    limit: int = Query(20, ge=1, le=50),
):
    return await engine.get_deep_research(
        tag=tag,
        content_type=type,
        limit=limit,
    )
