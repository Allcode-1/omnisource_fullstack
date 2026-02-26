import '../entities/app_notification.dart';
import '../entities/interaction_event.dart';
import '../entities/usage_stats.dart';

abstract class AnalyticsRepository {
  Future<void> trackEvent({
    required String type,
    String? extId,
    String? contentType,
    double? weight,
    Map<String, dynamic>? meta,
  });

  Future<List<InteractionEvent>> getTimeline({int limit = 50});
  Future<UsageStats> getStats({int days = 30});
  Future<List<AppNotification>> getNotifications();

  Future<String> getRankingVariant();
  Future<String> setRankingVariant(String variant);

  Future<void> enqueueOfflineTask(String task);
  Future<List<String>> getOfflineQueue();
  Future<void> clearOfflineQueue();
}
