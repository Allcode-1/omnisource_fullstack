import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/analytics_repository.dart';
import '../../widgets/app_screen_chrome.dart';

class DebugPanelScreen extends StatefulWidget {
  const DebugPanelScreen({super.key});

  @override
  State<DebugPanelScreen> createState() => _DebugPanelScreenState();
}

class _DebugPanelScreenState extends State<DebugPanelScreen> {
  bool _loading = true;
  String _variant = 'hybrid_ml';
  String _health = 'unknown';
  String _vectorMode = 'unknown';
  String _catalog = 'unknown';
  String _cache = 'unknown';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = context.read<AnalyticsRepository>();
    final variant = await repo.getRankingVariant();
    var health = 'unknown';
    var vectorMode = 'unknown';
    var catalog = 'unknown';
    var cache = 'unknown';

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final response = await dio.get('/diagnostics');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        health = data['redis']?.toString() ?? 'unknown';
        final ml = (data['ml'] as Map?)?.cast<String, dynamic>() ?? {};
        final catalogMap =
            (data['catalog'] as Map?)?.cast<String, dynamic>() ?? {};
        final cacheMap = (data['cache'] as Map?)?.cast<String, dynamic>() ?? {};
        final indexEnabled = ml['vector_index_enabled'] == true;
        final backend = ml['vector_backend'] ?? 'hash';
        vectorMode =
            '${indexEnabled ? 'Vector index' : 'Mongo scan'}  -  $backend  -  x${ml['vector_search_multiplier'] ?? '-'}';
        catalog =
            '${catalogMap['vectorized_documents'] ?? 0}/${catalogMap['total_documents'] ?? 0} vectorized  -  ${(catalogMap['vector_coverage'] ?? 0).toString()}';
        cache =
            'tags ${cacheMap['warmup_tag_limit'] ?? '-'}  -  users ${cacheMap['warmup_user_limit'] ?? '-'}';
      }
    } catch (_) {
      health = 'unreachable';
    }

    if (!mounted) return;
    setState(() {
      _variant = variant;
      _health = health;
      _vectorMode = vectorMode;
      _catalog = catalog;
      _cache = cache;
      _loading = false;
    });
  }

  Future<void> _setVariant(String value) async {
    final repo = context.read<AnalyticsRepository>();
    final updated = await repo.setRankingVariant(value);
    if (!mounted) return;
    setState(() => _variant = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          OmniHeaderSliver(
            title: 'Debug',
            subtitle: 'A/B mode and backend diagnostics',
            trailing: OmniIconButton(
              icon: CupertinoIcons.refresh,
              onTap: _load,
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  OmniCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'A/B Variant',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _variant,
                          style: TextStyle(
                            color: AppTheme.ink.withValues(alpha: 0.62),
                          ),
                        ),
                        const SizedBox(height: 14),
                        CupertinoSlidingSegmentedControl<String>(
                          groupValue: _variant,
                          thumbColor: AppTheme.ink.withValues(alpha: 0.18),
                          backgroundColor: Colors.black.withValues(alpha: 0.28),
                          children: const {
                            'content_only': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Content'),
                            ),
                            'hybrid_ml': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Hybrid'),
                            ),
                          },
                          onValueChanged: (value) {
                            if (value != null) _setVariant(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(title: 'Backend Health', value: 'Redis: $_health'),
                  const SizedBox(height: 10),
                  _InfoCard(title: 'ML Mode', value: _vectorMode),
                  const SizedBox(height: 10),
                  _InfoCard(title: 'Catalog Coverage', value: _catalog),
                  const SizedBox(height: 10),
                  _InfoCard(title: 'Cache Warmup', value: _cache),
                  const SizedBox(height: 10),
                  _InfoCard(title: 'API Base URL', value: ApiConstants.baseUrl),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return OmniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.62)),
          ),
        ],
      ),
    );
  }
}
