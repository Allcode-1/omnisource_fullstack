import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/content_repository.dart';

class ReleaseCalendarScreen extends StatefulWidget {
  const ReleaseCalendarScreen({super.key});

  @override
  State<ReleaseCalendarScreen> createState() => _ReleaseCalendarScreenState();
}

class _ReleaseCalendarScreenState extends State<ReleaseCalendarScreen> {
  bool _loading = true;
  String _error = '';
  String _activeType = 'all';
  bool _showUpcomingOnly = false;
  List<_ReleaseEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime? _parseReleaseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    if (value.length == 4) {
      final year = int.tryParse(value);
      if (year == null) return null;
      return DateTime(year, 1, 1);
    }
    if (value.length == 7 && value.contains('-')) {
      final parts = value.split('-');
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year == null || month == null) return null;
      return DateTime(year, month, 1);
    }
    return DateTime.tryParse(value);
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
        repo.getHomeData(type: type),
      ]);

      final merged = <String, UnifiedContent>{};
      for (final item in responses[0] as List<UnifiedContent>) {
        merged[item.externalId] = item;
      }
      for (final item in responses[1] as List<UnifiedContent>) {
        merged[item.externalId] = item;
      }
      final homeMap = responses[2] as Map<String, List<UnifiedContent>>;
      for (final sectionItems in homeMap.values) {
        for (final item in sectionItems) {
          merged[item.externalId] = item;
        }
      }

      final now = DateTime.now();
      final result = <_ReleaseEntry>[];
      for (final item in merged.values) {
        final releaseDate = _parseReleaseDate(item.releaseDate);
        if (releaseDate == null) continue;
        if (_showUpcomingOnly && releaseDate.isBefore(now)) continue;
        result.add(_ReleaseEntry(item: item, releaseDate: releaseDate));
      }

      result.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

      if (!mounted) return;
      setState(() => _entries = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to build release calendar');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setType(String type) {
    if (_activeType == type) return;
    setState(() => _activeType = type);
    _load();
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<_ReleaseEntry>>{};
    for (final entry in _entries) {
      final key = _monthLabel(entry.releaseDate);
      grouped.putIfAbsent(key, () => <_ReleaseEntry>[]).add(entry);
    }
    final sections = grouped.entries.toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 56)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Release Calendar',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Timeline of releases with type filtering',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CalendarFilters(
                activeType: _activeType,
                upcomingOnly: _showUpcomingOnly,
                onTypeSelected: _setType,
                onUpcomingChanged: (value) {
                  setState(() => _showUpcomingOnly = value);
                  _load();
                },
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
          else if (sections.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No releases for selected filters',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final section = sections[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.key,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...section.value.map((entry) {
                        final date = entry.releaseDate;
                        final content = entry.item;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      content.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${content.type.toUpperCase()} • ${content.rating.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }, childCount: sections.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _CalendarFilters extends StatelessWidget {
  final String activeType;
  final bool upcomingOnly;
  final ValueChanged<String> onTypeSelected;
  final ValueChanged<bool> onUpcomingChanged;

  const _CalendarFilters({
    required this.activeType,
    required this.upcomingOnly,
    required this.onTypeSelected,
    required this.onUpcomingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = const [
      ('All', 'all'),
      ('Movies', 'movie'),
      ('Music', 'music'),
      ('Books', 'book'),
    ];
    return Column(
      children: [
        SizedBox(
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
                  onTap: () => onTypeSelected(value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : const Color(0xFF1C1C1E),
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
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Show upcoming only',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              CupertinoSwitch(
                value: upcomingOnly,
                onChanged: onUpcomingChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReleaseEntry {
  final UnifiedContent item;
  final DateTime releaseDate;

  const _ReleaseEntry({required this.item, required this.releaseDate});
}
