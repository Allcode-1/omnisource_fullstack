import 'package:flutter/material.dart';
import '../../../domain/entities/unified_content.dart';

class ContentCard extends StatelessWidget {
  final UnifiedContent item;
  const ContentCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(item.imageUrl ?? ''),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA020816),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: item.imageUrl == null || item.imageUrl!.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2743),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white38),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          item.subtitle ?? item.type,
          maxLines: 1,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
