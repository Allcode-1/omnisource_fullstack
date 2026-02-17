import redis.asyncio as redis
import json
import logging
import asyncio
from app.core.config import settings

logger = logging.getLogger(__name__)

class RedisService:
    def __init__(self):
        self.redis_url = settings.REDIS_URL if settings.REDIS_URL else "redis://localhost:6379"
        self.client = redis.from_url(
            self.redis_url, 
            decode_responses=True,
            socket_connect_timeout=0.5,
            socket_timeout=0.5
        )
        self._is_available = True

    async def get_cache(self, key: str):
        try:
            data = await asyncio.wait_for(self.client.get(key), timeout=0.5)
            return json.loads(data) if data else None
        except Exception:
            if self._is_available:
                logger.warning("Redis is down. Fetching data directly from DB/API...")
                self._is_available = False
            return None

    async def set_cache(self, key: str, value: any, expire: int = 3600):
        try:
            await asyncio.wait_for(
                self.client.set(key, json.dumps(value), ex=expire), 
                timeout=0.5
            )
            self._is_available = True
        except Exception:
            pass

    async def close(self):
        try:
            await self.client.close()
        except Exception:
            pass

redis_client = RedisService()