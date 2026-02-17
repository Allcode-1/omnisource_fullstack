import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../../domain/entities/unified_content.dart';
import 'home_state.dart';

export 'home_state.dart';

enum ContentCategory { music, movie, book }

class HomeCubit extends Cubit<HomeState> {
  final ContentRepository repository;

  HomeCubit(this.repository)
    : super(HomeState(category: ContentCategory.music)) {
    loadContent();
  }

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
    // Не спамим загрузкой, если уже грузим
    if (state.isLoading == false && state.trending.isEmpty) {
      emit(state.copyWith(isLoading: true));
    }

    try {
      final type = _getCategoryType();
      print("[HOME_CUBIT] Начинаю загрузку для типа: $type");

      // Параллельно запускаем все запросы
      final results = await Future.wait([
        repository.getTrending(type: type),
        repository.getRecommendations(type: type),
        repository.getHomeData(type: type),
      ]);

      final trendingList = results[0] as List<UnifiedContent>;
      final recsList = results[1] as List<UnifiedContent>;
      final homeDataMap = results[2] as Map<String, List<UnifiedContent>>;

      print("[HOME_CUBIT] Данные получены успешно!");
      print("[HOME_CUBIT] Трендов: ${trendingList.length}");
      print("[HOME_CUBIT] Секций в HomeMap: ${homeDataMap.keys.toList()}");

      // Пытаемся вытащить тренды из HomeMap (бэкенд присылает их там как 'Trending Now')
      // Если там пусто, берем из отдельного списка трендов
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
    } catch (e, stack) {
      print("[HOME_CUBIT] КРИТИЧЕСКАЯ ОШИБКА: $e");
      print("[HOME_CUBIT] STACKTRACE: $stack");

      emit(
        state.copyWith(
          isLoading: false,
          error: "Ошибка загрузки: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> toggleLike(UnifiedContent item) async {
    try {
      await repository.toggleLike(item);
    } catch (e) {
      print("[HOME_CUBIT] Ошибка при лайке: $e");
    }
  }
}
