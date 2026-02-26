class PlaylistModel {
  final String id;
  final String title;
  final String? description;
  final List<String> items;

  PlaylistModel({
    required this.id,
    required this.title,
    this.description,
    required this.items,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      description: json['description'],
      items: List<String>.from(json['items'] ?? []),
    );
  }
}
