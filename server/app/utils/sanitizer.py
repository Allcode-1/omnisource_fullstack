from typing import List
from app.schemas.content import UnifiedContent
from app.core.config import settings

class ContentSanitizer:
    @staticmethod
    def is_valid(item: UnifiedContent) -> bool:
        if not item.image_url:
            return False
        
        title_lower = item.title.lower()
        subtitle_lower = item.subtitle.lower() if item.subtitle else ""

        for word in settings.STOP_WORDS_TITLES:
            if word in title_lower:
                return False
        
        for word in settings.STOP_WORDS_SUBTITLES:
            if word in subtitle_lower:
                return False
                
        return True

    @staticmethod
    def get_unique(items: List[UnifiedContent], limit: int = 10) -> List[UnifiedContent]:
        seen_keys = set()
        unique_results = []
        
        for item in items:
            if len(unique_results) >= limit:
                break
                
            key = f"{item.title.lower()}_{item.type}"
            
            if key not in seen_keys:
                seen_keys.add(key)
                unique_results.append(item)
        
        return unique_results