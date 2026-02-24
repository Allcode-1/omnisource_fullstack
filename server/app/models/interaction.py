from beanie import Document, Indexed
from typing import Annotated, Optional
from datetime import datetime
from pydantic import Field

class Interaction(Document):
    user_id: str
    ext_id: str  # link of content (external_id)
    type: str    # like, view, playlist_add
    weight: float = 1.0 # for ml: weight of action
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "interactions"
