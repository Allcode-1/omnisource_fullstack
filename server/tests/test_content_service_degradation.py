import pytest

from app.core.metrics import MetricsRegistry
from app.schemas.content import UnifiedContent
from app.services import content_service as content_service_module
from app.services.content_service import ContentService


class _FakeRedis:
    async def get_cache(self, key: str):
        return None

    async def set_cache(self, key: str, value, expire: int = 0):
        return None


def _make_item(ext_id: str, type_value: str = "music") -> UnifiedContent:
    return UnifiedContent(
        id=f"{type_value}_{ext_id}",
        external_id=ext_id,
        type=type_value,
        title=f"{type_value}-{ext_id}",
        subtitle=type_value.title(),
        image_url=f"https://img.test/{ext_id}.jpg",
        rating=7.0,
    )


@pytest.mark.asyncio
async def test_get_unified_search_records_metrics_on_fetch_and_mapping_errors(
    monkeypatch,
) -> None:
    service = ContentService()
    registry = MetricsRegistry()
    monkeypatch.setattr(content_service_module, "redis_client", _FakeRedis())
    monkeypatch.setattr(content_service_module, "metrics_registry", registry)

    async def failing_tmdb(query: str):
        raise RuntimeError("tmdb down")

    async def books_payload(query: str):
        return {"items": [{"id": "b1"}]}

    async def spotify_payload(query: str):
        return {"tracks": {"items": [{"id": "s1"}]}}

    monkeypatch.setattr(service.tmdb, "search_movies", failing_tmdb)
    monkeypatch.setattr(service.books, "search_books", books_payload)
    monkeypatch.setattr(service.spotify, "search_tracks", spotify_payload)

    def failing_map_google_books(raw):
        raise ValueError("bad book payload")

    monkeypatch.setattr(service.mapper, "map_google_books", failing_map_google_books)
    monkeypatch.setattr(service.mapper, "map_spotify", lambda raw: _make_item("s1"))
    monkeypatch.setattr(service.sanitizer, "is_valid", lambda item: True)

    payload = await service.get_unified_search("matrix", "all")
    metrics = registry.render_prometheus()

    assert len(payload) == 1
    assert payload[0].type == "music"
    assert 'event="content_service_errors_total"' in metrics
    assert 'stage="search_fetch"' in metrics
    assert 'stage="search_map"' in metrics


@pytest.mark.asyncio
async def test_get_recommendations_records_fetch_degradation_metrics(monkeypatch) -> None:
    service = ContentService()
    registry = MetricsRegistry()
    monkeypatch.setattr(content_service_module, "redis_client", _FakeRedis())
    monkeypatch.setattr(content_service_module, "metrics_registry", registry)

    async def failing(*args, **kwargs):
        raise RuntimeError("integration unavailable")

    monkeypatch.setattr(service.tmdb, "get_top_rated_movies", failing)
    monkeypatch.setattr(service.spotify, "search_tracks", failing)
    monkeypatch.setattr(service.books, "search_books", failing)

    payload = await service.get_recommendations("all")
    metrics = registry.render_prometheus()

    assert payload == []
    assert 'event="content_service_errors_total"' in metrics
    assert 'stage="recommendations_fetch"' in metrics
    assert 'source="movie"' in metrics
    assert 'source="music"' in metrics
    assert 'source="book"' in metrics
