import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/library/library_cubit.dart';
import '../../bloc/library/library_state.dart';
import 'playlist_detail_screen.dart';

class PlaylistEditorScreen extends StatefulWidget {
  const PlaylistEditorScreen({super.key});

  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends State<PlaylistEditorScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LibraryCubit>().loadLibraryData();
  }

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('Create Playlist'),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: titleController,
                  placeholder: 'Title',
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: descriptionController,
                  placeholder: 'Description (optional)',
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                await context.read<LibraryCubit>().createPlaylist(title);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog({
    required String playlistId,
    required String title,
    String? description,
  }) async {
    final titleController = TextEditingController(text: title);
    final descriptionController = TextEditingController(
      text: description ?? '',
    );
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('Edit Playlist'),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: titleController,
                  placeholder: 'Title',
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: descriptionController,
                  placeholder: 'Description (optional)',
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                final nextTitle = titleController.text.trim();
                if (nextTitle.isEmpty) return;
                final nextDescription = descriptionController.text.trim();
                await context.read<LibraryCubit>().updatePlaylist(
                  playlistId,
                  title: nextTitle,
                  description: nextDescription.isEmpty ? null : nextDescription,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlaylist(String id) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: const Text('Delete Playlist'),
          message: const Text('This action cannot be undone.'),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                await context.read<LibraryCubit>().deletePlaylist(id);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          if (state is LibraryLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (state is LibraryError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (state is! LibraryLoaded) {
            return const SizedBox.shrink();
          }

          final totalItems = state.playlists.fold<int>(
            0,
            (sum, p) => sum + (state.playlistItemsById[p.id]?.length ?? 0),
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  'Playlist Editor',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                border: null,
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.86,
                ),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showCreateDialog,
                  child: const Icon(CupertinoIcons.plus_circle, size: 28),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            title: 'Playlists',
                            value: '${state.playlists.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Metric(title: 'Items', value: '$totalItems'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (state.playlists.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No playlists yet',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final playlist = state.playlists[index];
                      final items =
                          state.playlistItemsById[playlist.id] ?? const [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.84,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => PlaylistDetailScreen(
                                    playlistId: playlist.id,
                                    title: playlist.title,
                                    description: playlist.description,
                                    initialItems: items,
                                  ),
                                ),
                              );
                            },
                            title: Text(
                              playlist.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              playlist.description?.trim().isNotEmpty == true
                                  ? '${items.length} items • ${playlist.description}'
                                  : '${items.length} items',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => _showEditDialog(
                                    playlistId: playlist.id,
                                    title: playlist.title,
                                    description: playlist.description,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.pencil,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                GestureDetector(
                                  onTap: () => _deletePlaylist(playlist.id),
                                  child: const Icon(
                                    CupertinoIcons.delete,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: state.playlists.length),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: CupertinoButton.filled(
            onPressed: _showCreateDialog,
            child: const Text('New Playlist'),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;

  const _Metric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.56),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
