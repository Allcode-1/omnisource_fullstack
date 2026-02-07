from pydantic import BaseModel, Field
from typing import List, Optional

class UnifiedContent(BaseModel):
    id: str = Field(alias="_id") 
    external_id: str = Field(alias="ext_id") 
    type: str          # 'movie', 'book', or 'music'
    title: str
    subtitle: str      
    description: Optional[str] = None
    image_url: Optional[str] = None
    rating: Optional[float] = 0.0
    genres: List[str] = []
    release_date: Optional[str] = None

    class Config:
        populate_by_name = True