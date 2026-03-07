from app.models.content_meta import ContentMetadata
from app.core.content_keys import make_content_key

class ContentRepository:
    async def get_by_ext_id(self, ext_id: str, content_type: str | None = None):
        if content_type:
            content_key = make_content_key(content_type, ext_id)
            by_key = await ContentMetadata.find_one(ContentMetadata.content_key == content_key)
            if by_key is not None:
                return by_key
            return await ContentMetadata.find_one(
                ContentMetadata.ext_id == ext_id,
                ContentMetadata.type == content_type,
            )
        return await ContentMetadata.find_one(ContentMetadata.ext_id == ext_id)

    async def create_content(self, data: dict):
        content_type = data.get("type")
        ext_id = data.get("ext_id")
        if content_type and ext_id and not data.get("content_key"):
            data["content_key"] = make_content_key(content_type, ext_id)
        content = ContentMetadata(**data)
        await content.insert()
        return content
