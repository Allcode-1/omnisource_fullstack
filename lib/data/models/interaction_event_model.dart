import '../../domain/entities/interaction_event.dart';

class InteractionEventModel extends InteractionEvent {
  InteractionEventModel({
    required super.id,
    required super.type,
    required super.extId,
    required super.weight,
    required super.createdAt,
    super.contentType,
    super.title,
    super.imageUrl,
    super.meta,
  });

  factory InteractionEventModel.fromJson(Map<String, dynamic> json) {
    return InteractionEventModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'unknown').toString(),
      extId: (json['ext_id'] ?? '').toString(),
      contentType: json['content_type']?.toString(),
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      title: json['title']?.toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
