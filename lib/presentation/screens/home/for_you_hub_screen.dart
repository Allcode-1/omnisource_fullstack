import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../bloc/home/home_cubit.dart';
import '../../bloc/library/library_cubit.dart';
import '../search/search_grid_card.dart';

class ForYouHubScreen extends StatefulWidget {
  const ForYouHubScreen({super.key});

  @override
  State<ForYouHubScreen> createState() => _ForYouHubScreenState();
}

class _ForYouHubScreenState extends State<ForYouHubScreen> {
  String _activeType = 'all';
  bool _isLoading = true;
  String _error = '';

  List<UnifiedContent> _recommendations = const [];
  List<UnifiedContent> _trending = const [];
  Map<String, List<UnifiedContent>> _homeMap = const {};

  bool get _hasData =>
      _recommendations.isNotEmpty ||
      _trending.isNotEmpty ||
      _homeMap.isNotEmpty;

  @override
  void initState() {
    super.initState();
    context.read<LibraryCubit>().loadLibraryData(showLoader: false);
    _hydrateFromHome();
    _load(silent: _hasData);
  }

  void _hydrateFromHome() {
    final homeState = context.read<HomeCubit>().state;
    if (homeState.recommendations.isEmpty &&
        homeState.trending.isEmpty &&
        homeState.homeMap.isEmpty) {
      return;
    }

    setState(() {
      _activeType = _typeForCategory(homeState.category);
      _recommendations = homeState.recommendations;
      _trending = homeState.trending;
      _homeMap = homeState.homeMap;
      _isLoading = false;
    });
  }

  String _typeForCategory(ContentCategory category) {
    switch (category) {
      case ContentCategory.movie:
        return 'movie';
      case ContentCategory.book:
        return 'book';
      case ContentCategory.music:
        return 'music';
    }
  }

  Future<void> _load({bool silent = false}) async {
    final hadData = _hasData;
    if (!silent || !hadData) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    } else {
      setState(() => _error = '');
    }

    try {
      final repo = context.read<ContentRepository>();
      final type = _activeType == 'all' ? null : _activeType;
      final results = await Future.wait([
        repo.getRecommendations(type: type),
        repo.getTrending(type: type),
        repo.getHomeData(type: type),
      ]);
      if (!mounted) return;
      setState(() {
        _recommendations = results[0] as List<UnifiedContent>;
        _trending = results[1] as List<UnifiedContent>;
        _homeMap = results[2] as Map<String, List<UnifiedContent>>;
      });
    } catch (_) {
      if (!mounted) return;
      if (!hadData) {
        setState(() => _error = 'Failed to load for-you feed');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setType(String type) {
    if (_activeType == type) return;
    setState(() => _activeType = type);
    _load(silent: _hasData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              'For You',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            border: null,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.84),
          ),
          CupertinoSliverRefreshControl(onRefresh: () => _load()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                'Personalized recommendations with context',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTypeFilters(theme),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          if (_isLoading && !_hasData)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_error.isNotEmpty && !_hasData)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error,
                      style: const TextStyle(color: Color(0xFFFF7A7A)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                _buildHeroInsight(theme),
                _buildSectionGrid(
                  theme,
                  'Recommended For You',
                  _recommendations,
                ),
                _buildSectionGrid(theme, 'Trending Match', _trending),
                ..._homeMap.entries
                    .where(
                      (entry) =>
                          entry.key != 'For You' && entry.key != 'Trending Now',
                    )
                    .take(3)
                    .map(
                      (entry) =>
                          _buildSectionGrid(theme, entry.key, entry.value),
                    ),
                const SizedBox(height: 90),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroInsight(ThemeData theme) {
    final count = _recommendations.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
              AppTheme.surfaceAlt.withValues(alpha: 0.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.sparkles, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You have $count curated items in your feed now.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilters(ThemeData theme) {
    final filters = const [
      ('All', 'all'),
      ('Movies', 'movie'),
      ('Music', 'music'),
      ('Books', 'book'),
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final label = filters[index].$1;
          final value = filters[index].$2;
          final selected = value == _activeType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _setType(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.surface.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: selected ? 0.14 : 0.08,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionGrid(
    ThemeData theme,
    String title,
    List<UnifiedContent> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    final shortlist = items.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shortlist.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.63,
            ),
            itemBuilder: (context, index) {
              return SearchGridCard(item: shortlist[index]);
            },
          ),
        ],
      ),
    );
  }
}
