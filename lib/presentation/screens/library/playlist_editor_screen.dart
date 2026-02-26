import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/library/library_cubit.dart';
import '../../bloc/library/library_state.dart';

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
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await context.read<LibraryCubit>().deletePlaylist(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist Editor'),
        actions: [
          IconButton(
            onPressed: _showCreateDialog,
            icon: const Icon(CupertinoIcons.plus),
          ),
        ],
      ),
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          if (state is LibraryLoading) {
            return const Center(child: CircularProgressIndicator());
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
          if (state.playlists.isEmpty) {
            return const Center(
              child: Text(
                'No playlists yet',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemBuilder: (context, index) {
              final playlist = state.playlists[index];
              final items = state.playlistItemsById[playlist.id] ?? const [];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  title: Text(playlist.title),
                  subtitle: Text('${items.length} items'),
                  trailing: Wrap(
                    spacing: 10,
                    children: [
                      GestureDetector(
                        onTap: () => _showEditDialog(
                          playlistId: playlist.id,
                          title: playlist.title,
                          description: playlist.description,
                        ),
                        child: const Icon(CupertinoIcons.pencil, size: 18),
                      ),
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
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: state.playlists.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(CupertinoIcons.plus),
        label: const Text('New Playlist'),
      ),
    );
  }
}
