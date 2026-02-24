import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/unified_content.dart';
import '../../bloc/library/library_cubit.dart';
import '../../bloc/library/library_state.dart';

class DetailScreen extends StatelessWidget {
  static const Color _bgColor = Color(0xFF121212);
  static const Color _surfaceColor = Color(0xFF1C1C1E);

  final UnifiedContent content;
  const DetailScreen({super.key, required this.content});

  Widget _buildImageFallback({bool fill = false, double size = 120}) {
    final child = Center(
      child: Icon(
        Icons.movie_creation_outlined,
        color: Colors.white24,
        size: size / 3,
      ),
    );

    if (fill) {
      return ColoredBox(color: Colors.white.withOpacity(0.08), child: child);
    }

    return Container(
      width: size,
      height: size,
      color: Colors.white.withOpacity(0.08),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = content.imageUrl ?? '';

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: imageUrl.isNotEmpty
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildImageFallback(fill: true),
                    ),
                  )
                : _buildImageFallback(fill: true),
          ),
          Positioned.fill(child: Container(color: _bgColor.withOpacity(0.75))),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: BackButton(color: Colors.white),
                ),
                actions: [
                  BlocBuilder<LibraryCubit, LibraryState>(
                    builder: (context, state) {
                      bool isLiked = false;
                      if (state is LibraryLoaded) {
                        isLiked = state.favorites.any(
                          (fav) => fav.externalId == content.externalId,
                        );
                      }

                      return IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.redAccent : Colors.white,
                          size: 28,
                        ),
                        onPressed: () => context
                            .read<LibraryCubit>()
                            .toggleFavorite(content),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      height: 310,
                      width: 210,
                      margin: const EdgeInsets.only(top: 12, bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 24),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildImageFallback(),
                              )
                            : _buildImageFallback(),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 100),
                      decoration: const BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            content.subtitle ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            "Description",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            content.description ?? "No description available.",
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.5,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {},
                              child: const Text(
                                "PLAY / READ",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
