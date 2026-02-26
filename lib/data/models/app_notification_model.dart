import '../../domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  AppNotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.level,
    required super.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      level: (json['level'] ?? 'info').toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
