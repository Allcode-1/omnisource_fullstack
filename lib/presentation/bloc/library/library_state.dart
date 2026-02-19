import '../../../domain/entities/unified_content.dart';
import '../../../data/models/playlist_model.dart';

abstract class LibraryState {}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<UnifiedContent> favorites;
  final List<PlaylistModel> playlists;

  LibraryLoaded({required this.favorites, required this.playlists});
}

class LibraryError extends LibraryState {
  final String message;
  LibraryError(this.message);
}
