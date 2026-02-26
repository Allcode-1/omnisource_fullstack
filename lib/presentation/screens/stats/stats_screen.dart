import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/usage_stats.dart';
import '../../../domain/repositories/analytics_repository.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  String _error = '';
  UsageStats? _stats;
  int _days = 30;

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
      final stats = await context.read<AnalyticsRepository>().getStats(
        days: _days,
      );
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load stats');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 56)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Stats',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'CTR, save-rate and interaction health',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [7, 30, 90].map((days) {
                  final selected = _days == days;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (_days == days) return;
                        setState(() => _days = days);
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF16213A),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$days d',
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_error.isNotEmpty || stats == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _error.isEmpty ? 'No stats available' : _error,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Events',
                            value: '${stats.totalEvents}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            title: 'CTR',
                            value: '${(stats.ctr * 100).toStringAsFixed(1)}%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Save Rate',
                            value:
                                '${(stats.saveRate * 100).toStringAsFixed(1)}%',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            title: 'Avg Dwell',
                            value:
                                '${stats.avgDwellSeconds.toStringAsFixed(1)}s',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _BreakdownCard(
                      title: 'Event Breakdown',
                      items: stats.countsByType,
                    ),
                    const SizedBox(height: 10),
                    _BreakdownCard(
                      title: 'Top Content Types',
                      items: stats.topContentTypes,
                    ),
                    if (stats.abMetrics.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _AbMetricsCard(metrics: stats.abMetrics),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final Map<String, int> items;

  const _BreakdownCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final entries = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text('No data yet', style: TextStyle(color: Colors.white54))
          else
            ...entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value}'),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AbMetricsCard extends StatelessWidget {
  final Map<String, Map<String, double>> metrics;

  const _AbMetricsCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final entries = metrics.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A/B Ranking Metrics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...entries.map((entry) {
            final value = entry.value;
            final ctr = (value['ctr'] ?? 0.0) * 100;
            final saveRate = (value['save_rate'] ?? 0.0) * 100;
            final events = (value['events'] ?? 0.0).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key == 'hybrid_ml' ? 'Hybrid ML' : 'Content-only',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'CTR ${ctr.toStringAsFixed(1)}% • Save ${saveRate.toStringAsFixed(1)}% • $events ev',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
