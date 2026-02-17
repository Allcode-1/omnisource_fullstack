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
    final response = await _dio.get(
      ApiConstants.home,
      queryParameters: {if (type != null) 'type': type},
    );

    final Map<String, dynamic> data = response.data;
    return data.map(
      (key, value) => MapEntry(
        key,
        (value as List).map((i) {
          try {
            return ContentModel.fromJson(i);
          } catch (e) {
            print("ERROR mapping item in section $key: $e");
            print("Offending item: $i");
            rethrow;
          }
        }).toList(),
      ),
    );
  }

  @override
  Future<List<UnifiedContent>> getRecommendations({String? type}) async {
    final response = await _dio.get(
      ApiConstants.recommendations,
      queryParameters: {if (type != null) 'type': type},
    );
    return (response.data as List)
        .map((i) => ContentModel.fromJson(i))
        .toList();
  }

  @override
  Future<List<UnifiedContent>> search(String query, {String? type}) async {
    final response = await _dio.get(
      ApiConstants.search,
      queryParameters: {'query': query, if (type != null) 'type': type},
    );
    return (response.data as List)
        .map((item) => ContentModel.fromJson(item))
        .toList();
  }

  @override
  Future<void> toggleLike(UnifiedContent item) async {
    await _dio.post(
      ApiConstants.like,
      data: ContentModel.fromEntity(item).toJson(),
    );
  }

  @override
  Future<List<UnifiedContent>> getFavorites({String? type}) async {
    final response = await _dio.get(
      ApiConstants.favorites,
      queryParameters: {if (type != null) 'type': type},
    );
    return (response.data as List)
        .map((item) => ContentModel.fromJson(item))
        .toList();
  }

  @override
  Future<List<UnifiedContent>> getTrending({String? type}) async {
    final response = await _dio.get(
      ApiConstants.trending,
      queryParameters: {if (type != null) 'type': type},
    );
    return (response.data as List)
        .map((i) => ContentModel.fromJson(i))
        .toList();
  }

  @override
  Future<List<UnifiedContent>> getDiscovery(String tag) async {
    final response = await _dio.get(
      '/content/discover',
      queryParameters: {'tag': tag},
    );
    return (response.data as List)
        .map((i) => ContentModel.fromJson(i))
        .toList();
  }
}
