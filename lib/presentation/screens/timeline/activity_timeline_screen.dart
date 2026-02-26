import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/interaction_event.dart';
import '../../../domain/repositories/analytics_repository.dart';

class ActivityTimelineScreen extends StatefulWidget {
  const ActivityTimelineScreen({super.key});

  @override
  State<ActivityTimelineScreen> createState() => _ActivityTimelineScreenState();
}

class _ActivityTimelineScreenState extends State<ActivityTimelineScreen> {
  bool _loading = true;
  String _error = '';
  List<InteractionEvent> _events = const [];

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
      final repo = context.read<AnalyticsRepository>();
      final events = await repo.getTimeline(limit: 120);
      if (!mounted) return;
      setState(() => _events = events);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load timeline');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'open_detail':
        return CupertinoIcons.doc_text_search;
      case 'dwell_time':
        return CupertinoIcons.timer;
      case 'search':
        return CupertinoIcons.search;
      case 'like':
        return CupertinoIcons.heart_fill;
      case 'playlist_add':
        return CupertinoIcons.add_circled_solid;
      default:
        return CupertinoIcons.circle_fill;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'like':
        return Colors.redAccent;
      case 'playlist_add':
        return Colors.greenAccent;
      case 'search':
        return const Color(0xFF5AA9FF);
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 56)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Activity Timeline',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Event stream: views, opens, dwell time, likes',
                style: TextStyle(color: Colors.white54, fontSize: 14),
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
          else if (_events.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No activity yet',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final event = _events[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: _colorForType(event.type).withOpacity(0.2),
                    child: Icon(
                      _iconForType(event.type),
                      color: _colorForType(event.type),
                      size: 19,
                    ),
                  ),
                  title: Text(event.title ?? event.type),
                  subtitle: Text(
                    '${event.type} • ${event.createdAt.toLocal()}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: Text(
                    event.weight.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white54),
                  ),
                );
              }, childCount: _events.length),
            ),
        ],
      ),
    );
  }
}
