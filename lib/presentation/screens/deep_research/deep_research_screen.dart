import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../profile/profile_screen.dart';
import '../search/search_grid_card.dart';

class DeepResearchScreen extends StatefulWidget {
  const DeepResearchScreen({super.key});

  @override
  State<DeepResearchScreen> createState() => _DeepResearchScreenState();
}

class _DeepResearchScreenState extends State<DeepResearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _tagSearchController = TextEditingController();

  List<String> _allTags = const [];
  List<String> _filteredTags = const [];
  final Set<String> _selectedTags = {};

  List<UnifiedContent> _results = const [];
  Timer? _researchDebounce;
  int _researchRequestToken = 0;

  bool _isLoadingTags = true;
  bool _isLoadingResults = false;
  String _error = '';
  String _activeType = 'all';
  double _appBarOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final next = (1.0 - (_scrollController.offset / 80)).clamp(0.0, 1.0);
      if (next != _appBarOpacity) {
        setState(() => _appBarOpacity = next);
      }
    });
    _loadTags();
  }

  @override
  void dispose() {
    _researchDebounce?.cancel();
    _scrollController.dispose();
    _tagSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoadingTags = true;
      _error = '';
    });

    try {
      final tags = await context.read<AuthRepository>().getAvailableTags();
      final sorted = [...tags]..sort((a, b) => a.compareTo(b));

      if (!mounted) return;
      setState(() {
        _allTags = sorted;
        _filteredTags = sorted;
      });

      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated &&
          authState.user.interests.isNotEmpty) {
        _selectedTags.addAll(authState.user.interests.take(3));
        _scheduleDeepResearch();
      }
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

  void _onTagQueryChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _filteredTags = query.isEmpty
          ? _allTags
          : _allTags.where((tag) => tag.toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _runDeepResearch() async {
    if (_selectedTags.isEmpty) {
      _researchRequestToken++;
      setState(() {
        _results = const [];
        _error = '';
        _isLoadingResults = false;
      });
      return;
    }

    final requestToken = ++_researchRequestToken;
    final selectedTags = _selectedTags.toList(growable: false);
    final selectedType = _activeType;

    setState(() {
      _isLoadingResults = true;
      _error = '';
    });

    try {
      final repository = context.read<ContentRepository>();
      final type = selectedType == 'all' ? null : selectedType;

      final responses = await Future.wait(
        selectedTags.map((tag) async {
          try {
            return await repository.getDeepResearch(tag, type: type);
          } catch (e, st) {
            AppLogger.error(
              'Deep research tag request failed: $tag',
              error: e,
              stackTrace: st,
              name: 'DeepResearchScreen',
            );
            return <UnifiedContent>[];
          }
        }),
      );

      final merged = <String, UnifiedContent>{};
      final scoreById = <String, int>{};

      for (final list in responses) {
        for (final item in list) {
          final id = _contentKey(item);
          if (id.isEmpty) continue;

          merged.putIfAbsent(id, () => item);
          scoreById[id] = (scoreById[id] ?? 0) + 1;
        }
      }

      final items = merged.values.toList();
      items.sort((a, b) {
        final scoreA = scoreById[_contentKey(a)] ?? 0;
        final scoreB = scoreById[_contentKey(b)] ?? 0;
        if (scoreA != scoreB) return scoreB.compareTo(scoreA);
        return b.rating.compareTo(a.rating);
      });

      if (!mounted || requestToken != _researchRequestToken) return;
      setState(() => _results = items);
    } catch (e, st) {
      AppLogger.error(
        'Deep research request failed',
        error: e,
        stackTrace: st,
        name: 'DeepResearchScreen',
      );
      if (!mounted || requestToken != _researchRequestToken) return;
      setState(() => _error = 'Failed to run deep research');
    } finally {
      if (mounted && requestToken == _researchRequestToken) {
        setState(() => _isLoadingResults = false);
      }
    }
  }

  String _contentKey(UnifiedContent item) => '${item.type}:${item.externalId}';

  void _scheduleDeepResearch() {
    _researchDebounce?.cancel();
    _researchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        _runDeepResearch();
      }
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _scheduleDeepResearch();
  }

  void _setType(String type) {
    if (_activeType == type) return;
    setState(() => _activeType = type);
    _scheduleDeepResearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 2, 20, 0),
                  child: Text(
                    'Pick one or more tags and explore a focused feed',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTypeFilters(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSelectedTags(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTagCloud(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              if (_isLoadingResults)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (_error.isNotEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      _error,
                      style: const TextStyle(color: Color(0xFFFF7A7A)),
                    ),
                  ),
                )
              else if (_selectedTags.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Select tags to start discovering',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                )
              else if (_results.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No results for selected tags',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: _appBarOpacity,
              child: _buildAppBar(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final username = authState is AuthAuthenticated
            ? authState.user.username
            : "U";
        final safeLetter = username.trim().isNotEmpty
            ? username.trim().substring(0, 1).toUpperCase()
            : "U";

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 54, 20, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Text(
                "Discover",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final userRepository = context.read<UserRepository>();
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) =>
                          ProfileScreen(userRepository: userRepository),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                  child: Text(
                    safeLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CupertinoSearchTextField(
        controller: _tagSearchController,
        backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
        itemColor: Colors.white70,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        placeholderStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        placeholder: 'Search tags',
        onChanged: _onTagQueryChanged,
        onSuffixTap: () {
          _tagSearchController.clear();
          _onTagQueryChanged('');
        },
      ),
    );
  }

  Widget _buildTypeFilters() {
    final filters = const [
      ('All', 'all'),
      ('Movies', 'movie'),
      ('Music', 'music'),
      ('Books', 'book'),
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final label = filters[index].$1;
          final value = filters[index].$2;
          final selected = value == _activeType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _setType(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF5AA9FF)
                      : Theme.of(context).cardColor.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedTags() {
    if (_selectedTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _toggleTag(tag),
                child: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagCloud() {
    if (_isLoadingTags) {
      return const SizedBox(
        height: 56,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_filteredTags.isEmpty) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: Text(
            'No matching tags',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _filteredTags.map((tag) {
        final selected = _selectedTags.contains(tag);
        return GestureDetector(
          onTap: () => _toggleTag(tag),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF5AA9FF)
                  : Theme.of(context).cardColor.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? Colors.transparent : Colors.white12,
              ),
            ),
            child: Text(tag, style: const TextStyle(color: Colors.white)),
          ),
        );
      }).toList(),
    );
  }
}
