import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../bloc/home/home_cubit.dart';
import '../../widgets/secondary_header_sliver.dart';
import '../search/search_grid_card.dart';

class TrendingHubScreen extends StatefulWidget {
  const TrendingHubScreen({super.key});

  @override
  State<TrendingHubScreen> createState() => _TrendingHubScreenState();
}

class _TrendingHubScreenState extends State<TrendingHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, List<UnifiedContent>> _cache = {};
  bool _isLoading = true;
  String _error = '';

  static const _tabs = [
    ('All', 'all'),
    ('Movies', 'movie'),
    ('Music', 'music'),
    ('Books', 'book'),
  ];

  @override
  void initState() {
    super.initState();
    final homeState = context.read<HomeCubit>().state;
    final initialType = _typeForCategory(homeState.category);
    final initialIndex = _tabs.indexWhere((tab) => tab.$2 == initialType);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
    if (homeState.trending.isNotEmpty) {
      _cache[initialType] = homeState.trending;
      _isLoading = false;
    }

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadForCurrentTab(silent: true);
    });
    _loadForCurrentTab(silent: _cache.isNotEmpty);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadForCurrentTab({
    bool silent = false,
    bool force = false,
  }) async {
    final type = _tabs[_tabController.index].$2;
    if (!force && _cache.containsKey(type)) {
      setState(() {
        _error = '';
        _isLoading = false;
      });
      return;
    }

    if (!silent || _cache.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    } else {
      setState(() => _error = '');
    }

    try {
      final repo = context.read<ContentRepository>();
      final data = await repo.getTrending(type: type == 'all' ? null : type);
      if (!mounted) return;
      _cache[type] = data;
    } catch (_) {
      if (!mounted) return;
      if (!_cache.containsKey(type)) {
        _error = 'Failed to load trending feed';
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeType = _tabs[_tabController.index].$2;
    final items = _cache[activeType] ?? const [];
    final headerCount = items.length;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SecondaryHeaderSliver(
            title: 'Trending',
            subtitle: 'Live trend map by content type',
            infoLabel: '$headerCount active picks in this stream',
            infoIcon: CupertinoIcons.flame_fill,
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => _loadForCurrentTab(force: true, silent: false),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelColor: Colors.white54,
                indicatorColor: AppTheme.primary,
                dividerColor: Colors.white.withValues(alpha: 0.06),
                tabs: _tabs.map((tab) => Tab(text: tab.$1)).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_isLoading && items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_error.isNotEmpty && items.isEmpty)
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
                      onPressed: () => _loadForCurrentTab(force: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.63,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return SearchGridCard(item: items[index]);
                }, childCount: items.length),
              ),
            ),
        ],
      ),
    );
  }
}
