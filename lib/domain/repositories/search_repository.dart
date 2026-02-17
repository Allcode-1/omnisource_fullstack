import '../entities/unified_content.dart';

abstract class ContentRepository {
  Future<List<UnifiedContent>> search(String query, {String? type});
}
