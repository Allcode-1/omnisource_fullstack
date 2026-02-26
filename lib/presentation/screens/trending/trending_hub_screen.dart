import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/content_repository.dart';
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
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadForCurrentTab();
    });
    _loadForCurrentTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadForCurrentTab() async {
    final type = _tabs[_tabController.index].$2;
    if (_cache.containsKey(type)) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final repo = context.read<ContentRepository>();
      final data = await repo.getTrending(type: type == 'all' ? null : type);
      if (!mounted) return;
      _cache[type] = data;
    } catch (_) {
      if (!mounted) return;
      _error = 'Failed to load trending feed';
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

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 56),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Trending Hub',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text(
                  'Live trend map by content type',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: const Color(0xFF0A84FF),
            tabs: _tabs.map((tab) => Tab(text: tab.$1)).toList(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? Center(child: Text(_error))
                : RefreshIndicator(
                    onRefresh: () async {
                      _cache.remove(activeType);
                      await _loadForCurrentTab();
                    },
                    child: GridView.builder(
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
    );
  }
}
