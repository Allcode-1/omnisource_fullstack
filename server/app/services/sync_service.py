from __future__ import annotations

from typing import Iterable

from app.core.logging import get_logger
from app.core.content_keys import make_content_key
from app.models.content_meta import ContentMetadata
from app.schemas.content import UnifiedContent
from app.services.content_service import ContentService

logger = get_logger(__name__)


class ContentSyncService:
    def __init__(self):
        self.content_service = ContentService()

    async def persist_items(self, items: Iterable[UnifiedContent]) -> int:
        count = 0
        supports_content_key = hasattr(ContentMetadata, "content_key")
        for item in items:
            if not item.external_id:
                continue

            content_key = make_content_key(item.type, item.external_id)
            doc = None
            if supports_content_key:
                doc = await ContentMetadata.find_one(
                    ContentMetadata.content_key == content_key,
                )
            if doc is None:
                if hasattr(ContentMetadata, "type"):
                    doc = await ContentMetadata.find_one(
                        ContentMetadata.ext_id == item.external_id,
                        ContentMetadata.type == item.type,
                    )
                else:
                    doc = await ContentMetadata.find_one(
                        ContentMetadata.ext_id == item.external_id,
                    )
            if doc:
                if supports_content_key and hasattr(doc, "content_key"):
                    doc.content_key = content_key
                doc.type = item.type
                doc.title = item.title
                doc.subtitle = item.subtitle
                doc.image_url = item.image_url
                doc.rating = item.rating or 0.0
                doc.release_date = item.release_date
                doc.genres = item.genres
                await doc.save()
            else:
                payload = {
                    "ext_id": item.external_id,
                    "type": item.type,
                    "title": item.title,
                    "subtitle": item.subtitle,
                    "image_url": item.image_url,
                    "rating": item.rating or 0.0,
                    "release_date": item.release_date,
                    "genres": item.genres,
                    "features_vector": [],
                }
                if supports_content_key:
                    payload["content_key"] = content_key
                await ContentMetadata(**payload).insert()
            count += 1
        return count

    async def sync_home_snapshot(self) -> int:
        total = 0
        for content_type in ("all", "movie", "music", "book"):
            data = await self.content_service.get_home_data(content_type)
            for section in data.values():
                total += await self.persist_items(section)

        logger.info("Background sync completed. persisted_items=%s", total)
        return total
