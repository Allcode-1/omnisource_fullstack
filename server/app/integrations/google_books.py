from app.integrations.base import BaseIntegration
from app.core.config import settings

class GoogleBooksClient(BaseIntegration):
    def __init__(self):
        super().__init__("https://www.googleapis.com/books/v1")
        self.api_key = settings.GOOGLE_BOOKS_API_KEY

    async def search_books(self, query: str):
        params = {"q": query, "key": self.api_key, "maxResults": 10, "langRestrict": "en"}
        return await self._get("/volumes", params=params)