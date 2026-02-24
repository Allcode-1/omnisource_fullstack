import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/content_repository.dart';
import '../search/search_grid_card.dart';

class DeepResearchScreen extends StatefulWidget {
  const DeepResearchScreen({super.key});

  @override
  State<DeepResearchScreen> createState() => _DeepResearchScreenState();
}

class _DeepResearchScreenState extends State<DeepResearchScreen> {
  List<String> _tags = const [];
  List<UnifiedContent> _results = const [];
  bool _isLoadingTags = true;
  bool _isLoadingResults = false;
  String _selectedTag = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoadingTags = true;
      _error = '';
    });

    try {
      final tags = await context.read<AuthRepository>().getAvailableTags();
      if (!mounted) return;
      setState(() => _tags = tags);
    } catch (e, st) {
      AppLogger.error(
        'Failed to load research tags',
        error: e,
        stackTrace: st,
        name: 'DeepResearchScreen',
      );
      if (!mounted) return;
      setState(() => _error = 'Failed to load tags');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTags = false);
      }
    }
  }

  Future<void> _runDeepResearch(String tag) async {
    setState(() {
      _selectedTag = tag;
      _isLoadingResults = true;
      _error = '';
    });

    try {
      final data = await context.read<ContentRepository>().getDeepResearch(tag);
      if (!mounted) return;
      setState(() => _results = data);
    } catch (e, st) {
      AppLogger.error(
        'Deep research request failed',
        error: e,
        stackTrace: st,
        name: 'DeepResearchScreen',
      );
      if (!mounted) return;
      setState(() => _error = 'Failed to run deep research');
    } finally {
      if (mounted) {
        setState(() => _isLoadingResults = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 62)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Deep Research',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Pick an interest and get a focused feed',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTagCloud(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (_isLoadingResults)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            )
          else if (_selectedTag.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Select a tag to start',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
          else if (_results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No focused results for "$_selectedTag"',
                  style: const TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.63,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SearchGridCard(item: _results[index]),
                  childCount: _results.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildTagCloud() {
    if (_isLoadingTags) {
      return const SizedBox(
        height: 50,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_tags.isEmpty) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: Text(
            'No tags available',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _tags.map((tag) {
        final isSelected = _selectedTag == tag;
        return GestureDetector(
          onTap: () => _runDeepResearch(tag),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0984E3)
                  : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white12,
              ),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
