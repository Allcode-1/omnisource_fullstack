from beanie import Document, Indexed
from pydantic import EmailStr, Field
from typing import List, Annotated

class User(Document):
    username: Annotated[str, Indexed(unique=True)]
    email: Annotated[EmailStr, Indexed(unique=True)]
    hashed_password: str
    interests: List[str] = []
    is_onboarding_completed: bool = False

    class Settings:
        name = "users"