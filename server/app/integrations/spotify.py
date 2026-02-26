import httpx
import base64
import asyncio
import time
from app.integrations.base import BaseIntegration
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

class SpotifyClient(BaseIntegration):
    def __init__(self):
        super().__init__("https://api.spotify.com/v1")
        self.token_url = "https://accounts.spotify.com/api/token"
        self._access_token = None
        self._token_expires_at = 0.0
        self._token_lock = asyncio.Lock()

    def _token_is_valid(self) -> bool:
        if not self._access_token:
            return False
        # refresh slightly before actual expiration
        return time.time() < (self._token_expires_at - 30)

    async def _get_token(self):
        auth_string = f"{settings.SPOTIFY_CLIENT_ID}:{settings.SPOTIFY_CLIENT_SECRET}"
        auth_base64 = base64.b64encode(auth_string.encode()).decode()
        headers = {"Authorization": f"Basic {auth_base64}", "Content-Type": "application/x-www-form-urlencoded"}
        data = {"grant_type": "client_credentials"}

        for attempt in range(3):
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.post(
                        self.token_url,
                        headers=headers,
                        data=data,
                        timeout=8.0,
                    )
                if response.status_code == 200:
                    payload = response.json()
                    self._access_token = payload.get("access_token")
                    expires_in = int(payload.get("expires_in", 3600))
                    self._token_expires_at = time.time() + max(60, expires_in)
                    return
            except Exception:
                pass
            await asyncio.sleep(0.25 * (attempt + 1))

        logger.warning("Spotify token request failed")
        self._access_token = None
        self._token_expires_at = 0.0

    async def _ensure_token(self, force_refresh: bool = False) -> None:
        if not force_refresh and self._token_is_valid():
            return
        async with self._token_lock:
            if not force_refresh and self._token_is_valid():
                return
            await self._get_token()

    async def search_tracks(self, query: str):
        await self._ensure_token()
        if not self._access_token:
            return {"tracks": {"items": []}}

        headers = {"Authorization": f"Bearer {self._access_token}"}
        params = {"q": query, "type": "track", "limit": 20, "market": "US"}
        res = await self._get("/search", params=params, headers=headers)

        # token may expire or request may fail transiently
        if not res:
            await self._ensure_token(force_refresh=True)
            if not self._access_token:
                return {"tracks": {"items": []}}
            headers = {"Authorization": f"Bearer {self._access_token}"}
            res = await self._get("/search", params=params, headers=headers)
        return res or {"tracks": {"items": []}}
