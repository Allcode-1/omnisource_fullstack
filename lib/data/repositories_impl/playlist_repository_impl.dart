import 'package:dio/dio.dart';
import '../../domain/entities/unified_content.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../models/content_model.dart';
import '../models/playlist_model.dart';
import '../../core/constants/api_constants.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final Dio _dio;
  PlaylistRepositoryImpl(this._dio);

  @override
  Future<List<PlaylistModel>> getPlaylists() async {
    final response = await _dio.get(ApiConstants.playlists);
    return (response.data as List)
        .map((item) => PlaylistModel.fromJson(item))
        .toList();
  }

  @override
  Future<PlaylistModel> createPlaylist(
    String title, {
    String? description,
  }) async {
    final response = await _dio.post(
      ApiConstants.playlists,
      queryParameters: {
        'title': title,
        if (description != null) 'description': description,
      },
    );
    return PlaylistModel.fromJson(response.data);
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await _dio.delete('${ApiConstants.playlists}/$id');
  }

  @override
  Future<void> addToPlaylist(String playlistId, UnifiedContent content) async {
    await _dio.post(
      '${ApiConstants.playlists}/$playlistId/add',
      data: ContentModel.fromEntity(content).toJson(),
    );
  }

  @override
  Future<void> removeFromPlaylist(String playlistId, String externalId) async {
    await _dio.delete(
      '${ApiConstants.playlists}/$playlistId/remove/$externalId',
    );
  }

  @override
  Future<List<UnifiedContent>> getPlaylistContent(String playlistId) async {
    final response = await _dio.get('${ApiConstants.playlists}/$playlistId');
    final List itemsRaw = response.data['items'] ?? [];
    return itemsRaw.map((item) {
      if (item['ext_id'] != null) item['external_id'] = item['ext_id'];
      return ContentModel.fromJson(item);
    }).toList();
  }
}
