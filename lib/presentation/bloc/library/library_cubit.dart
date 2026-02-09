import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/content_repository.dart';
import 'library_state.dart'; // Создай по аналогии с SearchState (Initial, Loading, Loaded)

class LibraryCubit extends Cubit<LibraryState> {
  final ContentRepository repository;

  LibraryCubit(this.repository) : super(LibraryInitial());

  Future<void> loadFavorites() async {
    emit(LibraryLoading());
    try {
      final favorites = await repository.getFavorites();
      emit(LibraryLoaded(favorites));
    } catch (e) {
      emit(LibraryError("Failed to load favorites"));
    }
  }
}
