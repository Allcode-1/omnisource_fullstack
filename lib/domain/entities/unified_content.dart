class UnifiedContent {
  final String id;
  final String externalId;
  final String type;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final double rating;
  final List<String> genres;
  final String? releaseDate;

  UnifiedContent({
    required this.id,
    required this.externalId,
    required this.type,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.rating = 0.0,
    this.genres = const [],
    this.releaseDate,
  });
}
