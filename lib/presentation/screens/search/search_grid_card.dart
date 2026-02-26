import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/analytics_repository.dart';
import '../../bloc/library/library_cubit.dart';
import '../../bloc/library/library_state.dart';
import '../../widgets/content_quick_actions.dart';
import '../home/detail_screen.dart';

class SearchGridCard extends StatelessWidget {
  final UnifiedContent item;

  const SearchGridCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final isLiked = state is LibraryLoaded
            ? state.favorites.any((fav) => fav.externalId == item.externalId)
            : false;

        return GestureDetector(
          onLongPress: () =>
              ContentQuickActions.show(context, item, source: 'search'),
          onTap: () {
            context.read<AnalyticsRepository>().trackEvent(
              type: 'view',
              extId: item.externalId,
              contentType: item.type,
              meta: {
                'source': 'search_grid_card',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          item.imageUrl ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Container(
                            color: const Color(0xFF1A2743),
                            child: Icon(
                              _getIconData(item.type),
                              color: Colors.white24,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () => ContentQuickActions.show(
                            context,
                            item,
                            source: 'search',
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0x7A0A1020),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.ellipsis,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              context.read<LibraryCubit>().toggleFavorite(item),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0x7A0A1020),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLiked
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: isLiked
                                  ? const Color(0xFFFF6B7A)
                                  : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Градиент снизу (App Store стиль)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                const Color(0xCC040914),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
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
