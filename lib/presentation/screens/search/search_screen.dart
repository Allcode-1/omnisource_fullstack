import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';

import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/library/library_cubit.dart';
import '../../bloc/library/library_state.dart';
import '../../bloc/search/search_cubit.dart';
import '../../bloc/search/search_state.dart';
import '../calendar/release_calendar_screen.dart';
import '../comparison/content_comparison_screen.dart';
import '../mood/mood_picker_screen.dart';
import '../profile/profile_screen.dart';
import 'search_grid_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  double _appBarOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    context.read<LibraryCubit>().loadLibraryData();

    _scrollController.addListener(() {
      final newOpacity = (1.0 - (_scrollController.offset / 80)).clamp(
        0.0,
        1.0,
      );
      if (newOpacity != _appBarOpacity) {
        setState(() => _appBarOpacity = newOpacity);
      }
    });

    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          final libraryState = context.watch<LibraryCubit>().state;
          final likedIds = libraryState is LibraryLoaded
              ? libraryState.favorites.map((item) => item.externalId).toSet()
              : <String>{};
          final filtered = _applyAdvancedFilters(
            state.results,
            state,
            likedIds,
          );

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSearchBar(context),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildTopActions(context, state),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFeatureShortcuts(context),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFilters(context, state.activeType),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  if (_searchController.text.isEmpty &&
                      state.recentQueries.isNotEmpty)
                    _buildSearchHistory(context, state),

                  if (state.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CupertinoActivityIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  else if (state.errorMessage.isNotEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          state.errorMessage,
                          style: const TextStyle(color: Color(0xFFFF7A7A)),
                        ),
                      ),
                    )
                  else if (filtered.isEmpty)
                    _buildEmptyState(_searchController.text.isEmpty)
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 18,
                              childAspectRatio: 0.63,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              SearchGridCard(item: filtered[index]),
                          childCount: filtered.length,
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
          );
        },
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
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 10),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Search",
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 30),
              ),
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
                  backgroundColor: const Color(0xFF1E2A47),
                  child: Text(
                    safeLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  Widget _buildTopActions(BuildContext context, SearchState state) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showAdvancedFilters(context, state),
            icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 18),
            label: const Text('Advanced Filters'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Save query',
          onPressed: () async {
            await context.read<SearchCubit>().saveCurrentQuery(
              _searchController.text.trim(),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Search query saved')));
          },
          icon: const Icon(CupertinoIcons.bookmark_fill),
        ),
      ],
    );
  }

  Widget _buildFeatureShortcuts(BuildContext context) {
    final items = <({String label, IconData icon, Widget page})>[
      (
        label: 'Mood Picker',
        icon: CupertinoIcons.layers_alt_fill,
        page: const MoodPickerScreen(),
      ),
      (
        label: 'Release Calendar',
        icon: CupertinoIcons.calendar_today,
        page: const ReleaseCalendarScreen(),
      ),
      (
        label: 'Comparison',
        icon: CupertinoIcons.rectangle_split_3x1_fill,
        page: const ContentComparisonScreen(),
      ),
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => item.page),
                );
              },
              icon: Icon(item.icon, size: 16),
              label: Text(item.label),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 52,
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNode.hasFocus
              ? AppTheme.primary
              : Colors.white.withValues(alpha: 0.08),
          width: 1.4,
        ),
        boxShadow: [
          if (_focusNode.hasFocus)
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: CupertinoSearchTextField(
        controller: _searchController,
        focusNode: _focusNode,
        backgroundColor: theme.cardColor.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
        itemColor: Colors.white70,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        placeholderStyle: const TextStyle(color: Colors.white54, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: const Icon(
          CupertinoIcons.search,
          color: Colors.white54,
          size: 18,
        ),
        suffixIcon: const Icon(
          CupertinoIcons.xmark_circle_fill,
          color: Colors.white30,
          size: 16,
        ),
        placeholder: "Artists, movies, books",
        onSuffixTap: () {
          _searchController.clear();
          context.read<SearchCubit>().search('');
          setState(() {});
        },
        onChanged: (val) {
          context.read<SearchCubit>().search(val);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildFilters(BuildContext context, String activeType) {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Movies', 'value': 'movie'},
      {'label': 'Music', 'value': 'music'},
      {'label': 'Books', 'value': 'book'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = activeType == filters[index]['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => context.read<SearchCubit>().setFilter(
                filters[index]['value']!,
                _searchController.text,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5AA9FF)
                      : Theme.of(context).cardColor.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index]['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchHistory(BuildContext context, SearchState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.savedQueries.isNotEmpty) ...[
              const Text(
                'Saved Searches',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.savedQueries.map((query) {
                  return InputChip(
                    label: Text(query),
                    onPressed: () {
                      _searchController.text = query;
                      context.read<SearchCubit>().search(query);
                      setState(() {});
                    },
                    onDeleted: () =>
                        context.read<SearchCubit>().removeSavedQuery(query),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      context.read<SearchCubit>().clearRecentQueries(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...state.recentQueries.take(6).map((query) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(CupertinoIcons.time),
                title: Text(query),
                onTap: () {
                  _searchController.text = query;
                  context.read<SearchCubit>().search(query);
                  setState(() {});
                },
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  List<UnifiedContent> _applyAdvancedFilters(
    List<UnifiedContent> source,
    SearchState state,
    Set<String> likedIds,
  ) {
    return source.where((item) {
      if (item.rating < state.minRating) return false;
      if (state.onlyLiked && !likedIds.contains(item.externalId)) return false;

      final release = item.releaseDate;
      int? year;
      if (release != null && release.isNotEmpty) {
        final value = release.length >= 4 ? release.substring(0, 4) : release;
        year = int.tryParse(value);
      }

      if (state.fromYear != null && year != null && year < state.fromYear!) {
        return false;
      }
      if (state.toYear != null && year != null && year > state.toYear!) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _showAdvancedFilters(
    BuildContext context,
    SearchState state,
  ) async {
    double minRating = state.minRating;
    bool onlyLiked = state.onlyLiked;
    final fromController = TextEditingController(
      text: state.fromYear?.toString() ?? '',
    );
    final toController = TextEditingController(
      text: state.toYear?.toString() ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Advanced Search',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Text('Min rating: ${minRating.toStringAsFixed(1)}'),
                  Slider(
                    value: minRating,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    label: minRating.toStringAsFixed(1),
                    onChanged: (value) =>
                        setModalState(() => minRating = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fromController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'From year',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: toController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'To year',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: onlyLiked,
                    onChanged: (value) =>
                        setModalState(() => onlyLiked = value),
                    title: const Text('Only liked'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.read<SearchCubit>().setAdvancedFilters(
                              minRating: 0.0,
                              onlyLiked: false,
                              clearFromYear: true,
                              clearToYear: true,
                            );
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<SearchCubit>().setAdvancedFilters(
                              minRating: minRating,
                              onlyLiked: onlyLiked,
                              fromYear: int.tryParse(fromController.text),
                              toYear: int.tryParse(toController.text),
                            );
                            Navigator.pop(ctx);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isInitial) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text(
          isInitial
              ? "Find your next favorite"
              : "Nothing found for active filters",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
