from app.schemas.content import UnifiedContent

class ContentMapper:
    @staticmethod
    def map_tmdb(movie: dict) -> UnifiedContent:
        return UnifiedContent(
            id=f"movie_{movie.get('id')}",
            external_id=str(movie.get('id')),
            type="movie",
            title=movie.get('title', ''),
            subtitle="Movie", 
            description=movie.get('overview'),
            image_url=f"https://image.tmdb.org/t/p/w500{movie.get('poster_path')}" if movie.get('poster_path') else None,
            rating=movie.get('vote_average', 0.0),
            genres=[], # id to name
            release_date=movie.get('release_date')
        )

    @staticmethod
    def map_google_books(book: dict) -> UnifiedContent:
        info = book.get('volumeInfo', {})
        return UnifiedContent(
            id=f"book_{book.get('id')}",
            external_id=book.get('id'),
            type="book",
            title=info.get('title', ''),
            subtitle=", ".join(info.get('authors', [])) if info.get('authors') else "Unknown author",
            description=info.get('description'),
            image_url=info.get('imageLinks', {}).get('thumbnail'),
            rating=info.get('averageRating', 0.0),
            genres=info.get('categories', []),
            release_date=info.get('publishedDate')
        )

    @staticmethod
    def map_spotify(track: dict) -> UnifiedContent:
        return UnifiedContent(
            id=f"music_{track.get('id')}",
            external_id=track.get('id'),
            type="music",
            title=track.get('name', ''),
            subtitle=", ".join([a['name'] for a in track.get('artists', [])]),
            description=f"Album: {track.get('album', {}).get('name')}",
            image_url=track.get('album', {}).get('images', [{}])[0].get('url'),
            rating=track.get('popularity', 0) / 10, # turn to 10grade rating
            genres=[], 
            release_date=track.get('album', {}).get('release_date')
        )