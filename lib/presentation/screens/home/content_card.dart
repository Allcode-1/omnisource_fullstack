import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/analytics_repository.dart';
import '../../bloc/library/library_cubit.dart';
import '../../bloc/library/library_state.dart';
import '../../widgets/content_quick_actions.dart';
import './detail_screen.dart';

class ContentCard extends StatelessWidget {
  final UnifiedContent item;
  const ContentCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = (item.imageUrl ?? '').trim();

    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, libraryState) {
        final isLiked = libraryState is LibraryLoaded
            ? libraryState.favorites.any(
                (fav) => fav.externalId == item.externalId,
              )
            : false;

        return GestureDetector(
          onLongPress: () =>
              ContentQuickActions.show(context, item, source: 'home'),
          onTap: () {
            context.read<AnalyticsRepository>().trackEvent(
              type: 'view',
              extId: item.externalId,
              contentType: item.type,
              meta: {
                'source': 'home_content_card',
                'title': item.title,
                'image_url': item.imageUrl,
                'rating': item.rating,
                'release_date': item.releaseDate,
                'genres': item.genres,
              },
            );
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => DetailScreen(content: item)),
            );
          },
          child: SizedBox(
            width: 145,
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _buildImage(imageUrl),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _CircleAction(
                          icon: CupertinoIcons.ellipsis,
                          onTap: () => ContentQuickActions.show(
                            context,
                            item,
                            source: 'home',
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _CircleAction(
                          icon: isLiked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          iconColor: isLiked
                              ? const Color(0xFFFF6B7A)
                              : Colors.white,
                          onTap: () =>
                              context.read<LibraryCubit>().toggleFavorite(item),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        _getIconData(item.type),
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.58),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _typeLabel(item.type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      if (item.rating > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${item.rating.toStringAsFixed(1)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if ((item.subtitle ?? '').isNotEmpty)
                    Text(
                      item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.46),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'movie':
        return 'Movie';
      case 'book':
        return 'Book';
      default:
        return 'Music';
    }
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      height: 145,
      width: 145,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _imageFallback(),
              )
            : _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: Icon(_getIconData(item.type), color: Colors.white24, size: 40),
    );
  }

  IconData _getIconData(String? type) {
    switch (type) {
      case 'movie':
        return Icons.movie_filter_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Color(0x66000000),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: iconColor),
      ),
    );
  }
}
