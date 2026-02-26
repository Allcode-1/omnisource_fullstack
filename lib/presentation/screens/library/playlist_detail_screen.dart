import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/unified_content.dart';
import '../../bloc/library/library_cubit.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String? playlistId;
  final String title;
  final String? description;
  final List<UnifiedContent> initialItems;
  final bool isFavorites;

  const PlaylistDetailScreen({
    super.key,
    this.playlistId,
    required this.title,
    this.description,
    required this.initialItems,
    this.isFavorites = false,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool isEditMode = false;
  Set<String> selectedIds = {};
  String filterType = 'all'; // all, music, movie, book
  bool sortNewest = true;
  bool _isRemoving = false;
  late List<UnifiedContent> _items;

  @override
  void initState() {
    super.initState();
    _items = List<UnifiedContent>.from(widget.initialItems);
  }

  Future<void> _removeSelected() async {
    if (selectedIds.isEmpty || _isRemoving) return;

    final cubit = context.read<LibraryCubit>();
    setState(() => _isRemoving = true);

    try {
      final ids = selectedIds.toList();
      if (widget.isFavorites) {
        final selectedItems = _items
            .where((item) => selectedIds.contains(item.externalId))
            .toList();
        await cubit.removeFavorites(selectedItems);
      } else if (widget.playlistId != null) {
        await cubit.removeItemsFromPlaylist(widget.playlistId!, ids);
      }

      if (!mounted) return;
      setState(() {
        _items = _items
            .where((item) => !selectedIds.contains(item.externalId))
            .toList();
        selectedIds.clear();
        isEditMode = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Фильтрация и сортировка
    List<UnifiedContent> filteredItems = _items.where((item) {
      if (filterType == 'all') return true;
      return item.type == filterType;
    }).toList();

    if (!sortNewest) filteredItems = filteredItems.reversed.toList();

    final stats = _getStats();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              widget.title,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Text(isEditMode ? "Done" : "Edit"),
              onPressed: () => setState(() => isEditMode = !isEditMode),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.description != null)
                    Text(
                      widget.description!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    stats,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("All", 'all'),
                        _buildFilterChip("Music", 'music'),
                        _buildFilterChip("Movies", 'movie'),
                        _buildFilterChip("Books", 'book'),
                        const SizedBox(width: 20),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(
                            sortNewest
                                ? CupertinoIcons.sort_down
                                : CupertinoIcons.sort_up,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => sortNewest = !sortNewest),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isEditMode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CupertinoButton(
                      child: const Text("Select All"),
                      onPressed: () => setState(
                        () => selectedIds = filteredItems
                            .map((e) => e.externalId)
                            .toSet(),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      child: const Text("Deselect"),
                      onPressed: () => setState(() => selectedIds.clear()),
                    ),
                  ],
                ),
              ),
            ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = filteredItems[index];
              final isSelected = selectedIds.contains(item.externalId);

              return ListTile(
                leading: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white10,
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    if (isEditMode)
                      Positioned.fill(
                        child: Container(
                          color: isSelected
                              ? const Color(0x885AA9FF)
                              : const Color(0x760A1020),
                          child: Icon(
                            isSelected
                                ? CupertinoIcons.check_mark_circled_solid
                                : CupertinoIcons.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  item.subtitle ?? item.type,
                  style: const TextStyle(color: Colors.white60),
                ),
                onTap: () {
                  if (isEditMode) {
                    setState(() {
                      if (isSelected)
                        selectedIds.remove(item.externalId);
                      else
                        selectedIds.add(item.externalId);
                    });
                  } else {}
                },
              );
            }, childCount: filteredItems.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomSheet: isEditMode && selectedIds.isNotEmpty
          ? Container(
              color: const Color(0xFF111A2E),
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                color: CupertinoColors.destructiveRed,
                child: _isRemoving
                    ? const CupertinoActivityIndicator()
                    : const Text("Remove Selected"),
                onPressed: _isRemoving ? null : _removeSelected,
              ),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = filterType == type;
    return GestureDetector(
      onTap: () => setState(() => filterType = type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5AA9FF) : const Color(0xFF1A2743),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  String _getStats() {
    int music = _items.where((i) => i.type == 'music').length;
    int movie = _items.where((i) => i.type == 'movie').length;
    int book = _items.where((i) => i.type == 'book').length;
    return "$music music, $movie movies, $book books";
  }
}
