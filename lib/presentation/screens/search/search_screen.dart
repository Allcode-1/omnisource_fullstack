import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/user_repository.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/search/search_cubit.dart';
import '../../bloc/search/search_state.dart';
import '../profile/profile_screen.dart';
import 'search_grid_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  double _appBarOpacity = 1.0;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final newOpacity = (1.0 - (_scrollController.offset / 80)).clamp(
        0.0,
        1.0,
      );
      if (newOpacity != _appBarOpacity) {
        setState(() => _appBarOpacity = newOpacity);
      }
    });

    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSearchBar(context),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFilters(context, state.activeType),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  if (state.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CupertinoActivityIndicator(color: Colors.white),
                      ),
                    )
                  else if (state.results.isEmpty)
                    _buildEmptyState(_searchController.text.isEmpty)
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 18,
                              childAspectRatio: 0.63,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              SearchGridCard(item: state.results[index]),
                          childCount: state.results.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
                "Search",
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

  Widget _buildSearchBar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNode.hasFocus
              ? const Color(0xFF0A84FF)
              : Colors.transparent,
          width: 1.4,
        ),
        boxShadow: [
          if (_focusNode.hasFocus)
            BoxShadow(
              color: const Color(0xFF0A84FF).withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: CupertinoSearchTextField(
        controller: _searchController,
        focusNode: _focusNode,
        backgroundColor: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        itemColor: Colors.white54,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        placeholderStyle: const TextStyle(color: Colors.white38, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: const Icon(
          CupertinoIcons.search,
          color: Colors.white54,
          size: 18,
        ),
        suffixIcon: const Icon(
          CupertinoIcons.xmark_circle_fill,
          color: Colors.white30,
          size: 16,
        ),
        placeholder: "Artists, movies, books",
        onSuffixTap: () {
          _searchController.clear();
          context.read<SearchCubit>().search('');
          setState(() {});
        },
        onChanged: (val) {
          context.read<SearchCubit>().search(val);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildFilters(BuildContext context, String activeType) {
    final filters = [
      {'label': 'Movies', 'value': 'movie'},
      {'label': 'Music', 'value': 'music'},
      {'label': 'Books', 'value': 'book'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = activeType == filters[index]['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => context.read<SearchCubit>().setFilter(
                filters[index]['value']!,
                _searchController.text,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index]['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isInitial) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text(
          isInitial ? "Find your next favorite" : "Nothing found",
          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
        ),
      ),
    );
  }
}
