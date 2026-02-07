import redis.asyncio as redis
import json
import logging
from app.core.config import settings

# lof to see if redis is down
logger = logging.getLogger(__name__)

class RedisService:
    def __init__(self):
        # socket_connect_timeout=1 does not allow app to hang if Redis is down
        self.client = redis.from_url(
            settings.REDIS_URL, 
            decode_responses=True,
            socket_connect_timeout=1,
            socket_timeout=1
        )

    async def get_cache(self, key: str):
        try:
            data = await self.client.get(key)
            return json.loads(data) if data else None
        except Exception as e:
            logger.warning(f"Redis is unavailable (GET): {e}")
            return None

    async def set_cache(self, key: str, value: any, expire: int = 3600):
        try:
            await self.client.set(key, json.dumps(value), ex=expire)
        except Exception as e:
            logger.warning(f"Redis is unavailable (SET): {e}")

    async def close(self):
        try:
            await self.client.close()
        except Exception:
            pass

redis_client = RedisService()