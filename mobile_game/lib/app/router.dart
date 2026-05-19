import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/character_select/character_select_screen.dart';
import '../features/game/game_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/menu/main_menu_screen.dart';
import '../features/result/post_game_screen.dart';
import '../features/traces/trace_viewer_screen.dart';
import '../providers/auth_provider.dart';

/// Fade transition page used by all routes for smooth screen changes.
CustomTransitionPage<void> _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (authState.isLoading) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/menu';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            _fadeTransitionPage(key: state.pageKey, child: const AuthScreen()),
      ),
      GoRoute(
        path: '/menu',
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const MainMenuScreen(),
        ),
      ),
      GoRoute(
        path: '/character-select',
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const CharacterSelectScreen(),
        ),
      ),
      GoRoute(
        path: '/game',
        pageBuilder: (context, state) =>
            _fadeTransitionPage(key: state.pageKey, child: const GameScreen()),
      ),
      GoRoute(
        path: '/result',
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: PostGameScreen(args: state.extra as PostGameArgs),
        ),
      ),
      GoRoute(
        path: '/traces/:sessionId',
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return _fadeTransitionPage(
            key: state.pageKey,
            child: TraceViewerScreen(sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: '/leaderboard',
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const LeaderboardScreen(),
        ),
      ),
    ],
  );
});
