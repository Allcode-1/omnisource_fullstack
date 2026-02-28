import json

import pytest

from app.core.redis import RedisService


class _FakeRedisClient:
    def __init__(self) -> None:
        self.storage: dict[str, str] = {}
        self.fail_set = False
        self.fail_delete = False
        self.fail_scan = False

    async def ping(self):
        return True

    async def get(self, key: str):
        return self.storage.get(key)

    async def set(self, key: str, value: str, ex: int | None = None):
        if self.fail_set:
            raise RuntimeError("set failed")
        self.storage[key] = value
        return True

    async def delete(self, *keys: str):
        if self.fail_delete:
            raise RuntimeError("delete failed")
        for key in keys:
            self.storage.pop(key, None)
        return len(keys)

    async def scan(self, cursor: int = 0, match: str | None = None, count: int = 100):
        if self.fail_scan:
            raise RuntimeError("scan failed")
        keys = [key for key in self.storage if match is None or key.startswith(match[:-1])]
        return 0, keys

    async def aclose(self) -> None:
        return None


@pytest.mark.asyncio
async def test_set_cache_marks_service_down_on_failure() -> None:
    service = RedisService()
    fake = _FakeRedisClient()
    fake.fail_set = True
    service.client = fake

    await service.set_cache("k1", {"a": 1})
    assert service._is_available is False


@pytest.mark.asyncio
async def test_delete_cache_and_delete_by_prefix_work() -> None:
    service = RedisService()
    fake = _FakeRedisClient()
    service.client = fake
    fake.storage["pref:1"] = json.dumps({"a": 1})
    fake.storage["pref:2"] = json.dumps({"a": 2})
    fake.storage["other:1"] = json.dumps({"a": 3})

    await service.delete_cache("other:1")
    deleted = await service.delete_by_prefix("pref:")

    assert "other:1" not in fake.storage
    assert deleted == 2
    assert "pref:1" not in fake.storage
    assert "pref:2" not in fake.storage


@pytest.mark.asyncio
async def test_delete_by_prefix_handles_scan_failure() -> None:
    service = RedisService()
    fake = _FakeRedisClient()
    fake.fail_scan = True
    service.client = fake

    deleted = await service.delete_by_prefix("pref:")
    assert deleted == 0
    assert service._is_available is False
