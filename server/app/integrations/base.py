import httpx
from typing import Optional, Any

class BaseIntegration:
    def __init__(self, base_url: str):
        self.base_url = base_url

    async def _get(self, endpoint: str, params: Optional[dict] = None, headers: Optional[dict] = None) -> Any:
        async with httpx.AsyncClient() as client:
            url = f"{self.base_url}{endpoint}"
            response = await client.get(url, params=params, headers=headers, timeout=10.0)
            if response.status_code != 200:
                print(f"API Error {url}: {response.status_code} - {response.text}")
                return None
            return response.json()