import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/repositories/content_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final ContentRepository contentRepository;
  Timer? _debounce;

  SearchCubit(this.contentRepository) : super(SearchState());

  Future<void> search(String query) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.trim().length < 2) {
      emit(state.copyWith(results: [], isLoading: false, errorMessage: ''));
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void setFilter(String type, String currentQuery) {
    if (state.activeType == type) return;

    emit(state.copyWith(activeType: type));

    if (currentQuery.trim().length >= 2) {
      _debounce?.cancel();
      _performSearch(currentQuery);
    }
  }

  Future<void> _performSearch(String query) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final results = await contentRepository.search(
        query,
        type: state.activeType, // Передаем 'all', 'movie' и т.д.
      );

      emit(state.copyWith(results: results, isLoading: false));
    } catch (e, st) {
      AppLogger.error(
        'Search failed for query: $query',
        error: e,
        stackTrace: st,
        name: 'SearchCubit',
      );
      emit(
        state.copyWith(isLoading: false, errorMessage: 'Something went wrong'),
      );
    } finally {
      if (state.isLoading) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  void clearSearch() {
    _debounce?.cancel();
    emit(SearchState(activeType: state.activeType));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
