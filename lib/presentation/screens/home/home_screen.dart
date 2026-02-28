import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/home_layout_prefs.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/home/home_cubit.dart';
import '../../bloc/library/library_cubit.dart';
import '../collections/collections_screen.dart';
import 'for_you_hub_screen.dart';
import 'home_layout_editor_screen.dart';
import '../profile/profile_screen.dart';
import '../trending/trending_hub_screen.dart';
import 'content_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 1.0;
  HomeLayoutConfig _layoutConfig = const HomeLayoutConfig.empty();

  @override
  void initState() {
    super.initState();
    context.read<LibraryCubit>().loadLibraryData();
    _loadLayoutConfig();
    _scrollController.addListener(() {
      double newOpacity = (1.0 - (_scrollController.offset / 100)).clamp(
        0.0,
        1.0,
      );
      if (newOpacity != _appBarOpacity) {
        setState(() => _appBarOpacity = newOpacity);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLayoutConfig() async {
    final config = await HomeLayoutPrefs.load();
    if (!mounted) return;
    setState(() => _layoutConfig = config);
  }

  Future<void> _openLayoutEditor(HomeState state) async {
    final sections = _availableSections(state);
    if (sections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Load home sections first')));
      return;
    }

    final result = await Navigator.push<HomeLayoutConfig>(
      context,
      CupertinoPageRoute(
        builder: (_) => HomeLayoutEditorScreen(
          availableSections: sections,
          initialConfig: _layoutConfig,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _layoutConfig = result);
    await HomeLayoutPrefs.save(result);
    AppLogger.info(
      'Home layout saved: sections=${result.orderedSections.length}',
      name: 'HomeScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CupertinoSlidingSegmentedControl<ContentCategory>(
                        groupValue: state.category,
                        backgroundColor: theme.cardColor.withValues(
                          alpha: 0.82,
                        ),
                        thumbColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.9),
                        children: const {
                          ContentCategory.music: Text(
                            "Music",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          ContentCategory.movie: Text(
                            "Movies",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          ContentCategory.book: Text(
                            "Books",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        },
                        onValueChanged: (val) {
                          if (val != null) {
                            context.read<HomeCubit>().setCategory(val);
                          }
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildHubShortcuts(context),
                    ),
                  ),
                  if (state.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CupertinoActivityIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  else if ((state.error ?? '').isNotEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.error ?? 'Failed to load content',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFFF7A7A)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () =>
                                  context.read<HomeCubit>().loadContent(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    SliverList(
                      delegate: SliverChildListDelegate([
                        ..._buildDynamicRows(state),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ],
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _appBarOpacity,
                  child: _buildAppBar(context, state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, HomeState state) {
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
                "OmniSource",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 22),
                onPressed: () => _openLayoutEditor(state),
                tooltip: 'Home layout editor',
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

  Widget _buildSection(String title, List<UnifiedContent> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 25, 16, 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => ContentCard(item: items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildHubShortcuts(BuildContext context) {
    final theme = Theme.of(context);
    final shortcuts = <({String title, IconData icon, Widget page})>[
      (
        title: 'For You Hub',
        icon: CupertinoIcons.sparkles,
        page: const ForYouHubScreen(),
      ),
      (
        title: 'Trending Hub',
        icon: CupertinoIcons.flame_fill,
        page: const TrendingHubScreen(),
      ),
      (
        title: 'Collections',
        icon: CupertinoIcons.square_stack_3d_up_fill,
        page: const CollectionsScreen(),
      ),
    ];

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shortcuts.length,
        itemBuilder: (context, index) {
          final item = shortcuts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: theme.colorScheme.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => item.page),
                );
              },
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildDynamicRows(HomeState state) {
    final sections = <MapEntry<String, List<UnifiedContent>>>[
      MapEntry("Trending Now", state.trending),
      MapEntry("For You", state.recommendations),
      ...state.homeMap.entries.where(
        (entry) => entry.key != "Trending Now" && entry.key != "For You",
      ),
    ];

    final filtered = sections.where((entry) {
      if (entry.value.isEmpty) return false;
      return !_layoutConfig.hiddenSections.contains(entry.key);
    }).toList();
    final originalIndex = <String, int>{};
    for (var i = 0; i < sections.length; i++) {
      originalIndex[sections[i].key] = i;
    }

    final orderIndex = <String, int>{};
    for (var i = 0; i < _layoutConfig.orderedSections.length; i++) {
      orderIndex[_layoutConfig.orderedSections[i]] = i;
    }

    filtered.sort((a, b) {
      final aOrder = orderIndex[a.key] ?? 100000;
      final bOrder = orderIndex[b.key] ?? 100000;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return (originalIndex[a.key] ?? 0).compareTo(originalIndex[b.key] ?? 0);
    });

    return filtered
        .map((entry) => _buildSection(entry.key, entry.value))
        .toList();
  }

  List<String> _availableSections(HomeState state) {
    final keys = <String>{"Trending Now", "For You", ...state.homeMap.keys};
    return keys.toList();
  }
}
