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

    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, libraryState) {
        bool isLiked = false;
        if (libraryState is LibraryLoaded) {
          isLiked = libraryState.favorites.any(
            (fav) => fav.externalId == item.externalId,
          );
        }

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
              CupertinoPageRoute(
                builder: (context) => DetailScreen(content: item),
              ),
            );
          },
          child: Container(
            width: 145,
            margin: const EdgeInsets.only(right: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _buildImage(),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: () => ContentQuickActions.show(
                          context,
                          item,
                          source: 'home',
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.ellipsis,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          await context.read<LibraryCubit>().toggleFavorite(
                            item,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLiked
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            color: isLiked ? Colors.redAccent : Colors.white,
                            size: 20,
                          ),
                        ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  item.subtitle ?? '',
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage() {
    return Container(
      height: 145,
      width: 145,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          item.imageUrl ?? '',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.white.withValues(alpha: 0.05),
            child: Icon(
              _getIconData(item.type),
              color: Colors.white24,
              size: 40,
            ),
          ),
        ),
      ),
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
