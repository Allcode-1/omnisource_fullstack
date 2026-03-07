from __future__ import annotations

from typing import Final


_ALLOWED_TYPES: Final[set[str]] = {"movie", "music", "book"}


def make_content_key(content_type: str | None, ext_id: str | None) -> str:
    normalized_type = (content_type or "").strip().lower()
    normalized_ext_id = (ext_id or "").strip()
    if not normalized_type or not normalized_ext_id:
        return ""
    return f"{normalized_type}:{normalized_ext_id}"


def split_content_key(content_ref: str | None) -> tuple[str | None, str | None]:
    value = (content_ref or "").strip()
    if ":" not in value:
        return None, None
    content_type, ext_id = value.split(":", 1)
    content_type = content_type.strip().lower()
    ext_id = ext_id.strip()
    if not content_type or not ext_id:
        return None, None
    return content_type, ext_id


def looks_like_content_key(content_ref: str | None) -> bool:
    content_type, ext_id = split_content_key(content_ref)
    return bool(content_type in _ALLOWED_TYPES and ext_id)
