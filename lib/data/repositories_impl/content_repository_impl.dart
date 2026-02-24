import 'package:omnisource/data/models/playlist_model.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/unified_content.dart';
import '../../domain/repositories/content_repository.dart';
import '../models/content_model.dart';
import '../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';

class ContentRepositoryImpl implements ContentRepository {
  final Dio _dio;
  ContentRepositoryImpl(this._dio);

  @override
  Future<Map<String, List<UnifiedContent>>> getHomeData({String? type}) async {
    try {
      final response = await _dio.get(
        ApiConstants.home,
        queryParameters: {if (type != null) 'type': type},
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );
      return data.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((i) => ContentModel.fromJson(i)).toList(),
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Home data request failed',
        error: e,
        stackTrace: st,
        name: 'ContentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<UnifiedContent>> getRecommendations({String? type}) async {
    try {
      final response = await _dio.get(
        ApiConstants.recommendations,
        queryParameters: {if (type != null) 'type': type},
      );
      return (response.data as List)
          .map((i) => ContentModel.fromJson(i))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Recommendations request failed',
        error: e,
        stackTrace: st,
        name: 'ContentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<UnifiedContent>> search(String query, {String? type}) async {
    try {
      final response = await _dio.get(
        ApiConstants.search,
        queryParameters: {'query': query, if (type != null) 'type': type},
      );
      return (response.data as List)
          .map((item) => ContentModel.fromJson(item))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Search request failed',
        error: e,
        stackTrace: st,
        name: 'ContentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> toggleLike(UnifiedContent item) async {
    try {
      await _dio.post(
        ApiConstants.like,
        data: ContentModel.fromEntity(item).toJson(),
      );
    } catch (e, st) {
      AppLogger.error(
        'Toggle like failed',
        error: e,
        stackTrace: st,
        name: 'ContentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<UnifiedContent>> getFavorites({String? type}) async {
    try {
      final response = await _dio.get(
        ApiConstants.favorites,
        queryParameters: {if (type != null) 'type': type},
      );

      return (response.data as List).map((item) {
        if (item is Map && item['ext_id'] != null) {
          item['external_id'] = item['ext_id'];
        }
        return ContentModel.fromJson(item);
      }).toList();
    } catch (e, st) {
      AppLogger.error(
        'Favorites request failed',
        error: e,
        stackTrace: st,
        name: 'ContentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<UnifiedContent>> getTrending({String? type}) async {
    try {
      final response = await _dio.get(
        ApiConstants.trending,
        queryParameters: {if (type != null) 'type': type},
      );
      return (response.data as List)
          .map((i) => ContentModel.fromJson(i))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Trending request failed',
        error: e,
        stackTrace: st,
        name: 'ContentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<UnifiedContent>> getDiscovery(String tag) async {
    try {
      final response = await _dio.get(
        '/content/discover',
        queryParameters: {'tag': tag},
      );
      return (response.data as List)
          .map((i) => ContentModel.fromJson(i))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Discovery request failed',
        error: e,
        stackTrace: st,
        name: 'ContentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<UnifiedContent>> getDeepResearch(
    String tag, {
    String? type,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.deepResearch,
        queryParameters: {'tag': tag, if (type != null) 'type': type},
      );
      return (response.data as List)
          .map((item) => ContentModel.fromJson(item))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Deep research request failed',
        error: e,
        stackTrace: st,
        name: 'ContentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<PlaylistModel>> getPlaylists() async {
    try {
      final response = await _dio.get(ApiConstants.playlists);
      return (response.data as List)
          .map((item) => PlaylistModel.fromJson(item))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Playlists request failed',
        error: e,
        stackTrace: st,
        name: 'ContentRepository',
      );
      rethrow;
    }
  }
}
