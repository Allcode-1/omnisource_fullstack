import 'package:dio/dio.dart';
import '../../domain/entities/unified_content.dart';
import '../../domain/repositories/search_repository.dart';
import '../models/content_model.dart';

class ContentRepositoryImpl implements ContentRepository {
  final Dio _dio;

  ContentRepositoryImpl(this._dio);

  @override
  Future<List<UnifiedContent>> search(String query, {String? type}) async {
    try {
      final response = await _dio.get(
        '/content/search',
        queryParameters: {'query': query, 'type': type ?? 'all'},
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => ContentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search content: $e');
    }
  }
}
