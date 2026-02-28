import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/analytics_repository.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../bloc/library/library_cubit.dart';
import '../../bloc/library/library_state.dart';
import '../search/search_grid_card.dart';

class DetailScreen extends StatefulWidget {
  static const Color _bgColor = AppTheme.appBackground;
  static const Color _surfaceColor = AppTheme.surface;

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

  Future<void> _loadRelated() async {
    try {
      final repo = context.read<ContentRepository>();
      final data = await repo.getRecommendations(type: content.type);
      if (!mounted) return;
      setState(() {
        _relatedError = '';
        _related = data
            .where((item) => item.externalId != content.externalId)
            .take(10)
            .toList();
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
        return Icons.movie_creation_outlined;
      case 'book':
        return Icons.menu_book_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }

  Widget _buildImageFallback({bool fill = false, double size = 120}) {
    final icon = Icon(
      _iconByType(content.type),
      color: Colors.white24,
      size: size / 2.8,
    );

    if (fill) {
      return ColoredBox(
        color: Colors.white.withValues(alpha: 0.08),
        child: Center(child: icon),
      );
    }

    return Container(
      width: size,
      height: size,
      color: Colors.white.withValues(alpha: 0.08),
      child: Center(child: icon),
    );
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
      backgroundColor: DetailScreen._surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Add To Playlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              ...state.playlists.map(
                (playlist) => ListTile(
                  title: Text(playlist.title),
                  subtitle: Text('${playlist.items.length} items'),
                  trailing: const Icon(CupertinoIcons.add_circled),
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
        );
      },
    );
  }

  String _buildExplainText() {
    final genres = content.genres.take(3).join(', ');
    final genreText = genres.isEmpty ? 'genre signals' : genres;
    return 'This item appears because your interaction profile matches '
        '${content.type} content with $genreText and similar rating patterns.';
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
        content: Text('Source link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (content.imageUrl ?? '').trim();

    return Scaffold(
      backgroundColor: DetailScreen._bgColor,
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          final isLiked = state is LibraryLoaded
              ? state.favorites.any(
                  (fav) => fav.externalId == content.externalId,
                )
              : false;

          return Stack(
            children: [
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImageFallback(fill: true),
                        ),
                      )
                    : _buildImageFallback(fill: true),
              ),
              Positioned.fill(
                child: Container(
                  color: DetailScreen._bgColor.withValues(alpha: 0.78),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0x7A0A1020),
                      child: BackButton(color: Colors.white),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? const Color(0xFFFF6B7A)
                              : Colors.white,
                        ),
                        onPressed: () => context
                            .read<LibraryCubit>()
                            .toggleFavorite(content),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: 290,
                              width: 198,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xA6020816),
                                    blurRadius: 26,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildImageFallback(),
                                      )
                                    : _buildImageFallback(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            content.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if ((content.subtitle ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              content.subtitle!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MetaChip(label: _displayType(content.type)),
                              if (content.rating > 0)
                                _MetaChip(
                                  label:
                                      'Rating ${content.rating.toStringAsFixed(1)}',
                                ),
                              if ((content.releaseDate ?? '').isNotEmpty)
                                _MetaChip(label: content.releaseDate!),
                            ],
                          ),
                          if (content.genres.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: content.genres
                                  .take(5)
                                  .map((genre) => _MetaChip(label: '#$genre'))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 18),
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white54,
                            indicatorColor: AppTheme.primary,
                            tabs: const [
                              Tab(text: 'Overview'),
                              Tab(text: 'Related'),
                              Tab(text: 'Sources'),
                              Tab(text: 'Why'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 360,
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            content.description?.trim().isNotEmpty == true
                ? content.description!
                : 'No detailed description available.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (content.genres.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: content.genres
                  .map((genre) => _MetaChip(label: genre))
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showAddToPlaylistSheet(context),
              icon: const Icon(CupertinoIcons.music_note_list),
              label: const Text('Add To Playlist'),
            ),
          ),
        ],
      ),
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
      return const Center(
        child: Text(
          'No related items',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _related.length.clamp(0, 6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 0.63,
      ),
      itemBuilder: (context, index) => SearchGridCard(item: _related[index]),
    );
  }

  Widget _buildSourcesTab() {
    final links = _buildSourceLinks();
    if (links.isEmpty) {
      return const Center(
        child: Text('No source links', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.separated(
      itemBuilder: (context, index) {
        final item = links[index];
        return ListTile(
          tileColor: DetailScreen._surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(item.title),
          subtitle: Text(item.url, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(CupertinoIcons.arrow_up_right_square),
          onTap: () => _openSource(item.url),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemCount: links.length,
    );
  }

  Widget _buildExplainTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DetailScreen._surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendation Explain',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            _buildExplainText(),
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 14),
          const Text('Signals', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('• Content type affinity'),
          const Text('• Similarity score from interaction vectors'),
          const Text('• Popularity and rating balancing'),
          const Text('• Recent dwell/open behavior'),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2C49),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SourceLink {
  final String title;
  final String url;
  const _SourceLink({required this.title, required this.url});
}
