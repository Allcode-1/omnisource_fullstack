import 'package:dio/dio.dart';
import '../../domain/entities/unified_content.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../models/content_model.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final Dio _dio;
  PlaylistRepositoryImpl(this._dio);

  @override
  Future<void> createPlaylist(String name) async {
    await _dio.post('/actions/playlists', data: {'name': name});
  }

  @override
  Future<void> addToPlaylist(String playlistId, String contentId) async {
    await _dio.post(
      '/actions/playlists/$playlistId/add',
      data: {'content_id': contentId},
    );
  }

  @override
  Future<List<UnifiedContent>> getPlaylistContent(String playlistId) async {
    final response = await _dio.get('/actions/playlists/$playlistId');
    return (response.data as List)
        .map((e) => ContentModel.fromJson(e))
        .toList();
  }
}
