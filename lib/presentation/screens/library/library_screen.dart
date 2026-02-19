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
    required List<dynamic> items,
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
      trailing: const Icon(CupertinoIcons.right_chevron, size: 18),
      onTap: () {
        final safeItems = items.whereType<UnifiedContent>().toList();

        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) =>
                PlaylistDetailScreen(title: title, initialItems: safeItems),
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
              if (controller.text.isNotEmpty) {
                context.read<LibraryCubit>().createPlaylist(controller.text);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
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
                          ),

                          const Divider(color: Colors.white10, height: 1),

                          ...state.playlists.map(
                            (playlist) => _buildPlaylistTile(
                              title: playlist.title,
                              icon: CupertinoIcons.music_note_list,
                              items: playlist.items,
                            ),
                          ),
                        ]),
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
                    username[0].toUpperCase(),
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
