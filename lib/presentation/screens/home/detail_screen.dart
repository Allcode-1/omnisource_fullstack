import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/analytics_repository.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../bloc/library/library_cubit.dart';
import '../../bloc/library/library_state.dart';
import '../search/search_grid_card.dart';

class DetailScreen extends StatefulWidget {
  final UnifiedContent content;

  const DetailScreen({super.key, required this.content});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final DateTime _openedAt;

  bool _loadingRelated = true;
  String _relatedError = '';
  List<UnifiedContent> _related = const [];

  UnifiedContent get content => widget.content;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _openedAt = DateTime.now();
    _trackOpenDetail();
    _loadRelated();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trackDwellTime();
    super.dispose();
  }

  Future<void> _trackOpenDetail() async {
    try {
      await context.read<AnalyticsRepository>().trackEvent(
        type: 'open_detail',
        extId: content.externalId,
        contentType: content.type,
        meta: {
          'title': content.title,
          'subtitle': content.subtitle,
          'image_url': content.imageUrl,
          'rating': content.rating,
          'release_date': content.releaseDate,
          'genres': content.genres,
          'description': content.description,
        },
      );
    } catch (_) {}
  }

  Future<void> _trackDwellTime() async {
    try {
      final seconds = DateTime.now().difference(_openedAt).inSeconds.toDouble();
      await context.read<AnalyticsRepository>().trackEvent(
        type: 'dwell_time',
        extId: content.externalId,
        contentType: content.type,
        weight: seconds > 0 ? seconds / 60 : 0.0,
        meta: {'seconds': seconds},
      );
    } catch (_) {}
  }

  Future<List<UnifiedContent>> _safeRelatedRequest(
    Future<List<UnifiedContent>> Function() loader,
  ) async {
    try {
      return await loader();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _loadRelated() async {
    try {
      final repo = context.read<ContentRepository>();
      final seeds = _relatedSeeds();
      final responses = await Future.wait([
        ...seeds.map(
          (tag) => _safeRelatedRequest(
            () => repo.getDeepResearch(tag, type: content.type),
          ),
        ),
        _safeRelatedRequest(() => repo.getRecommendations(type: content.type)),
      ]);

      final merged = <String, UnifiedContent>{};
      for (final list in responses) {
        for (final item in list) {
          final key = _contentKey(item);
          if (key.isEmpty || key == _contentKey(content)) continue;
          merged.putIfAbsent(key, () => item);
        }
      }

      if (!mounted) return;
      setState(() {
        _relatedError = '';
        _related = _rankRelated(merged.values).take(8).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _related = const [];
        _relatedError = 'Failed to load related content';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRelated = false);
      }
    }
  }

  List<String> _relatedSeeds() {
    final genres = _normalizedGenres(content).take(2).toList();
    if (genres.isNotEmpty) return genres;

    final tokens = _tokens(
      '${content.title} ${content.subtitle ?? ''} ${content.description ?? ''}',
    ).where((token) => token.length > 4).take(2).toList();
    return tokens;
  }

  List<UnifiedContent> _rankRelated(Iterable<UnifiedContent> items) {
    final scored =
        items
            .where((item) => item.type == content.type)
            .map((item) => MapEntry(item, _relatedScore(item)))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) {
            final score = b.value.compareTo(a.value);
            if (score != 0) return score;
            return b.key.rating.compareTo(a.key.rating);
          });

    return scored.map((entry) => entry.key).toList();
  }

  double _relatedScore(UnifiedContent item) {
    var score = 0.0;
    final baseGenres = _normalizedGenres(content).toSet();
    final itemGenres = _normalizedGenres(item).toSet();
    score += baseGenres.intersection(itemGenres).length * 8;

    final baseTokens = _tokens(
      '${content.title} ${content.subtitle ?? ''} ${content.description ?? ''}',
    ).toSet();
    final itemTokens = _tokens(
      '${item.title} ${item.subtitle ?? ''} ${item.description ?? ''}',
    ).toSet();
    score += baseTokens.intersection(itemTokens).length * 1.5;

    if (content.rating > 0 && item.rating > 0) {
      final delta = (content.rating - item.rating).abs();
      if (delta <= 1.5) score += 2.0 - delta;
    }

    final baseYear = _yearOf(content.releaseDate);
    final itemYear = _yearOf(item.releaseDate);
    if (baseYear != null && itemYear != null) {
      final delta = (baseYear - itemYear).abs();
      if (delta <= 3) score += 2.0;
    }

    return score;
  }

  Set<String> _tokens(String value) {
    const ignored = {
      'movie',
      'music',
      'book',
      'with',
      'from',
      'that',
      'this',
      'into',
      'your',
      'their',
      'about',
      'after',
      'before',
      'small',
    };

    return value
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length > 3 && !ignored.contains(token))
        .toSet();
  }

  List<String> _normalizedGenres(UnifiedContent item) {
    return item.genres
        .map((genre) => genre.trim().toLowerCase())
        .where((genre) => genre.isNotEmpty)
        .toList();
  }

  int? _yearOf(String? releaseDate) {
    if (releaseDate == null || releaseDate.length < 4) return null;
    return int.tryParse(releaseDate.substring(0, 4));
  }

  String _contentKey(UnifiedContent item) {
    final externalId = item.externalId.trim();
    if (externalId.isNotEmpty) return '${item.type}:$externalId';
    return '${item.type}:${item.id}';
  }

  String _displayType(String type) {
    switch (type) {
      case 'movie':
        return 'Movie';
      case 'book':
        return 'Book';
      case 'music':
        return 'Music';
      default:
        return 'Content';
    }
  }

  IconData _iconByType(String type) {
    switch (type) {
      case 'movie':
        return PhosphorIcons.filmSlate();
      case 'book':
        return PhosphorIcons.bookOpen();
      default:
        return PhosphorIcons.musicNote();
    }
  }

  Future<void> _showAddToPlaylistSheet(BuildContext context) async {
    final state = context.read<LibraryCubit>().state;
    if (state is! LibraryLoaded || state.playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a playlist first'),
          backgroundColor: AppTheme.surfaceAlt,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    'Add to playlist',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                ...state.playlists.map(
                  (playlist) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    title: Text(playlist.title),
                    subtitle: Text('${playlist.items.length} items'),
                    trailing: const Icon(CupertinoIcons.plus_circle),
                    onTap: () async {
                      await context.read<LibraryCubit>().addItemToPlaylist(
                        playlist.id,
                        content,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildExplainText() {
    final genres = content.genres.take(3).join(', ');
    final genreText = genres.isEmpty ? 'similar behavior signals' : genres;
    return 'This recommendation is based on your interest in '
        '${_displayType(content.type).toLowerCase()} content, $genreText, '
        'rating patterns, and recent opens.';
  }

  List<_SourceLink> _buildSourceLinks() {
    switch (content.type) {
      case 'movie':
        return [
          _SourceLink(
            title: 'TMDB',
            url: 'https://www.themoviedb.org/movie/${content.externalId}',
          ),
        ];
      case 'music':
        return [
          _SourceLink(
            title: 'Spotify',
            url: 'https://open.spotify.com/track/${content.externalId}',
          ),
        ];
      case 'book':
        return [
          _SourceLink(
            title: 'Google Books',
            url: 'https://books.google.com/books?id=${content.externalId}',
          ),
        ];
      default:
        return const [];
    }
  }

  Future<void> _openSource(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Source link copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (content.imageUrl ?? '').trim();

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          final isLiked = state is LibraryLoaded
              ? state.favorites.any(
                  (fav) => _contentKey(fav) == _contentKey(content),
                )
              : false;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: Row(
                      children: [
                        _RoundIconButton(
                          icon: CupertinoIcons.back,
                          onTap: () => Navigator.maybePop(context),
                        ),
                        const Spacer(),
                        _RoundIconButton(
                          icon: PhosphorIcons.heart(
                            isLiked
                                ? PhosphorIconsStyle.fill
                                : PhosphorIconsStyle.regular,
                          ),
                          color: isLiked
                              ? const Color(0xFFFF5D73)
                              : AppTheme.ink,
                          onTap: () => context
                              .read<LibraryCubit>()
                              .toggleFavorite(content),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _Poster(imageUrl: imageUrl, item: content),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        content.title,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _metaLine(),
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.ink.withValues(alpha: 0.64),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (content.genres.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: content.genres
                              .take(5)
                              .map((genre) => _MetaPill(label: genre))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildTabs(),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.5,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(context),
                            _buildRelatedTab(),
                            _buildSourcesTab(),
                            _buildExplainTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _metaLine() {
    final parts = <String>[_displayType(content.type)];
    if (content.rating > 0) {
      parts.add(content.rating.toStringAsFixed(1));
    }
    if ((content.releaseDate ?? '').isNotEmpty) {
      parts.add(content.releaseDate!);
    }
    if ((content.subtitle ?? '').isNotEmpty) {
      parts.add(content.subtitle!);
    }
    return parts.join('  -  ');
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppTheme.ink,
      unselectedLabelColor: AppTheme.ink.withValues(alpha: 0.52),
      indicatorColor: AppTheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppTheme.ink.withValues(alpha: 0.12),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Related'),
        Tab(text: 'Sources'),
        Tab(text: 'Why'),
      ],
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          content.description?.trim().isNotEmpty == true
              ? content.description!
              : 'No detailed description available.',
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.72),
            fontSize: 15,
            height: 1.52,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _showAddToPlaylistSheet(context),
            icon: const Icon(CupertinoIcons.music_note_list, size: 18),
            label: const Text(
              'Add to Playlist',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedTab() {
    if (_loadingRelated) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_relatedError.isNotEmpty) {
      return Center(
        child: Text(
          _relatedError,
          style: const TextStyle(color: Color(0xFFFF7A7A)),
        ),
      );
    }
    if (_related.isEmpty) {
      return Center(
        child: Text(
          'No close matches yet',
          style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.52)),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: _related.length.clamp(0, 6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: 0.63,
      ),
      itemBuilder: (context, index) => SearchGridCard(item: _related[index]),
    );
  }

  Widget _buildSourcesTab() {
    final links = _buildSourceLinks();
    if (links.isEmpty) {
      return Center(
        child: Text(
          'No source links',
          style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.52)),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final item = links[index];
        return _DetailListRow(
          title: item.title,
          subtitle: item.url,
          icon: CupertinoIcons.arrow_up_right,
          onTap: () => _openSource(item.url),
        );
      },
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: AppTheme.ink.withValues(alpha: 0.08)),
      itemCount: links.length,
    );
  }

  Widget _buildExplainTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text(
          _buildExplainText(),
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.72),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Signals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _SignalRow(icon: _iconByType(content.type), text: 'Content type'),
        _SignalRow(icon: PhosphorIcons.star(), text: 'Rating pattern'),
        _SignalRow(icon: PhosphorIcons.clock(), text: 'Recent behavior'),
        _SignalRow(icon: PhosphorIcons.sparkle(), text: 'Genre similarity'),
      ],
    );
  }
}

class _Poster extends StatelessWidget {
  final String imageUrl;
  final UnifiedContent item;

  const _Poster({required this.imageUrl, required this.item});

  @override
  Widget build(BuildContext context) {
    final isSquare = item.type == 'music';
    final width = isSquare ? 232.0 : 222.0;
    final height = isSquare ? 232.0 : 326.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _PosterFallback(item: item),
              )
            : _PosterFallback(item: item),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  final UnifiedContent item;

  const _PosterFallback({required this.item});

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      'movie' => PhosphorIcons.filmSlate(),
      'book' => PhosphorIcons.bookOpen(),
      _ => PhosphorIcons.musicNote(),
    };

    return Container(
      color: AppTheme.surfaceAlt,
      alignment: Alignment.center,
      child: Icon(icon, color: AppTheme.ink.withValues(alpha: 0.32), size: 52),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: color ?? AppTheme.ink, size: 24),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;

  const _MetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.ink,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DetailListRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DetailListRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppTheme.ink.withValues(alpha: 0.52),
          fontSize: 12,
        ),
      ),
      trailing: Icon(icon, color: AppTheme.ink.withValues(alpha: 0.64)),
      onTap: onTap,
    );
  }
}

class _SignalRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SignalRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.ink.withValues(alpha: 0.62)),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.72)),
          ),
        ],
      ),
    );
  }
}

class _SourceLink {
  final String title;
  final String url;

  const _SourceLink({required this.title, required this.url});
}
