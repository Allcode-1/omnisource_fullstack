import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/unified_content.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String title;
  final String? description;
  final List<UnifiedContent> initialItems;

  const PlaylistDetailScreen({
    super.key,
    required this.title,
    this.description,
    required this.initialItems,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool isEditMode = false;
  Set<String> selectedIds = {};
  String filterType = 'all'; // all, music, movie, book
  bool sortNewest = true;

  @override
  Widget build(BuildContext context) {
    // Фильтрация и сортировка
    List<UnifiedContent> filteredItems = widget.initialItems.where((item) {
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
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
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
                            .map((e) => e.id)
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
              final isSelected = selectedIds.contains(item.id);

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
                              ? Colors.blue.withOpacity(0.4)
                              : Colors.black45,
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
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isEditMode) {
                    setState(() {
                      if (isSelected)
                        selectedIds.remove(item.id);
                      else
                        selectedIds.add(item.id);
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
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                color: CupertinoColors.destructiveRed,
                child: const Text("Remove Selected"),
                onPressed: () {},
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
          color: isSelected ? Colors.white : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  String _getStats() {
    int music = widget.initialItems.where((i) => i.type == 'music').length;
    int movie = widget.initialItems.where((i) => i.type == 'movie').length;
    int book = widget.initialItems.where((i) => i.type == 'book').length;
    return "$music music, $movie movies, $book books";
  }
}
