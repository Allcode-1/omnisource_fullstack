import '../../domain/entities/unified_content.dart';
import '../../domain/repositories/content_repository.dart';
import '../models/content_model.dart';
import 'package:dio/dio.dart';

class ContentRepositoryImpl implements ContentRepository {
  final Dio _dio;

  ContentRepositoryImpl(this._dio);

  @override
  Future<List<UnifiedContent>> search(String query, {String? type}) async {
    try {
      final response = await _dio.get(
        '/discovery/search',
        queryParameters: {'query': query, if (type != null) 'type': type},
      );

      // turn json list to types list
      return (response.data as List)
          .map((item) => ContentModel.fromJson(item))
          .toList();
    } catch (e) {
      print("Search error: $e");
      return [];
    }
  }

  @override
  Future<List<UnifiedContent>> getFavorites() async {
    final response = await _dio.get('/actions/favorites');
    return (response.data as List)
        .map((item) => ContentModel.fromJson(item))
        .toList();
  }
}
