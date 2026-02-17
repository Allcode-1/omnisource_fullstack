import '../../domain/entities/unified_content.dart';

class ContentModel extends UnifiedContent {
  ContentModel({
    required super.id,
    required super.externalId,
    required super.type,
    required super.title,
    super.subtitle,
    super.description,
    super.imageUrl,
    super.rating,
    super.genres,
    super.releaseDate,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      externalId: (json['ext_id'] ?? json['external_id'] ?? '').toString(),

      type: json['type']?.toString() ?? 'unknown',
      title: json['title']?.toString() ?? 'No Title',
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),

      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,

      genres: json['genres'] != null
          ? List<String>.from(json['genres'].map((g) => g.toString()))
          : const [],

      releaseDate: json['release_date']?.toString(),
    );
  }

  factory ContentModel.fromEntity(UnifiedContent entity) {
    return ContentModel(
      id: entity.id,
      externalId: entity.externalId,
      type: entity.type,
      title: entity.title,
      subtitle: entity.subtitle,
      description: entity.description,
      imageUrl: entity.imageUrl,
      rating: entity.rating,
      genres: entity.genres,
      releaseDate: entity.releaseDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ext_id': externalId,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'genres': genres,
      'release_date': releaseDate,
    };
  }
}
