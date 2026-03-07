import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/interaction_event.dart';
import '../../domain/entities/usage_stats.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../models/app_notification_model.dart';
import '../models/interaction_event_model.dart';
import '../models/usage_stats_model.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  static const _offlineQueueKey = 'offline_queue_tasks';
  static const _maxOfflineQueueSize = 200;
  static const _maxReplayBatchSize = 20;

  final Dio _dio;

  AnalyticsRepositoryImpl(this._dio);

  @override
  Future<void> trackEvent({
    required String type,
    String? extId,
    String? contentType,
    double? weight,
    Map<String, dynamic>? meta,
  }) async {
    final payload = <String, dynamic>{
      'type': type,
      'ext_id': extId,
      'content_type': contentType,
      'weight': weight,
      'meta': meta ?? <String, dynamic>{},
    }..removeWhere((_, value) => value == null);

    try {
      await _dio.post('/actions/event', data: payload);
      await _replayOfflineQueue();
    } catch (e, st) {
      AppLogger.warning('Failed to track event $type. Added to offline queue');
      await enqueueOfflineTask(jsonEncode(payload));
      AppLogger.error(
        'Track event failed',
        error: e,
        stackTrace: st,
        name: 'AnalyticsRepository',
      );
    }
  }

  @override
  Future<List<InteractionEvent>> getTimeline({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/actions/timeline',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map(
            (item) => InteractionEventModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Load timeline failed',
        error: e,
        stackTrace: st,
        name: 'AnalyticsRepository',
      );
      return const [];
    }
  }

  @override
  Future<UsageStats> getStats({int days = 30}) async {
    try {
      final response = await _dio.get(
        '/actions/stats',
        queryParameters: {'days': days},
      );
      return UsageStatsModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (e, st) {
      AppLogger.error(
        'Load stats failed',
        error: e,
        stackTrace: st,
        name: 'AnalyticsRepository',
      );
      return UsageStatsModel(
        totalEvents: 0,
        countsByType: const {},
        ctr: 0.0,
        saveRate: 0.0,
        avgDwellSeconds: 0.0,
        topContentTypes: const {},
        abMetrics: const {},
      );
    }
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _dio.get('/actions/notifications');
      final items =
          (response.data as Map<String, dynamic>)['items'] as List<dynamic>? ??
          const [];
      return items
          .map(
            (item) => AppNotificationModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Load notifications failed',
        error: e,
        stackTrace: st,
        name: 'AnalyticsRepository',
      );
      return const [];
    }
  }

  @override
  Future<String> getRankingVariant() async {
    try {
      final response = await _dio.get('/user/ranking-variant');
      return (response.data as Map<String, dynamic>)['ranking_variant']
              ?.toString() ??
          'hybrid_ml';
    } catch (e, st) {
      AppLogger.error(
        'Get ranking variant failed',
        error: e,
        stackTrace: st,
        name: 'AnalyticsRepository',
      );
      return 'hybrid_ml';
    }
  }

  @override
  Future<String> setRankingVariant(String variant) async {
    try {
      final response = await _dio.patch(
        '/user/ranking-variant',
        data: {'ranking_variant': variant},
      );
      return (response.data as Map<String, dynamic>)['ranking_variant']
              ?.toString() ??
          variant;
    } catch (e, st) {
      AppLogger.error(
        'Set ranking variant failed',
        error: e,
        stackTrace: st,
        name: 'AnalyticsRepository',
      );
      return variant;
    }
  }

  @override
  Future<void> enqueueOfflineTask(String task) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_offlineQueueKey) ?? <String>[];
    list.insert(0, task);
    await prefs.setStringList(
      _offlineQueueKey,
      list.take(_maxOfflineQueueSize).toList(),
    );
  }

  @override
  Future<List<String>> getOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_offlineQueueKey) ?? const [];
  }

  @override
  Future<void> clearOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineQueueKey);
  }

  Future<void> _setOfflineQueue(List<String> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _offlineQueueKey,
      queue.take(_maxOfflineQueueSize).toList(),
    );
  }

  Future<void> _replayOfflineQueue() async {
    final queueNewestFirst = await getOfflineQueue();
    if (queueNewestFirst.isEmpty) return;

    final queueOldestFirst = queueNewestFirst.reversed.toList();
    final pendingOldestFirst = <String>[];
    var replayed = 0;
    var failed = false;

    for (var i = 0; i < queueOldestFirst.length; i++) {
      final task = queueOldestFirst[i];
      if (replayed >= _maxReplayBatchSize) {
        pendingOldestFirst.add(task);
        continue;
      }
      Map<String, dynamic> payload;
      try {
        final decoded = jsonDecode(task);
        if (decoded is! Map) {
          continue;
        }
        payload = Map<String, dynamic>.from(decoded);
      } catch (_) {
        continue;
      }

      try {
        await _dio.post('/actions/event', data: payload);
        replayed++;
      } catch (_) {
        pendingOldestFirst.addAll(queueOldestFirst.sublist(i));
        failed = true;
        break;
      }
    }

    if (!failed && pendingOldestFirst.isEmpty) {
      await clearOfflineQueue();
      return;
    }

    await _setOfflineQueue(pendingOldestFirst.reversed.toList());
  }
}
