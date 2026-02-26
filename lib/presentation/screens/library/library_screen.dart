import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnisource/domain/entities/unified_content.dart';
import '../../bloc/library/library_cubit.dart';
import '../../bloc/library/library_state.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../domain/repositories/user_repository.dart';
import '../profile/profile_screen.dart';
import 'content_card.dart';
import 'playlist_detail_screen.dart';
import 'playlist_editor_screen.dart';
import 'smart_library_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LibraryCubit>().loadLibraryData();
  }

  Widget _buildPlaylistTile({
    required String title,
    required IconData icon,
    required List<UnifiedContent> items,
    String? playlistId,
    String? description,
    bool isFavorites = false,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white54),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text("${items.length} items"),
      trailing: isFavorites
          ? const Icon(CupertinoIcons.right_chevron, size: 18)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (playlistId == null) return;
                    _showPlaylistActions(
                      playlistId: playlistId,
                      currentTitle: title,
                      currentDescription: description,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(CupertinoIcons.ellipsis_circle, size: 20),
                  ),
                ),
                const Icon(CupertinoIcons.right_chevron, size: 18),
              ],
            ),
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => PlaylistDetailScreen(
              playlistId: playlistId,
              title: title,
              description: description,
              initialItems: items,
              isFavorites: isFavorites,
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("New Playlist"),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: controller,
            placeholder: "Title",
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: const Text("Create"),
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                context.read<LibraryCubit>().createPlaylist(title);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPlaylistActions({
    required String playlistId,
    required String currentTitle,
    String? currentDescription,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(currentTitle),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditPlaylistDialog(
                playlistId: playlistId,
                currentTitle: currentTitle,
                currentDescription: currentDescription,
              );
            },
            child: const Text('Edit Playlist'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LibraryCubit>().deletePlaylist(playlistId);
            },
            child: const Text('Delete Playlist'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showEditPlaylistDialog({
    required String playlistId,
    required String currentTitle,
    String? currentDescription,
  }) {
    final titleController = TextEditingController(text: currentTitle);
    final descriptionController = TextEditingController(
      text: currentDescription ?? '',
    );

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Edit Playlist"),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoTextField(
                controller: titleController,
                placeholder: "Title",
                autofocus: true,
              ),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: descriptionController,
                placeholder: "Description (optional)",
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: const Text("Save"),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              context.read<LibraryCubit>().updatePlaylist(
                playlistId,
                title: title,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              );
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _openLibraryTools() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Library Tools'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const SmartLibraryScreen()),
              );
            },
            child: const Text('Smart Library'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const PlaylistEditorScreen()),
              );
            },
            child: const Text('Playlist Editor'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _LibraryToolButton(
                              title: 'Smart Library',
                              icon: CupertinoIcons.chart_bar_alt_fill,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) => const SmartLibraryScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _LibraryToolButton(
                              title: 'Playlist Editor',
                              icon: CupertinoIcons.square_pencil,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) => const PlaylistEditorScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (state is LibraryLoading)
                    const SliverFillRemaining(
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else if (state is LibraryLoaded)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildPlaylistTile(
                            title: "Favorites",
                            icon: CupertinoIcons.heart_fill,
                            iconColor: Colors.redAccent,
                            items: state.favorites,
                            isFavorites: true,
                          ),

                          const Divider(color: Colors.white10, height: 1),

                          ...state.playlists.map(
                            (playlist) => _buildPlaylistTile(
                              title: playlist.title,
                              icon: CupertinoIcons.music_note_list,
                              playlistId: playlist.id,
                              description: playlist.description,
                              items:
                                  state.playlistItemsById[playlist.id] ??
                                  const [],
                            ),
                          ),
                        ]),
                      ),
                    )
                  else if (state is LibraryError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 30, 16, 16),
                      child: Text(
                        "Recently Added",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (state is LibraryLoaded)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              childAspectRatio: 0.7,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              ContentCard(item: state.favorites[index]),
                          childCount: state.favorites.length,
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildAppBar(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final username = authState is AuthAuthenticated
            ? authState.user.username
            : "U";
        final safeLetter = username.trim().isNotEmpty
            ? username.trim().substring(0, 1).toUpperCase()
            : "U";
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 10),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            children: [
              const Text(
                "Library",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showCreatePlaylistDialog,
                child: const Icon(CupertinoIcons.plus_circle, size: 28),
              ),
              const SizedBox(width: 10),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openLibraryTools,
                child: const Icon(CupertinoIcons.slider_horizontal_3, size: 24),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => ProfileScreen(
                      userRepository: context.read<UserRepository>(),
                    ),
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    safeLetter,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryToolButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _LibraryToolButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
