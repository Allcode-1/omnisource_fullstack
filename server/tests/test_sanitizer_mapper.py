from app.schemas.content import UnifiedContent
from app.utils.mappers import ContentMapper
from app.utils.sanitizer import ContentSanitizer


def _content(
    *,
    id_value: str,
    ext_id: str,
    title: str,
    type_value: str = "movie",
    subtitle: str = "subtitle",
    image_url: str | None = "https://img",
) -> UnifiedContent:
    return UnifiedContent(
        id=id_value,
        external_id=ext_id,
        title=title,
        type=type_value,
        subtitle=subtitle,
        image_url=image_url,
    )


def test_sanitizer_rejects_missing_image() -> None:
    item = _content(id_value="1", ext_id="e1", title="Normal title", image_url=None)
    assert ContentSanitizer.is_valid(item) is False


def test_sanitizer_rejects_stop_words() -> None:
    item = _content(id_value="2", ext_id="e2", title="White Noise Collection")
    assert ContentSanitizer.is_valid(item) is False


def test_sanitizer_accepts_regular_content() -> None:
    item = _content(id_value="3", ext_id="e3", title="Blade Runner")
    assert ContentSanitizer.is_valid(item) is True


def test_sanitizer_get_unique_deduplicates_by_title_and_type() -> None:
    items = [
        _content(id_value="1", ext_id="e1", title="Dune", type_value="movie"),
        _content(id_value="2", ext_id="e2", title="Dune", type_value="movie"),
        _content(id_value="3", ext_id="e3", title="Dune", type_value="book"),
    ]

    unique = ContentSanitizer.get_unique(items, limit=10)
    assert len(unique) == 2
    assert unique[0].external_id == "e1"
    assert unique[1].external_id == "e3"


def test_map_tmdb_builds_expected_unified_content() -> None:
    mapped = ContentMapper.map_tmdb(
        {
            "id": 42,
            "title": "Inception",
            "overview": "Dream infiltration",
            "poster_path": "/poster.jpg",
            "vote_average": 8.7,
            "release_date": "2010-07-16",
        }
    )

    assert mapped.type == "movie"
    assert mapped.external_id == "42"
    assert mapped.image_url == "https://image.tmdb.org/t/p/w500/poster.jpg"
    assert mapped.rating == 8.7


def test_map_google_books_forces_https_thumbnail() -> None:
    mapped = ContentMapper.map_google_books(
        {
            "id": "book-id",
            "volumeInfo": {
                "title": "Neuromancer",
                "authors": ["William Gibson"],
                "imageLinks": {"thumbnail": "http://books.test/img.jpg"},
                "averageRating": 4.5,
                "categories": ["Sci-Fi"],
                "publishedDate": "1984",
            },
        }
    )

    assert mapped.type == "book"
    assert mapped.external_id == "book-id"
    assert mapped.image_url == "https://books.test/img.jpg"
    assert mapped.subtitle == "William Gibson"


def test_map_spotify_uses_first_album_image_and_popularity_rating() -> None:
    mapped = ContentMapper.map_spotify(
        {
            "id": "track-1",
            "name": "Chill Track",
            "artists": [{"name": "Artist A"}, {"name": "Artist B"}],
            "album": {
                "name": "Album X",
                "images": [{"url": "https://spotify.test/cover.jpg"}],
                "release_date": "2024-01-01",
            },
            "popularity": 80,
        }
    )

    assert mapped.type == "music"
    assert mapped.external_id == "track-1"
    assert mapped.image_url == "https://spotify.test/cover.jpg"
    assert mapped.subtitle == "Artist A, Artist B"
    assert mapped.rating == 8.0
