class UnifiedContent {
  final String id; // insert id from db
  final String externalId; // id from foreign api
  final String type; // movie, book, music
  final String title;
  final String subtitle;
  final String? description;
  final String? imageUrl;
  final double rating;
  final List<String> genres;

  UnifiedContent({
    required this.id,
    required this.externalId,
    required this.type,
    required this.title,
    required this.subtitle,
    this.description,
    this.imageUrl,
    this.rating = 0.0,
    this.genres = const [],
  });
}
