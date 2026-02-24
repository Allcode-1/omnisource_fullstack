import '../../../domain/entities/unified_content.dart';
import '../../../data/models/playlist_model.dart';

abstract class LibraryState {}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<UnifiedContent> favorites;
  final List<PlaylistModel> playlists;
  final Map<String, List<UnifiedContent>> playlistItemsById;

  LibraryLoaded({
    required this.favorites,
    required this.playlists,
    required this.playlistItemsById,
  });

  LibraryLoaded copyWith({
    List<UnifiedContent>? favorites,
    List<PlaylistModel>? playlists,
    Map<String, List<UnifiedContent>>? playlistItemsById,
  }) {
    return LibraryLoaded(
      favorites: favorites ?? this.favorites,
      playlists: playlists ?? this.playlists,
      playlistItemsById: playlistItemsById ?? this.playlistItemsById,
    );
  }
}

class LibraryError extends LibraryState {
  final String message;
  LibraryError(this.message);
}
