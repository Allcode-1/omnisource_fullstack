import pytest

from app.ml.similarity import SimilarityManager
from app.ml.vectorizer import ContentVectorizer


def test_cosine_similarity_identical_vectors_is_one() -> None:
    score = SimilarityManager.calculate_cosine_similarity([1.0, 2.0], [1.0, 2.0])
    assert score == pytest.approx(1.0, rel=1e-6)


def test_cosine_similarity_empty_or_zero_vector_is_zero() -> None:
    assert SimilarityManager.calculate_cosine_similarity([], [1.0, 1.0]) == 0.0
    assert SimilarityManager.calculate_cosine_similarity([0.0, 0.0], [1.0, 1.0]) == 0.0


def test_genres_to_vector_binary_mapping() -> None:
    result = SimilarityManager.genres_to_vector(
        all_genres=["Action", "Drama", "Sci-Fi"],
        target_genres=["Drama"],
    )
    assert result == [0.0, 1.0, 0.0]


def test_vectorizer_clean_text_strips_html_and_punctuation() -> None:
    vectorizer = ContentVectorizer()
    cleaned = vectorizer._clean_text(" <b>Hello, WORLD!</b> ")
    assert cleaned == "hello world"


def test_vectorizer_hash_fallback_embedding_shape() -> None:
    vectorizer = ContentVectorizer()
    vectorizer._load_failed = True

    embedding = vectorizer.get_embedding("Cyberpunk Noir")
    assert len(embedding) == 128
    assert any(value != 0 for value in embedding)


def test_vectorizer_batch_embeddings_filters_empty_and_returns_vectors() -> None:
    vectorizer = ContentVectorizer()
    vectorizer._load_failed = True

    vectors = vectorizer.get_batch_embeddings(["Dark fantasy", "", "Medieval mystery"])
    assert len(vectors) == 2
    assert all(len(vector) == 128 for vector in vectors)
