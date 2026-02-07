from app.models.content_meta import ContentMetadata

class ContentRepository:
    async def get_by_ext_id(self, ext_id: str):
        return await ContentMetadata.find_one(ContentMetadata.ext_id == ext_id)

    async def create_content(self, data: dict):
        content = ContentMetadata(**data)
        await content.insert()
        return content