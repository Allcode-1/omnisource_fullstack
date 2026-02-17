import '../../../domain/entities/unified_content.dart';

class SearchState {
  final List<UnifiedContent> results;
  final bool isLoading;
  final String activeType; // 'all', 'movie', 'music', 'book'
  final String errorMessage;

  SearchState({
    this.results = const [],
    this.isLoading = false,
    this.activeType = 'all',
    this.errorMessage = '',
  });

  SearchState copyWith({
    List<UnifiedContent>? results,
    bool? isLoading,
    String? activeType,
    String? errorMessage,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      activeType: activeType ?? this.activeType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
