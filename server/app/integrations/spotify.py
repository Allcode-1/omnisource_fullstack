import httpx
import base64
from app.integrations.base import BaseIntegration
from app.core.config import settings

class SpotifyClient(BaseIntegration):
    def __init__(self):
        super().__init__("https://api.spotify.com/v1")
        self.token_url = "https://accounts.spotify.com/api/token"
        self._access_token = None

    async def _get_token(self):
        auth_string = f"{settings.SPOTIFY_CLIENT_ID}:{settings.SPOTIFY_CLIENT_SECRET}"
        auth_base64 = base64.b64encode(auth_string.encode()).decode()
        headers = {"Authorization": f"Basic {auth_base64}", "Content-Type": "application/x-www-form-urlencoded"}
        data = {"grant_type": "client_credentials"}
        
        async with httpx.AsyncClient() as client:
            response = await client.post(self.token_url, headers=headers, data=data)
            if response.status_code == 200:
                self._access_token = response.json().get("access_token")

    async def search_tracks(self, query: str):
        if not self._access_token: await self._get_token()
        headers = {"Authorization": f"Bearer {self._access_token}"}
        params = {"q": query, "type": "track", "limit": 20, "market": "US"}
        res = await self._get("/search", params=params, headers=headers)
        if not res: # if token expires
            await self._get_token()
            headers = {"Authorization": f"Bearer {self._access_token}"}
            res = await self._get("/search", params=params, headers=headers)
        return res