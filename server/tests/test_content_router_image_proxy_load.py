from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.routers import content as content_router


def _build_app() -> FastAPI:
    app = FastAPI()
    app.include_router(content_router.router)
    return app


def _reset_cache() -> None:
    content_router._image_cache.clear()
    content_router._image_inflight.clear()
    content_router._image_cache_total_bytes = 0


def test_image_proxy_burst_requests_use_cached_payload(monkeypatch) -> None:
    _reset_cache()
    url = "https://image.tmdb.org/t/p/w500/burst.jpg"
    calls = {"fetch": 0}

    async def fake_fetch_image(raw_url: str):
        calls["fetch"] += 1
        assert raw_url == url
        return b"x" * 1024, "image/jpeg"

    monkeypatch.setattr(content_router, "_fetch_image", fake_fetch_image)
    client = TestClient(_build_app())

    for _ in range(25):
        response = client.get("/content/image-proxy", params={"url": url})
        assert response.status_code == 200
        assert response.content == b"x" * 1024

    assert calls["fetch"] == 1
    assert content_router._image_cache_total_bytes == 1024


def test_image_proxy_many_unique_requests_stays_within_budget(monkeypatch) -> None:
    _reset_cache()
    original_budget = content_router._IMAGE_CACHE_MAX_TOTAL_BYTES
    original_max_items = content_router._IMAGE_CACHE_MAX_ITEMS
    try:
        content_router._IMAGE_CACHE_MAX_TOTAL_BYTES = 8 * 1024
        content_router._IMAGE_CACHE_MAX_ITEMS = 200

        async def fake_fetch_image(raw_url: str):
            return b"z" * 1024, "image/jpeg"

        monkeypatch.setattr(content_router, "_fetch_image", fake_fetch_image)
        client = TestClient(_build_app())

        for idx in range(40):
            response = client.get(
                "/content/image-proxy",
                params={"url": f"https://image.tmdb.org/t/p/w500/{idx}.jpg"},
            )
            assert response.status_code == 200

        assert content_router._image_cache_total_bytes <= 8 * 1024
    finally:
        content_router._IMAGE_CACHE_MAX_TOTAL_BYTES = original_budget
        content_router._IMAGE_CACHE_MAX_ITEMS = original_max_items
