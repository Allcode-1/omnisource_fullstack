import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../calendar/release_calendar_screen.dart';
import '../comparison/content_comparison_screen.dart';
import '../deep_research/deep_research_screen.dart';
import '../library/playlist_editor_screen.dart';
import '../library/smart_library_screen.dart';
import '../mood/mood_picker_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/debug_panel_screen.dart';
import '../settings/offline_queue_screen.dart';
import '../settings/settings_screen.dart';
import '../timeline/activity_timeline_screen.dart';
import '../trending/trending_hub_screen.dart';
import '../collections/collections_screen.dart';
import '../home/for_you_hub_screen.dart';
import '../stats/stats_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_DashboardItem>[
      _DashboardItem(
        title: 'For You Hub',
        subtitle: 'Personalized feed and insights',
        icon: CupertinoIcons.sparkles,
        builder: (_) => const ForYouHubScreen(),
      ),
      _DashboardItem(
        title: 'Trending Hub',
        subtitle: 'Movies, music and books trends',
        icon: CupertinoIcons.flame_fill,
        builder: (_) => const TrendingHubScreen(),
      ),
      _DashboardItem(
        title: 'Collections',
        subtitle: 'Curated theme collections',
        icon: CupertinoIcons.square_stack_3d_up_fill,
        builder: (_) => const CollectionsScreen(),
      ),
      _DashboardItem(
        title: 'Deep Research',
        subtitle: 'Tag-based exploration',
        icon: CupertinoIcons.compass_fill,
        builder: (_) => const DeepResearchScreen(),
      ),
      _DashboardItem(
        title: 'Mood Picker',
        subtitle: 'Mood to curated content feed',
        icon: CupertinoIcons.layers_alt_fill,
        builder: (_) => const MoodPickerScreen(),
      ),
      _DashboardItem(
        title: 'Release Calendar',
        subtitle: 'Timeline of releases by type',
        icon: CupertinoIcons.calendar_today,
        builder: (_) => const ReleaseCalendarScreen(),
      ),
      _DashboardItem(
        title: 'Content Comparison',
        subtitle: 'Compare 2-3 titles side by side',
        icon: CupertinoIcons.rectangle_split_3x1_fill,
        builder: (_) => const ContentComparisonScreen(),
      ),
      _DashboardItem(
        title: 'Smart Library',
        subtitle: 'Library analytics and shortcuts',
        icon: CupertinoIcons.music_note_list,
        builder: (_) => const SmartLibraryScreen(),
      ),
      _DashboardItem(
        title: 'Playlist Editor',
        subtitle: 'Create, update and delete playlists',
        icon: CupertinoIcons.square_pencil,
        builder: (_) => const PlaylistEditorScreen(),
      ),
      _DashboardItem(
        title: 'Activity Timeline',
        subtitle: 'Recent events and behavior',
        icon: CupertinoIcons.time_solid,
        builder: (_) => const ActivityTimelineScreen(),
      ),
      _DashboardItem(
        title: 'Stats',
        subtitle: 'CTR, save-rate and dwell time',
        icon: CupertinoIcons.chart_bar_alt_fill,
        builder: (_) => const StatsScreen(),
      ),
      _DashboardItem(
        title: 'Notifications',
        subtitle: 'In-app recommendations alerts',
        icon: CupertinoIcons.bell_fill,
        builder: (_) => const NotificationsScreen(),
      ),
      _DashboardItem(
        title: 'Settings',
        subtitle: 'Preferences and switches',
        icon: CupertinoIcons.settings_solid,
        builder: (_) => const SettingsScreen(),
      ),
      _DashboardItem(
        title: 'Debug Panel',
        subtitle: 'A/B mode and diagnostics',
        icon: CupertinoIcons.ant_circle_fill,
        builder: (_) => const DebugPanelScreen(),
      ),
      _DashboardItem(
        title: 'Offline Queue',
        subtitle: 'Pending tracked events',
        icon: CupertinoIcons.cloud_download_fill,
        builder: (_) => const OfflineQueueScreen(),
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 62)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Omni Dashboard',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Launch advanced features and screens',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.98,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: items.length,
                (context, index) => _DashboardTile(item: items[index]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;

  _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}

class _DashboardTile extends StatelessWidget {
  final _DashboardItem item;
  const _DashboardTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, CupertinoPageRoute(builder: item.builder));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF16213A).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF5AA9FF).withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
