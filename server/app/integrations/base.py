import asyncio
import time
from typing import Any, Optional

import httpx

from app.core.logging import get_logger

logger = get_logger(__name__)


class BaseIntegration:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(8.0, connect=3.0, read=8.0),
            limits=httpx.Limits(max_connections=40, max_keepalive_connections=20),
        )

    async def _get(
        self,
        endpoint: str,
        params: Optional[dict] = None,
        headers: Optional[dict] = None,
    ) -> Any:
        url = f"{self.base_url}{endpoint}"
        retries = 2
        for attempt in range(retries + 1):
            started = time.perf_counter()
            try:
                response = await self._client.get(
                    url,
                    params=params,
                    headers=headers,
                )
                duration_ms = (time.perf_counter() - started) * 1000
                if response.status_code == 200:
                    logger.debug(
                        "API request ok url=%s status=%s attempt=%s duration_ms=%.2f",
                        url,
                        response.status_code,
                        attempt + 1,
                        duration_ms,
                    )
                    return response.json()
                if response.status_code in (429, 500, 502, 503, 504) and attempt < retries:
                    await asyncio.sleep(0.25 * (attempt + 1))
                    continue
                logger.warning(
                    "API non-200 response url=%s status=%s attempt=%s duration_ms=%.2f body=%s",
                    url,
                    response.status_code,
                    attempt + 1,
                    duration_ms,
                    response.text[:200],
                )
                return None
            except Exception as exc:
                duration_ms = (time.perf_counter() - started) * 1000
                if attempt < retries:
                    await asyncio.sleep(0.25 * (attempt + 1))
                    continue
                message = str(exc).strip() or type(exc).__name__
                logger.warning(
                    "API request failed url=%s attempt=%s duration_ms=%.2f error=%s",
                    url,
                    attempt + 1,
                    duration_ms,
                    message,
                )
                return None

        return None

    async def close(self) -> None:
        await self._client.aclose()
