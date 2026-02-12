import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Center(
      child: Text("Home Feed", style: TextStyle(color: Colors.white)),
    ),
    const Center(
      child: Text("Deep Discovery", style: TextStyle(color: Colors.white)),
    ),
    const Center(
      child: Text("Library", style: TextStyle(color: Colors.white)),
    ),
    const Center(
      child: Text("Search", style: TextStyle(color: Colors.white)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        height: 88,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),

          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: const Color(0xFF0984E3),
          unselectedItemColor: Colors.white38,

          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(CupertinoIcons.house_fill, size: 24),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(CupertinoIcons.compass, size: 24),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(CupertinoIcons.square_stack_3d_up_fill, size: 24),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(CupertinoIcons.search, size: 26),
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
