from beanie import Document, Indexed
from datetime import datetime, timedelta
from typing import Annotated

class PasswordReset(Document):
    email: Annotated[str, Indexed()]
    token: str
    expires_at: datetime

    class Settings:
        name = "password_resets"