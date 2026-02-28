from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.routers import research as research_router
from app.schemas.content import UnifiedContent


def _item(ext_id: str, title: str) -> UnifiedContent:
    return UnifiedContent(
        id=f"id-{ext_id}",
        external_id=ext_id,
        type="movie",
        title=title,
        subtitle="Movie",
        image_url="https://img.test/cover.jpg",
        rating=7.0,
    )


def _build_app() -> FastAPI:
    app = FastAPI()
    app.include_router(research_router.router)
    return app


def test_deep_research_endpoint_returns_engine_payload(monkeypatch) -> None:
    async def fake_deep_research(tag: str, content_type: str | None = None, limit: int = 20):
        assert tag == "cyberpunk"
        assert content_type == "movie"
        assert limit == 3
        return [_item("x1", "Blade Runner"), _item("x2", "Akira")]

    monkeypatch.setattr(research_router.engine, "get_deep_research", fake_deep_research)
    client = TestClient(_build_app())

    response = client.get("/research/deep?tag=cyberpunk&type=movie&limit=3")
    assert response.status_code == 200

    payload = response.json()
    assert len(payload) == 2
    assert payload[0]["ext_id"] == "x1"
    assert payload[1]["title"] == "Akira"


def test_deep_research_validates_min_tag_length() -> None:
    client = TestClient(_build_app())
    response = client.get("/research/deep?tag=a")
    assert response.status_code == 422
