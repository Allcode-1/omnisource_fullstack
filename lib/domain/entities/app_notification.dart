class AppNotification {
  final String id;
  final String title;
  final String body;
  final String level;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.level,
    required this.createdAt,
  });
}
