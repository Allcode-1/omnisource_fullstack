import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/content_repository.dart';
import '../search/search_grid_card.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  static const _collections = [
    ('Cyber Mood', ['cyberpunk', 'noir'], 'movie'),
    ('Late Night', ['chill', 'dark'], 'music'),
    ('Mind Benders', ['mystery', 'mind-bending'], 'all'),
    ('Epic Worlds', ['fantasy', 'epic'], 'book'),
  ];

  final Map<String, List<UnifiedContent>> _itemsByCollection = {};
  bool _loading = true;
  String _error = '';

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
      for (final collection in _collections) {
        final name = collection.$1;
        final tags = collection.$2;
        final type = collection.$3;
        final responses = await Future.wait(
          tags.map(
            (tag) =>
                repo.getDeepResearch(tag, type: type == 'all' ? null : type),
          ),
        );

        final map = <String, UnifiedContent>{};
        for (final list in responses) {
          for (final item in list) {
            map[_contentKey(item)] = item;
          }
        }
        _itemsByCollection[name] = map.values.take(8).toList();
      }
    } catch (_) {
      _error = 'Failed to load collections';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 58)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Collections',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Curated sets across moods and genres',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
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
                  style: const TextStyle(color: Color(0xFFFF7A7A)),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                ..._collections.map((entry) {
                  final name = entry.$1;
                  final tags = entry.$2;
                  final items =
                      _itemsByCollection[name] ?? const <UnifiedContent>[];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).cardColor.withValues(alpha: 0.84),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return SizedBox(
                                width: 170,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SearchGridCard(item: item),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 100),
              ]),
            ),
        ],
      ),
    );
  }
}
