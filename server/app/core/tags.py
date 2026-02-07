from dataclasses import dataclass
from typing import Dict

@dataclass
class TagMapping:
    tmdb_keyword: str
    spotify_genre: str
    google_books_subject: str

MASTER_TAGS: Dict[str, TagMapping] = {
    # main ganres
    "cyberpunk": TagMapping("cyberpunk", "synthwave", "fiction+cyberpunk"),
    "horror": TagMapping("horror", "horror", "horror"),
    "comedy": TagMapping("comedy", "comedy", "humor"),
    "sci-fi": TagMapping("science fiction", "ambient", "fiction+science+fiction"),
    "fantasy": TagMapping("fantasy", "soundtrack", "fiction+fantasy"),
    "romance": TagMapping("romance", "romance", "romance+fiction"),
    "thriller": TagMapping("thriller", "crime", "thriller+fiction"),
    "mystery": TagMapping("mystery", "mystery", "detective+fiction"),
    "drama": TagMapping("drama", "acoustic", "drama"),
    "action": TagMapping("action", "rock", "adventure+fiction"),
    
    # atmosphere and style
    "noir": TagMapping("film noir", "jazz", "detective"),
    "post-apocalyptic": TagMapping("post-apocalyptic", "industrial", "dystopian"),
    "western": TagMapping("western", "country", "western+fiction"),
    "anime": TagMapping("anime", "j-pop", "manga"),
    "superhero": TagMapping("superhero", "power+metal", "comics"),
    "space": TagMapping("space", "space+ambient", "astronomy+fiction"),
    "cyber": TagMapping("hacker", "techno", "technology"),
    "medieval": TagMapping("medieval", "medieval", "history+europe"),
    "steampunk": TagMapping("steampunk", "victorian", "steampunk+fiction"),
    "urban": TagMapping("urban", "hip-hop", "urban+fiction"),

    # mood
    "dark": TagMapping("dark", "dark+ambient", "gothic"),
    "chill": TagMapping("relax", "chill", "self-help"),
    "epic": TagMapping("epic", "orchestral", "heroic+fantasy"),
    "retro": TagMapping("80s", "80s", "history+20th+century"),
    "sad": TagMapping("sad", "sad", "psychology"),
    "mind-bending": TagMapping("psychological", "psychedelic", "philosophy"),
    
    # another
    "crime": TagMapping("crime", "hip-hop", "true+crime"),
    "history": TagMapping("history", "classical", "biography"),
    "war": TagMapping("war", "military", "military+history"),
    "magic": TagMapping("magic", "new+age", "occult")
}

def get_tag_queries(tag_name: str) -> TagMapping:
    # retunrs tag mapping or def tag if nothing found
    return MASTER_TAGS.get(
        tag_name.lower(), 
        TagMapping(tag_name, tag_name, tag_name)
    )