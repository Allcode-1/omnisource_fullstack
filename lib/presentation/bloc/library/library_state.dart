import '../../../domain/entities/unified_content.dart';

abstract class LibraryState {}

// initial state (like just calm state)
class LibraryInitial extends LibraryState {}

// while loading favourites or playlists
class LibraryLoading extends LibraryState {}

// when data correctly parsed from backend
class LibraryLoaded extends LibraryState {
  final List<UnifiedContent> favorites;
  // TODO: List.playlist here in future
  LibraryLoaded(this.favorites);
}

// if backend throws 404 or 500
class LibraryError extends LibraryState {
  final String message;
  LibraryError(this.message);
}
