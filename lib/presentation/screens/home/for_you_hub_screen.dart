import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/content_repository.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<LibraryCubit>().loadLibraryData();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load for-you feed');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setType(String type) {
    if (_activeType == type) return;
    setState(() => _activeType = type);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 56)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'For You Hub',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Personalized recommendations with context',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTypeFilters(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error,
                      style: const TextStyle(color: Colors.redAccent),
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
                _buildHeroInsight(),
                _buildSectionGrid('Recommended For You', _recommendations),
                _buildSectionGrid('Trending Match', _trending),
                ..._homeMap.entries
                    .where(
                      (entry) =>
                          entry.key != 'For You' && entry.key != 'Trending Now',
                    )
                    .take(3)
                    .map((entry) => _buildSectionGrid(entry.key, entry.value)),
                const SizedBox(height: 90),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroInsight() {
    final count = _recommendations.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A84FF), Color(0xFF064C93)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.sparkles, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You have $count curated items in your feed now.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
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
                  color: selected ? Colors.white : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
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

  Widget _buildSectionGrid(String title, List<UnifiedContent> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final shortlist = items.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
