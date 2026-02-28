import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/unified_content.dart';
import '../../bloc/library/library_cubit.dart';
import '../home/detail_screen.dart';

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
  String filterType = 'all';
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
    final theme = Theme.of(context);
    List<UnifiedContent> filteredItems = _items.where((item) {
      if (filterType == 'all') return true;
      return item.type == filterType;
    }).toList();

    if (!sortNewest) filteredItems = filteredItems.reversed.toList();

    final stats = _getStats();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            middle: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            border: null,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.86),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Text(
                isEditMode ? "Done" : "Edit",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => setState(() => isEditMode = !isEditMode),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildHeaderCard(theme, stats),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _buildFilterRow(theme),
            ),
          ),
          if (isEditMode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text("Select All"),
                      onPressed: () => setState(
                        () => selectedIds = filteredItems
                            .map((e) => e.externalId)
                            .toSet(),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text("Deselect"),
                      onPressed: () => setState(() => selectedIds.clear()),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = filteredItems[index];
                final isSelected = selectedIds.contains(item.externalId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildItemTile(theme, item, isSelected),
                );
              }, childCount: filteredItems.length),
            ),
          ),
        ],
      ),
      bottomSheet: isEditMode && selectedIds.isNotEmpty
          ? SafeArea(
              top: false,
              child: Container(
                color: theme.colorScheme.surface.withValues(alpha: 0.96),
                padding: const EdgeInsets.all(14),
                child: CupertinoButton(
                  color: CupertinoColors.destructiveRed,
                  onPressed: _isRemoving ? null : _removeSelected,
                  child: _isRemoving
                      ? const CupertinoActivityIndicator()
                      : Text("Remove Selected (${selectedIds.length})"),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderCard(ThemeData theme, String stats) {
    final cover = _items.isNotEmpty ? _items.first.imageUrl ?? '' : '';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface.withValues(alpha: 0.86),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            if (cover.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  cover,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('${_items.length} items'),
                      _chip(stats),
                      _chip(sortNewest ? 'Newest first' : 'Oldest first'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(theme, "All", 'all'),
          _buildFilterChip(theme, "Music", 'music'),
          _buildFilterChip(theme, "Movies", 'movie'),
          _buildFilterChip(theme, "Books", 'book'),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () => setState(() => sortNewest = !sortNewest),
            child: Icon(
              sortNewest ? CupertinoIcons.sort_down : CupertinoIcons.sort_up,
              size: 18,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(ThemeData theme, UnifiedContent item, bool isSelected) {
    final imageUrl = (item.imageUrl ?? '').trim();
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white10,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: Colors.white30,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.white10,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        CupertinoIcons.photo,
                        color: Colors.white30,
                      ),
                    ),
            ),
            if (isEditMode)
              Positioned.fill(
                child: Container(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4),
                  child: Icon(
                    isSelected
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.circle,
                    color: Colors.white,
                    size: 20,
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
        trailing: isEditMode
            ? const SizedBox.shrink()
            : Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
        onTap: () {
          if (isEditMode) {
            setState(() {
              if (isSelected) {
                selectedIds.remove(item.externalId);
              } else {
                selectedIds.add(item.externalId);
              }
            });
            return;
          }
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => DetailScreen(content: item)),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, String type) {
    final isSelected = filterType == type;
    return GestureDetector(
      onTap: () => setState(() => filterType = type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.15 : 0.08),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getStats() {
    final music = _items.where((i) => i.type == 'music').length;
    final movie = _items.where((i) => i.type == 'movie').length;
    final book = _items.where((i) => i.type == 'book').length;
    return '$music music • $movie movies • $book books';
  }
}
