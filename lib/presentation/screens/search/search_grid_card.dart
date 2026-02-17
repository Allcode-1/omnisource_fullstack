import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/unified_content.dart';
import '../home/detail_screen.dart';

class SearchGridCard extends StatelessWidget {
  final UnifiedContent item;

  const SearchGridCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1C1C1E),
                        child: Icon(
                          _getIconData(item.type),
                          color: Colors.white24,
                          size: 40,
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
                            Colors.black.withOpacity(0.6),
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
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
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
