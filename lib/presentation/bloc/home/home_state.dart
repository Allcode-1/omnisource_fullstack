import '../../../domain/entities/unified_content.dart';
import 'home_cubit.dart';

class HomeState {
  final ContentCategory category;
  final List<UnifiedContent> trending;
  final List<UnifiedContent> recommendations;
  final Map<String, List<UnifiedContent>> homeMap;
  final bool isLoading;
  final String? error;

  HomeState({
    required this.category,
    this.trending = const [],
    this.recommendations = const [],
    this.homeMap = const {},
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    ContentCategory? category,
    List<UnifiedContent>? trending,
    List<UnifiedContent>? recommendations,
    Map<String, List<UnifiedContent>>? homeMap,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      category: category ?? this.category,
      trending: trending ?? this.trending,
      recommendations: recommendations ?? this.recommendations,
      homeMap: homeMap ?? this.homeMap,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
