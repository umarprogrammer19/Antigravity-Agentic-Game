import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/character_select/character_select_screen.dart';
import '../features/game/game_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/menu/main_menu_screen.dart';
import '../features/traces/trace_viewer_screen.dart';
import '../providers/auth_provider.dart';

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
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: '/character-select',
        builder: (context, state) => const CharacterSelectScreen(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Result Screen'))),
      ),
      GoRoute(
        path: '/traces/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return TraceViewerScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
    ],
  );
});
