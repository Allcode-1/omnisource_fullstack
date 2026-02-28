import asyncio
import json
import time

import pytest

from app.core.redis import RedisService


class _FakeRedisClient:
    def __init__(self) -> None:
        self.storage: dict[str, str] = {}
        self.fail_get = False
        self.fail_set = False
        self.get_calls = 0

    async def ping(self) -> bool:
        return True

    async def get(self, key: str):
        self.get_calls += 1
        if self.fail_get:
            raise RuntimeError("redis down")
        return self.storage.get(key)

    async def set(self, key: str, value: str, ex: int | None = None):
        if self.fail_set:
            raise RuntimeError("set failed")
        self.storage[key] = value
        return True

    async def delete(self, *keys: str):
        for key in keys:
            self.storage.pop(key, None)
        return len(keys)

    async def scan(self, cursor: int = 0, match: str | None = None, count: int = 100):
        return 0, []

    async def aclose(self) -> None:
        return None


@pytest.mark.asyncio
async def test_get_cache_hit_and_miss() -> None:
    service = RedisService()
    fake = _FakeRedisClient()
    service.client = fake
    fake.storage["k1"] = json.dumps({"value": 1})

    hit = await service.get_cache("k1")
    miss = await service.get_cache("k2")

    assert hit == {"value": 1}
    assert miss is None


@pytest.mark.asyncio
async def test_set_cache_writes_json_payload() -> None:
    service = RedisService()
    fake = _FakeRedisClient()
    service.client = fake

    await service.set_cache("k", {"a": 1}, expire=60)
    assert json.loads(fake.storage["k"]) == {"a": 1}


@pytest.mark.asyncio
async def test_get_cache_marks_down_and_skips_during_cooldown() -> None:
    service = RedisService()
    fake = _FakeRedisClient()
    fake.fail_get = True
    service.client = fake

    first = await service.get_cache("k")
    assert first is None
    assert service._is_available is False
    initial_calls = fake.get_calls

    service._retry_after_monotonic = time.monotonic() + 5.0
    second = await service.get_cache("k")
    assert second is None
    assert fake.get_calls == initial_calls


@pytest.mark.asyncio
async def test_service_recovers_after_successful_ping() -> None:
    service = RedisService()
    fake = _FakeRedisClient()
    service.client = fake
    service._mark_down("forced down")
    assert service._is_available is False

    ok = await service.ping()
    assert ok is True
    assert service._is_available is True
