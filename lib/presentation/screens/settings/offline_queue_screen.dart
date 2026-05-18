import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/analytics_repository.dart';
import '../../widgets/app_screen_chrome.dart';

class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen> {
  bool _loading = true;
  List<String> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<AnalyticsRepository>().getOfflineQueue();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    await context.read<AnalyticsRepository>().clearOfflineQueue();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          OmniHeaderSliver(
            title: 'Offline Queue',
            subtitle: 'Pending analytics events waiting for network',
            trailing: OmniIconButton(
              icon: CupertinoIcons.delete,
              color: _items.isEmpty
                  ? AppTheme.ink.withValues(alpha: 0.28)
                  : const Color(0xFFFF5D73),
              onTap: _items.isEmpty ? () {} : _clear,
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Queue is empty',
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
                  return OmniCard(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.ink.withValues(alpha: 0.68),
                        height: 1.35,
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: _items.length,
              ),
            ),
        ],
      ),
    );
  }
}
