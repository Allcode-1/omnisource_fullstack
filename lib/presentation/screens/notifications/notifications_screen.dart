import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/repositories/analytics_repository.dart';
import '../../widgets/app_screen_chrome.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String _error = '';
  List<AppNotification> _items = const [];

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
      final items = await context
          .read<AnalyticsRepository>()
          .getNotifications();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load notifications');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _colorForLevel(String level) {
    switch (level) {
      case 'success':
        return const Color(0xFF4ADE80);
      case 'warning':
        return const Color(0xFFFBBF24);
      case 'error':
        return const Color(0xFFFF5D73);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          OmniHeaderSliver(
            title: 'Notifications',
            subtitle: 'Product updates and recommendation tips',
            trailing: OmniIconButton(
              icon: CupertinoIcons.refresh,
              onTap: _load,
            ),
          ),
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
                  style: const TextStyle(color: Color(0xFFFF5D73)),
                ),
              ),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No notifications yet',
                  style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.42)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              sliver: SliverList.separated(
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final color = _colorForLevel(item.level);
                  return _NotificationRow(item: item, color: color);
                },
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 54,
                  color: AppTheme.ink.withValues(alpha: 0.08),
                ),
                itemCount: _items.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification item;
  final Color color;

  const _NotificationRow({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.bell_fill, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.68),
                    fontSize: 14,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.createdAt.month}/${item.createdAt.day}',
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.44),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
