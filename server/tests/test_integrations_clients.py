import asyncio
import time

import pytest

from app.integrations.base import BaseIntegration
from app.integrations.google_books import GoogleBooksClient
from app.integrations.spotify import SpotifyClient
from app.integrations.tmdb import TMDBClient


class _FakeResponse:
    def __init__(self, status_code: int, payload=None, text: str = "") -> None:
        self.status_code = status_code
        self._payload = payload if payload is not None else {}
        self.text = text

    def json(self):
        return self._payload


class _FakeAsyncClient:
    def __init__(self, responses):
        self._responses = list(responses)
        self.calls = 0

    async def get(self, *args, **kwargs):
        self.calls += 1
        if self._responses:
            response = self._responses.pop(0)
            if isinstance(response, Exception):
                raise response
            return response
        return _FakeResponse(200, {})

    async def aclose(self) -> None:
        return None


@pytest.mark.asyncio
async def test_base_integration_get_returns_json_on_200() -> None:
    integration = BaseIntegration("https://api.test")
    integration._client = _FakeAsyncClient([_FakeResponse(200, {"ok": True})])

    data = await integration._get("/path", params={"q": 1})
    assert data == {"ok": True}


@pytest.mark.asyncio
async def test_base_integration_retries_then_returns_none(monkeypatch) -> None:
    integration = BaseIntegration("https://api.test")
    integration._client = _FakeAsyncClient(
        [_FakeResponse(503, text="busy"), _FakeResponse(503, text="busy"), _FakeResponse(503, text="busy")],
    )

    async def _fast_sleep(*_args, **_kwargs):
        return None

    monkeypatch.setattr(asyncio, "sleep", _fast_sleep)

    data = await integration._get("/path")
    assert data is None
    assert integration._client.calls == 3


@pytest.mark.asyncio
async def test_base_integration_handles_exception_after_retries(monkeypatch) -> None:
    integration = BaseIntegration("https://api.test")
    integration._client = _FakeAsyncClient(
        [RuntimeError("boom"), RuntimeError("boom"), RuntimeError("boom")],
    )

    async def _fast_sleep(*_args, **_kwargs):
        return None

    monkeypatch.setattr(asyncio, "sleep", _fast_sleep)

    data = await integration._get("/path")
    assert data is None
    assert integration._client.calls == 3


@pytest.mark.asyncio
async def test_tmdb_make_request_returns_results_on_success() -> None:
    client = TMDBClient()
    client._client = _FakeAsyncClient([_FakeResponse(200, {"results": [{"id": 1}]})])

    payload = await client._make_request("search/movie", {"query": "matrix"})
    assert payload["results"][0]["id"] == 1


@pytest.mark.asyncio
async def test_tmdb_make_request_falls_back_on_failure(monkeypatch) -> None:
    client = TMDBClient()
    client._client = _FakeAsyncClient(
        [_FakeResponse(500, text="err"), _FakeResponse(500, text="err"), _FakeResponse(500, text="err")],
    )

    async def _fast_sleep(*_args, **_kwargs):
        return None

    monkeypatch.setattr(asyncio, "sleep", _fast_sleep)

    payload = await client._make_request("search/movie", {"query": "matrix"})
    assert payload == {"results": []}


@pytest.mark.asyncio
async def test_tmdb_search_movies_returns_empty_for_blank_query() -> None:
    client = TMDBClient()
    payload = await client.search_movies("")
    assert payload == {"results": []}


@pytest.mark.asyncio
async def test_google_books_search_uses_fallback_when_request_none(monkeypatch) -> None:
    client = GoogleBooksClient()

    async def fake_get(endpoint: str, params=None, headers=None):
        assert endpoint == "/volumes"
        return None

    monkeypatch.setattr(client, "_get", fake_get)
    payload = await client.search_books("subject:history")
    assert payload == {"items": []}


@pytest.mark.asyncio
async def test_spotify_token_validity_check() -> None:
    client = SpotifyClient()
    client._access_token = "tkn"
    client._token_expires_at = time.time() + 120
    assert client._token_is_valid() is True

    client._token_expires_at = time.time() + 5
    assert client._token_is_valid() is False


@pytest.mark.asyncio
async def test_spotify_search_returns_empty_when_no_token(monkeypatch) -> None:
    client = SpotifyClient()

    async def fake_ensure_token(force_refresh: bool = False) -> None:
        client._access_token = None

    monkeypatch.setattr(client, "_ensure_token", fake_ensure_token)
    payload = await client.search_tracks("genre:rock")
    assert payload == {"tracks": {"items": []}}


@pytest.mark.asyncio
async def test_spotify_search_retries_after_refresh(monkeypatch) -> None:
    client = SpotifyClient()
    calls = {"ensure": [], "get": 0}

    async def fake_ensure_token(force_refresh: bool = False) -> None:
        calls["ensure"].append(force_refresh)
        client._access_token = "token-refreshed"

    async def fake_get(endpoint: str, params=None, headers=None):
        calls["get"] += 1
        if calls["get"] == 1:
            return None
        return {"tracks": {"items": [{"id": "t1"}]}}

    monkeypatch.setattr(client, "_ensure_token", fake_ensure_token)
    monkeypatch.setattr(client, "_get", fake_get)

    payload = await client.search_tracks("genre:rock")
    assert payload["tracks"]["items"][0]["id"] == "t1"
    assert calls["ensure"] == [False, True]
    assert calls["get"] == 2
