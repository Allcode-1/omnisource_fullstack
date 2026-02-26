import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/analytics_repository.dart';
import '../notifications/notifications_screen.dart';
import '../stats/stats_screen.dart';
import '../timeline/activity_timeline_screen.dart';
import 'debug_panel_screen.dart';
import 'offline_queue_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _variant = 'hybrid_ml';

  @override
  void initState() {
    super.initState();
    _loadVariant();
  }

  Future<void> _loadVariant() async {
    final variant = await context
        .read<AnalyticsRepository>()
        .getRankingVariant();
    if (!mounted) return;
    setState(() => _variant = variant);
  }

  Future<void> _toggleVariant(bool isHybrid) async {
    final next = isHybrid ? 'hybrid_ml' : 'content_only';
    final updated = await context.read<AnalyticsRepository>().setRankingVariant(
      next,
    );
    if (!mounted) return;
    setState(() => _variant = updated);
  }

  void _push(Widget page) {
    Navigator.push(context, CupertinoPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isHybrid = _variant == 'hybrid_ml';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ranking Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Switch between content-only and hybrid ML',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(value: isHybrid, onChanged: _toggleVariant),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: CupertinoIcons.bell_fill,
            title: 'Notifications',
            onTap: () => _push(const NotificationsScreen()),
          ),
          _NavTile(
            icon: CupertinoIcons.chart_bar_alt_fill,
            title: 'Stats',
            onTap: () => _push(const StatsScreen()),
          ),
          _NavTile(
            icon: CupertinoIcons.time_solid,
            title: 'Activity Timeline',
            onTap: () => _push(const ActivityTimelineScreen()),
          ),
          _NavTile(
            icon: CupertinoIcons.ant_circle_fill,
            title: 'Debug Panel',
            onTap: () => _push(const DebugPanelScreen()),
          ),
          _NavTile(
            icon: CupertinoIcons.cloud_download_fill,
            title: 'Offline Queue',
            onTap: () => _push(const OfflineQueueScreen()),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(CupertinoIcons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
