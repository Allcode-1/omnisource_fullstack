import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../domain/entities/unified_content.dart';

class DetailScreen extends StatelessWidget {
  final UnifiedContent content;
  const DetailScreen({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Фоновое размытое изображение
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(content.imageUrl ?? ''),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                leading: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: BackButton(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      /* Вызов toggleLike из Cubit */
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Постер
                    Container(
                      height: 300,
                      width: 200,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black54, blurRadius: 20),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(content.imageUrl ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Инфо
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1C1C1E), // Серый как в iOS
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
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            content.subtitle ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Description",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            content.description ?? "No description...",
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.5,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: () {},
                              child: const Text(
                                "PLAY / READ",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
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
