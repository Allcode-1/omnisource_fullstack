import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_constants.dart';
import '../../../domain/repositories/analytics_repository.dart';

class DebugPanelScreen extends StatefulWidget {
  const DebugPanelScreen({super.key});

  @override
  State<DebugPanelScreen> createState() => _DebugPanelScreenState();
}

class _DebugPanelScreenState extends State<DebugPanelScreen> {
  bool _loading = true;
  String _variant = 'hybrid_ml';
  String _health = 'unknown';

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

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final response = await dio.get('/health');
      final data = response.data;
      health = data is Map<String, dynamic>
          ? (data['redis']?.toString() ?? 'unknown')
          : 'unknown';
    } catch (_) {
      health = 'unreachable';
    }

    if (!mounted) return;
    setState(() {
      _variant = variant;
      _health = health;
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
      appBar: AppBar(title: const Text('Debug Panel')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TileCard(
                  title: 'A/B Variant',
                  subtitle: _variant,
                  trailing: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _variant,
                    children: const {
                      'content_only': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('Content'),
                      ),
                      'hybrid_ml': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('Hybrid'),
                      ),
                    },
                    onValueChanged: (value) {
                      if (value != null) _setVariant(value);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _TileCard(title: 'Backend Health', subtitle: 'Redis: $_health'),
                const SizedBox(height: 10),
                _TileCard(
                  title: 'API Base URL',
                  subtitle: ApiConstants.baseUrl,
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(CupertinoIcons.refresh),
                  label: const Text('Refresh Diagnostics'),
                ),
              ],
            ),
    );
  }
}

class _TileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _TileCard({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
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
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          if (trailing != null) ...[const SizedBox(height: 12), trailing!],
        ],
      ),
    );
  }
}
