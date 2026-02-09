import '../entities/unified_content.dart';

abstract class PlaylistRepository {
  Future<void> createPlaylist(String name);
  Future<void> addToPlaylist(String playlistId, String contentId);
  // in backend endpoint returns playlists info
  Future<List<UnifiedContent>> getPlaylistContent(String playlistId);
}
