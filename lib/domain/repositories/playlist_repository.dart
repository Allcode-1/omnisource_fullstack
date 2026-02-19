import '../entities/unified_content.dart';
import '../../data/models/playlist_model.dart';

abstract class PlaylistRepository {
  Future<List<PlaylistModel>> getPlaylists();
  Future<PlaylistModel> createPlaylist(String title, {String? description});
  Future<void> deletePlaylist(String id);
  Future<void> addToPlaylist(String playlistId, UnifiedContent content);
  Future<void> removeFromPlaylist(String playlistId, String externalId);
  Future<List<UnifiedContent>> getPlaylistContent(String playlistId);
}
