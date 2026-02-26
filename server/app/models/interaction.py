from beanie import Document, Indexed
from typing import Annotated, Optional, Dict, Any
from datetime import datetime
from pydantic import Field

class Interaction(Document):
    user_id: Annotated[str, Indexed()]
    ext_id: Annotated[str, Indexed()]  # link of content (external_id)
    content_type: Optional[str] = None
    type: Annotated[str, Indexed()]    # like, view, playlist_add
    weight: float = 1.0 # for ml: weight of action
    meta: Dict[str, Any] = Field(default_factory=dict)
    created_at: Annotated[datetime, Indexed()] = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "interactions"
