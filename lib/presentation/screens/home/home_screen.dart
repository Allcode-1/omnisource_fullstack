import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/unified_content.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/home/home_cubit.dart';
import '../profile/profile_screen.dart';
import 'content_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      double newOpacity = (1.0 - (_scrollController.offset / 100)).clamp(
        0.0,
        1.0,
      );
      if (newOpacity != _appBarOpacity)
        setState(() => _appBarOpacity = newOpacity);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CupertinoSlidingSegmentedControl<ContentCategory>(
                        groupValue: state.category,
                        backgroundColor: Colors.white10,
                        thumbColor: Colors.white24,
                        children: const {
                          ContentCategory.music: Text(
                            "Music",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          ContentCategory.movie: Text(
                            "Movies",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          ContentCategory.book: Text(
                            "Books",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        },
                        onValueChanged: (val) {
                          if (val != null)
                            context.read<HomeCubit>().setCategory(val);
                        },
                      ),
                    ),
                  ),
                  if (state.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CupertinoActivityIndicator(color: Colors.white),
                      ),
                    )
                  else ...[
                    SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSection("Trending Now", state.trending),
                        _buildSection("For You", state.recommendations),
                        ..._buildDynamicRows(state),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ],
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _appBarOpacity,
                  child: _buildAppBar(context),
                ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "OmniSource",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              GestureDetector(
                onTap: () {
                  final userRepository = context.read<UserRepository>();
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) =>
                          ProfileScreen(userRepository: userRepository),
                    ),
                  );
                },
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

  Widget _buildSection(String title, List<UnifiedContent> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 25, 16, 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => ContentCard(item: items[index]),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDynamicRows(HomeState state) {
    return state.homeMap.entries
        .where((e) => e.key != "Trending Now" && e.key != "For You")
        .map((e) => _buildSection(e.key, e.value))
        .toList();
  }
}
