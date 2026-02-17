import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Core
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';

// Data
import 'data/repositories_impl/auth_repository_impl.dart';
import 'data/repositories_impl/content_repository_impl.dart';
import 'data/repositories_impl/playlist_repository_impl.dart';

import 'domain/repositories/user_repository.dart';
import 'data/repositories_impl/user_repository_impl.dart';

import 'package:omnisource/domain/repositories/auth_repository.dart';

// Bloc
import 'presentation/bloc/auth/auth_cubit.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/home/home_cubit.dart';
import 'presentation/bloc/search/search_cubit.dart';
import 'presentation/bloc/library/library_cubit.dart';

// Screens
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/onboarding/interests_screen.dart';
import 'presentation/screens/main_layout/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // init ApiClient
  final apiClient = ApiClient();

  runApp(
    // 1. data layer
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(apiClient.dio),
        ),
        RepositoryProvider<UserRepository>(
          create: (context) => UserRepositoryImpl(apiClient),
        ),
        RepositoryProvider<ContentRepositoryImpl>(
          create: (context) => ContentRepositoryImpl(apiClient.dio),
        ),
        RepositoryProvider<PlaylistRepositoryImpl>(
          create: (context) => PlaylistRepositoryImpl(apiClient.dio),
        ),
      ],
      // 2. cubit layer
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthCubit(context.read<AuthRepository>())..checkAuth(),
          ),
          BlocProvider(
            create: (context) =>
                HomeCubit(context.read<ContentRepositoryImpl>())..loadContent(),
          ),
          BlocProvider(
            create: (context) =>
                SearchCubit(context.read<ContentRepositoryImpl>()),
          ),
          BlocProvider(
            create: (context) =>
                LibraryCubit(context.read<ContentRepositoryImpl>()),
          ),
        ],
        child: const OmniSourceApp(),
      ),
    ),
  );
}

class OmniSourceApp extends StatelessWidget {
  const OmniSourceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniSource AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.needsOnboarding) {
              return const InterestsSelectionScreen();
            }
            // if tags already choosed go to main layout
            return const MainLayout();
          }

          // loading spinner
          if (state is AuthLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF0984E3)),
              ),
            );
          }

          // if not authorized
          return const LoginScreen();
        },
      ),
    );
  }
}
