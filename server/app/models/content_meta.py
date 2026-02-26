from beanie import Document, Indexed
from typing import List, Annotated, Optional
from datetime import datetime
from pydantic import Field

class ContentMetadata(Document):
    ext_id: Annotated[str, Indexed(unique=True)]
    type: Annotated[str, Indexed()]  # movie, music, book
    title: str
    subtitle: Optional[str] = None
    image_url: Optional[str] = None
    rating: float = 0.0
    release_date: Optional[str] = None
    genres: List[str] = []
    features_vector: List[float] = []

    class Settings:
        name = "content_metadata"

class Playlist(Document):
    user_id: Annotated[str, Indexed()]
    title: str
    description: Optional[str] = None
    items: List[str] = []  
    is_public: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "playlists"
