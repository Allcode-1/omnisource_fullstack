class InteractionEvent {
  final String id;
  final String type;
  final String extId;
  final String? contentType;
  final double weight;
  final String? title;
  final String? imageUrl;
  final DateTime createdAt;
  final Map<String, dynamic> meta;

  InteractionEvent({
    required this.id,
    required this.type,
    required this.extId,
    required this.weight,
    required this.createdAt,
    this.contentType,
    this.title,
    this.imageUrl,
    this.meta = const {},
  });
}
