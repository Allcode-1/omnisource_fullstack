import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/content_repository.dart';

class ContentComparisonScreen extends StatefulWidget {
  const ContentComparisonScreen({super.key});

  @override
  State<ContentComparisonScreen> createState() =>
      _ContentComparisonScreenState();
}

class _ContentComparisonScreenState extends State<ContentComparisonScreen> {
  bool _loading = true;
  String _error = '';
  String _activeType = 'all';
  List<UnifiedContent> _items = const [];
  final List<UnifiedContent> _selected = [];

  String _contentKey(UnifiedContent item) => '${item.type}:${item.externalId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final repo = context.read<ContentRepository>();
      final type = _activeType == 'all' ? null : _activeType;
      final responses = await Future.wait([
        repo.getTrending(type: type),
        repo.getRecommendations(type: type),
      ]);

      final merged = <String, UnifiedContent>{};
      for (final list in responses) {
        for (final item in list) {
          merged[_contentKey(item)] = item;
        }
      }

      final nextItems = merged.values.toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      if (!mounted) return;
      setState(() => _items = nextItems.take(36).toList());
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load comparison candidates');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setType(String type) {
    if (_activeType == type) return;
    setState(() {
      _activeType = type;
      _selected.clear();
    });
    _load();
  }

  void _toggleSelection(UnifiedContent item) {
    final key = _contentKey(item);
    final exists = _selected.any((selected) => _contentKey(selected) == key);
    setState(() {
      if (exists) {
        _selected.removeWhere((selected) => _contentKey(selected) == key);
      } else if (_selected.length < 3) {
        _selected.add(item);
      }
    });
  }

  int? _releaseYear(UnifiedContent item) {
    final raw = item.releaseDate;
    if (raw == null || raw.isEmpty) return null;
    if (raw.length >= 4) {
      return int.tryParse(raw.substring(0, 4));
    }
    return int.tryParse(raw);
  }

  double _relevanceScore(UnifiedContent item) {
    final selectedGenres = _selected
        .expand((content) => content.genres)
        .toSet();
    final overlap = item.genres.where(selectedGenres.contains).length;
    final overlapFactor = selectedGenres.isEmpty
        ? 0.0
        : overlap / selectedGenres.length;
    final score = (item.rating * 0.75) + (overlapFactor * 2.5);
    return score.clamp(0.0, 10.0);
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
                'Content Comparison',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                '1) Tap 2-3 cards below. 2) Comparison Matrix appears automatically.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TypeFilter(activeType: _activeType, onSelected: _setType),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ComparisonHeader(
                selectedCount: _selected.length,
                onClear: _selected.isEmpty
                    ? null
                    : () => setState(() => _selected.clear()),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          if (_selected.length >= 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ComparisonTable(
                  selected: _selected,
                  releaseYear: _releaseYear,
                  relevanceScore: _relevanceScore,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: _items.length,
                  (context, index) {
                    final item = _items[index];
                    final selectedIndex = _selected.indexWhere(
                      (selected) => _contentKey(selected) == _contentKey(item),
                    );
                    return _CandidateCard(
                      item: item,
                      selectedIndex: selectedIndex,
                      disabled: selectedIndex < 0 && _selected.length >= 3,
                      onTap: () => _toggleSelection(item),
                    );
                  },
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _TypeFilter extends StatelessWidget {
  final String activeType;
  final ValueChanged<String> onSelected;

  const _TypeFilter({required this.activeType, required this.onSelected});

  @override
  Widget build(BuildContext context) {
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
          final selected = value == activeType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFF16213A),
                  borderRadius: BorderRadius.circular(999),
                ),
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
}

class _ComparisonHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onClear;

  const _ComparisonHeader({required this.selectedCount, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.chart_bar_alt_fill, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedCount < 2
                  ? 'Choose at least 2 cards. Matrix will appear right here.'
                  : 'Matrix is ready (${selectedCount.toString()} selected). Tap a selected card to remove it.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (onClear != null)
            TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final List<UnifiedContent> selected;
  final int? Function(UnifiedContent) releaseYear;
  final double Function(UnifiedContent) relevanceScore;

  const _ComparisonTable({
    required this.selected,
    required this.releaseYear,
    required this.relevanceScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparison Matrix',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...selected.map((item) {
            final genres = item.genres.take(3).join(', ');
            final year = releaseYear(item);
            final relevance = relevanceScore(item).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rating ${item.rating.toStringAsFixed(1)} • Relevance $relevance • Year ${year?.toString() ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      genres.isEmpty ? 'Genres: -' : 'Genres: $genres',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final UnifiedContent item;
  final int selectedIndex;
  final bool disabled;
  final VoidCallback onTap;

  const _CandidateCard({
    required this.item,
    required this.selectedIndex,
    required this.disabled,
    required this.onTap,
  });

  IconData _iconByType(String type) {
    switch (type) {
      case 'movie':
        return CupertinoIcons.film;
      case 'book':
        return CupertinoIcons.book_fill;
      default:
        return CupertinoIcons.music_note_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex >= 0;
    final imageUrl = (item.imageUrl ?? '').trim();
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16213A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF5AA9FF) : Colors.white10,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stackTrace) {
                                return _buildImageFallback();
                              },
                            )
                          : _buildImageFallback(),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5AA9FF)
                                : Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            isSelected ? '${selectedIndex + 1}' : '+',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.type.toUpperCase()} • ${item.rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: Icon(_iconByType(item.type), color: Colors.white24, size: 34),
    );
  }
}
