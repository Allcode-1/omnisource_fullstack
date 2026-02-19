import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../data/models/playlist_model.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final ContentRepository contentRepository;
  final PlaylistRepository playlistRepository;

  LibraryCubit({
    required this.contentRepository,
    required this.playlistRepository,
  }) : super(LibraryInitial());

  Future<void> loadLibraryData() async {
    emit(LibraryLoading());
    try {
      final results = await Future.wait([
        contentRepository.getFavorites(),
        playlistRepository.getPlaylists(),
      ]);
      emit(
        LibraryLoaded(
          favorites: results[0] as List<UnifiedContent>,
          playlists: results[1] as List<PlaylistModel>,
        ),
      );
    } catch (e) {
      print("Library Load Error: $e");
      emit(LibraryError("Failed to load library data"));
    }
  }

  Future<void> createPlaylist(String title) async {
    try {
      await playlistRepository.createPlaylist(title);
      await loadLibraryData(); // Обновляем список
    } catch (e) {
      print("Create Error: $e");
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      await playlistRepository.deletePlaylist(id);
      await loadLibraryData();
    } catch (e) {
      print("Delete Error: $e");
    }
  }
}
