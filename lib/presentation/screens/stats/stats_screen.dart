import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/usage_stats.dart';
import '../../../domain/repositories/analytics_repository.dart';
import '../../widgets/app_screen_chrome.dart';

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
      backgroundColor: AppTheme.appBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const OmniHeaderSliver(
            title: 'Stats',
            subtitle: 'CTR, save-rate and interaction health',
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                children: [7, 30, 90].map((days) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OmniPill(
                      label: '$days d',
                      selected: _days == days,
                      onTap: () {
                        if (_days == days) return;
                        setState(() => _days = days);
                        _load();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
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
                  style: const TextStyle(color: Color(0xFFFF5D73)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: OmniMetricTile(
                          title: 'Events',
                          value: '${stats.totalEvents}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OmniMetricTile(
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
                        child: OmniMetricTile(
                          title: 'Save Rate',
                          value:
                              '${(stats.saveRate * 100).toStringAsFixed(1)}%',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OmniMetricTile(
                          title: 'Avg Dwell',
                          value: '${stats.avgDwellSeconds.toStringAsFixed(1)}s',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                ]),
              ),
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

    return OmniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              'No data yet',
              style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.52)),
            )
          else
            ...entries.map((entry) {
              final maxValue = entries.first.value == 0
                  ? 1
                  : entries.first.value;
              final ratio = entry.value / maxValue;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text('${entry.value}'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 4,
                        backgroundColor: AppTheme.ink.withValues(alpha: 0.08),
                        color: AppTheme.primary,
                      ),
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

class _AbMetricsCard extends StatelessWidget {
  final Map<String, Map<String, double>> metrics;

  const _AbMetricsCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final entries = metrics.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return OmniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A/B Ranking Metrics',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
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
                    'CTR ${ctr.toStringAsFixed(1)}%  Save ${saveRate.toStringAsFixed(1)}%  $events ev',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.ink.withValues(alpha: 0.62),
                    ),
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
