import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Text(
          "Library Screen",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
