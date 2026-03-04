import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnisource/domain/entities/unified_content.dart';
import '../../../core/theme/app_theme.dart';
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.95,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.white.withValues(alpha: 0.82),
            size: 19,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          description?.trim().isNotEmpty == true
              ? '${items.length} items • ${description!.trim()}'
              : "${items.length} items",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
      ),
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
        title: const Text('Library Actions'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showCreatePlaylistDialog();
            },
            child: const Text('New Playlist'),
          ),
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
                CupertinoPageRoute(
                  builder: (_) => const PlaylistEditorScreen(),
                ),
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
                  if (state is LibraryLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CupertinoActivityIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  else if (state is LibraryLoaded)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildPlaylistTile(
                            title: "Favorites",
                            icon: CupertinoIcons.heart_fill,
                            iconColor: Colors.redAccent,
                            items: state.favorites,
                            isFavorites: true,
                          ),

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
                          style: const TextStyle(color: Color(0xFFFF7A7A)),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 30, 20, 16),
                      child: Text(
                        "Recently Added",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (state is LibraryLoaded)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          padding: const EdgeInsets.fromLTRB(20, 54, 20, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Text(
                "Library",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _openLibraryTools,
                icon: const Icon(CupertinoIcons.gear_alt_fill, size: 22),
              ),
              const SizedBox(width: 10),
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
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                  child: Text(
                    safeLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
