import '../entities/unified_content.dart';

abstract class ContentRepository {
  // search: gets request and optionally a type of content
  Future<List<UnifiedContent>> search(String query, {String? type});

  // get favourite: returns all fovorite content of the user
  Future<List<UnifiedContent>> getFavorites();
}
