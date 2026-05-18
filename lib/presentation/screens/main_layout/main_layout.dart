import 'package:flutter/material.dart';
import 'package:omnisource/core/theme/app_theme.dart';
import 'package:omnisource/presentation/screens/deep_research/deep_research_screen.dart';
import 'package:omnisource/presentation/screens/home/home_screen.dart';
import 'package:omnisource/presentation/screens/library/library_screen.dart';
import 'package:omnisource/presentation/screens/search/search_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DeepResearchScreen(),
    const LibraryScreen(),
    const SearchScreen(),
  ];

  static const _items = <_NavItem>[
    _NavItem(
      icon: PhosphorIconsRegular.house,
      activeIcon: PhosphorIconsFill.house,
      label: 'Home',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.compass,
      activeIcon: PhosphorIconsFill.compass,
      label: 'Discover',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.stackSimple,
      activeIcon: PhosphorIconsFill.stackSimple,
      label: 'Library',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.magnifyingGlass,
      activeIcon: PhosphorIconsBold.magnifyingGlass,
      label: 'Search',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: SizedBox(
          height: 66,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x8A000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final selected = _currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _currentIndex = index),
                    child: Tooltip(
                      message: item.label,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 22,
                              color: AppTheme.ink.withValues(
                                alpha: selected ? 1 : 0.6,
                              ),
                            ),
                            const SizedBox(height: 7),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: selected ? 18 : 4,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppTheme.ink.withValues(
                                  alpha: selected ? 1 : 0,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
