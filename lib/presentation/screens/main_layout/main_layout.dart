import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:omnisource/core/theme/app_theme.dart';
import 'package:omnisource/presentation/screens/deep_research/deep_research_screen.dart';
import 'package:omnisource/presentation/screens/home/home_screen.dart';
import 'package:omnisource/presentation/screens/library/library_screen.dart';
import 'package:omnisource/presentation/screens/search/search_screen.dart';

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
      icon: CupertinoIcons.house_fill,
      activeIcon: CupertinoIcons.house_alt_fill,
      label: 'Home',
    ),
    _NavItem(
      icon: CupertinoIcons.compass,
      activeIcon: CupertinoIcons.compass_fill,
      label: 'Discover',
    ),
    _NavItem(
      icon: CupertinoIcons.square_stack_3d_up,
      activeIcon: CupertinoIcons.square_stack_3d_up_fill,
      label: 'Library',
    ),
    _NavItem(
      icon: CupertinoIcons.search,
      activeIcon: CupertinoIcons.search,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x72000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final showLabel =
                            selected && constraints.maxWidth >= 104;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: showLabel ? 10 : 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selected ? item.activeIcon : item.icon,
                                    size: 20,
                                    color: Colors.white.withValues(
                                      alpha: selected ? 0.96 : 0.68,
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return SizeTransition(
                                        sizeFactor: animation,
                                        axis: Axis.horizontal,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: showLabel
                                        ? Padding(
                                            key: ValueKey(item.label),
                                            padding: const EdgeInsets.only(
                                              left: 7,
                                            ),
                                            child: Text(
                                              item.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(
                                            key: ValueKey('empty'),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
