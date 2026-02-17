import '../entities/unified_content.dart';

abstract class ContentRepository {
  Future<List<UnifiedContent>> search(String query, {String? type});
  Future<void> toggleLike(UnifiedContent item);
  Future<List<UnifiedContent>> getFavorites({String? type});
  Future<Map<String, List<UnifiedContent>>> getHomeData({String? type});
  Future<List<UnifiedContent>> getTrending({String? type});
  Future<List<UnifiedContent>> getRecommendations({String? type});
  Future<List<UnifiedContent>> getDiscovery(String tag);
}
