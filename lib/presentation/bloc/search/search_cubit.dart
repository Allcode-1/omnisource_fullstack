import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/content_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final ContentRepository contentRepository;

  SearchCubit(this.contentRepository) : super(SearchInitial());

  Future<void> searchContent(String query, {String? type}) async {
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());
    try {
      final results = await contentRepository.search(query, type: type);
      emit(SearchLoaded(results));
    } catch (e) {
      emit(SearchError("Nothing found or server error."));
    }
  }
}
