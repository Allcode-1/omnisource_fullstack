import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../../domain/entities/unified_content.dart';
import 'home_state.dart';

export 'home_state.dart';

enum ContentCategory { music, movie, book }

class HomeCubit extends Cubit<HomeState> {
  final ContentRepository repository;

  HomeCubit(this.repository)
    : super(HomeState(category: ContentCategory.music));

  void setCategory(ContentCategory category) {
    if (state.category == category) return;
    emit(state.copyWith(category: category, isLoading: true));
    loadContent();
  }

  String _getCategoryType() {
    switch (state.category) {
      case ContentCategory.movie:
        return 'movie';
      case ContentCategory.book:
        return 'book';
      case ContentCategory.music:
        return 'music';
    }
  }

  Future<void> loadContent() async {
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      final type = _getCategoryType();

      final results = await Future.wait([
        repository.getTrending(type: type),
        repository.getRecommendations(type: type),
        repository.getHomeData(type: type),
      ]);

      final trendingList = results[0] as List<UnifiedContent>;
      final recsList = results[1] as List<UnifiedContent>;
      final homeDataMap = results[2] as Map<String, List<UnifiedContent>>;

      final finalTrending =
          homeDataMap['Trending Now'] ??
          homeDataMap['Trending'] ??
          trendingList;

      emit(
        state.copyWith(
          isLoading: false,
          trending: finalTrending,
          recommendations: homeDataMap['For You'] ?? recsList,
          homeMap: homeDataMap,
          error: '',
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Home content loading failed',
        error: e,
        stackTrace: st,
        name: 'HomeCubit',
      );
      emit(state.copyWith(error: "Ошибка загрузки: ${e.toString()}"));
    } finally {
      if (state.isLoading) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  Future<void> toggleLike(UnifiedContent item) async {
    try {
      await repository.toggleLike(item);
    } catch (e, st) {
      AppLogger.error(
        'Toggle like failed in HomeCubit',
        error: e,
        stackTrace: st,
        name: 'HomeCubit',
      );
    }
  }
}
