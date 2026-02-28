import 'package:flutter_test/flutter_test.dart';
import 'package:omnisource/presentation/bloc/search/search_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fakes.dart';

void main() {
  group('SearchCubit', () {
    late FakeContentRepository contentRepository;
    late FakeAnalyticsRepository analyticsRepository;
    late SearchCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'search_recent_queries': ['matrix'],
        'search_saved_queries': ['cyberpunk'],
      });

      contentRepository = FakeContentRepository();
      analyticsRepository = FakeAnalyticsRepository();
      cubit = SearchCubit(contentRepository, analyticsRepository);
      await cubit.init();
    });

    tearDown(() async {
      await cubit.close();
    });

    test('init loads recent and saved queries from preferences', () {
      expect(cubit.state.recentQueries, contains('matrix'));
      expect(cubit.state.savedQueries, contains('cyberpunk'));
    });

    test(
      'search with short query clears results and does not hit repository',
      () async {
        await cubit.search('a');

        expect(cubit.state.results, isEmpty);
        expect(cubit.state.isLoading, isFalse);
        expect(cubit.state.lastQuery, 'a');
        expect(contentRepository.searchCalls, 0);
      },
    );

    test('debounced search performs request and tracks analytics', () async {
      contentRepository.searchResponse = [
        makeContent(
          id: '1',
          externalId: 'track-1',
          type: 'music',
          title: 'Synthwave Track',
        ),
      ];

      await cubit.search('synthwave');
      await Future<void>.delayed(const Duration(milliseconds: 650));

      expect(contentRepository.searchCalls, 1);
      expect(contentRepository.lastSearchQuery, 'synthwave');
      expect(cubit.state.results.length, 1);
      expect(cubit.state.lastQuery, 'synthwave');
      expect(cubit.state.recentQueries.first, 'synthwave');
      expect(analyticsRepository.trackedEvents.length, 1);
      expect(analyticsRepository.trackedEvents.first['type'], 'search');
    });

    test('setFilter updates type and re-runs search for valid query', () async {
      contentRepository.searchResponse = [
        makeContent(
          id: 'm1',
          externalId: 'movie-1',
          type: 'movie',
          title: 'Movie',
        ),
      ];

      cubit.setFilter('movie', 'matrix');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.activeType, 'movie');
      expect(contentRepository.searchCalls, 1);
      expect(contentRepository.lastSearchType, 'movie');
    });

    test('setAdvancedFilters updates and clears year boundaries', () {
      cubit.setAdvancedFilters(minRating: 7.5, fromYear: 2010, toYear: 2022);
      expect(cubit.state.minRating, 7.5);
      expect(cubit.state.fromYear, 2010);
      expect(cubit.state.toYear, 2022);

      cubit.setAdvancedFilters(clearFromYear: true, clearToYear: true);
      expect(cubit.state.fromYear, isNull);
      expect(cubit.state.toYear, isNull);
    });

    test(
      'clearSearch resets search payload but preserves preferences and filters',
      () {
        cubit.setAdvancedFilters(minRating: 6.0, onlyLiked: true);
        contentRepository.searchResponse = [
          makeContent(id: 'x', externalId: 'x', type: 'movie', title: 'X'),
        ];
        cubit.clearSearch();

        expect(cubit.state.results, isEmpty);
        expect(cubit.state.errorMessage, isEmpty);
        expect(cubit.state.recentQueries, contains('matrix'));
        expect(cubit.state.savedQueries, contains('cyberpunk'));
        expect(cubit.state.minRating, 6.0);
        expect(cubit.state.onlyLiked, isTrue);
      },
    );

    test('save and remove saved query updates storage state', () async {
      await cubit.saveCurrentQuery('neo noir');
      expect(cubit.state.savedQueries.first, 'neo noir');

      await cubit.removeSavedQuery('neo noir');
      expect(cubit.state.savedQueries, isNot(contains('neo noir')));
    });

    test('clearRecentQueries empties recent history', () async {
      expect(cubit.state.recentQueries, isNotEmpty);

      await cubit.clearRecentQueries();

      expect(cubit.state.recentQueries, isEmpty);
    });

    test('search failure sets error message and ends loading', () async {
      contentRepository.searchError = Exception('network');

      await cubit.search('matrix');
      await Future<void>.delayed(const Duration(milliseconds: 650));

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, 'Something went wrong');
    });
  });
}
