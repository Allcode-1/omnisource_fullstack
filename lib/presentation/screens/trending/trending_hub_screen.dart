import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../bloc/home/home_cubit.dart';
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
    final theme = Theme.of(context);
    final activeType = _tabs[_tabController.index].$2;
    final items = _cache[activeType] ?? const [];
    final headerCount = items.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.only(right: 8),
                    minimumSize: Size.zero,
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Icon(CupertinoIcons.back, size: 22),
                  ),
                  Text(
                    'Trending',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.flame_fill, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live trend map by content type',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$headerCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
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
            Expanded(
              child: _isLoading && items.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : _error.isNotEmpty && items.isEmpty
                  ? Center(
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
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          _loadForCurrentTab(force: true, silent: false),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.63,
                            ),
                        itemBuilder: (context, index) {
                          return SearchGridCard(item: items[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
