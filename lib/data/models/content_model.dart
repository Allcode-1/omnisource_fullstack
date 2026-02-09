import '../../domain/entities/unified_content.dart';

class ContentModel extends UnifiedContent {
  ContentModel({
    required super.id,
    required super.externalId,
    required super.type,
    required super.title,
    required super.subtitle,
    super.description,
    super.imageUrl,
    super.rating,
    super.genres,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['_id']?.toString() ?? '',
      externalId: json['ext_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      genres: List<String>.from(json['genres'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ext_id': externalId,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'genres': genres,
    };
  }
}
