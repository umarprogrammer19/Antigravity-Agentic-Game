import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/empty_state_card.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("DUNGEONMIND", style: DungeonText.headingMedium),
        leading: Semantics(
          button: true,
          label: "Sign out",
          child: IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sign out",
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ),
      ),
      body: playerAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DungeonColors.gold),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(DungeonSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: DungeonColors.crimson,
                  size: 48,
                ),
                const SizedBox(height: DungeonSpacing.md),
                Text(
                  "Could not load your profile.",
                  style: DungeonText.bodyMedium.copyWith(
                    color: DungeonColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DungeonSpacing.md),
                ElevatedButton(
                  onPressed: () => ref.invalidate(playerProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DungeonColors.gold,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text("RETRY"),
                ),
              ],
            ),
          ),
        ),
        data: (player) => _MenuBody(player: player),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DungeonColors.surfaceElevated,
        title: Text("Sign Out", style: DungeonText.headingMedium),
        content: Text(
          "Are you sure you want to sign out?",
          style: DungeonText.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: TextStyle(color: DungeonColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DungeonColors.crimson,
            ),
            child: const Text("SIGN OUT"),
          ),
        ],
      ),
    );
  }
}

class _MenuBody extends StatelessWidget {
  final PlayerModel player;

  const _MenuBody({required this.player});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DungeonSpacing.lg),
      child: Column(
        children: [
          // Player stats card
          _PlayerStatsCard(player: player),
          const SizedBox(height: DungeonSpacing.xl),

          // NEW RUN button
          Semantics(
            button: true,
            label: "Start a new dungeon run",
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/character-select');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A0A00), Color(0xFF2D1500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: DungeonColors.gold, width: 1.5),
                  borderRadius: const BorderRadius.all(DungeonRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: DungeonColors.gold,
                      size: 28,
                    ),
                    const SizedBox(width: DungeonSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "NEW RUN",
                          style: DungeonText.headingMedium.copyWith(
                            color: DungeonColors.gold,
                          ),
                        ),
                        Text(
                          "Your Dungeon Master is ready…",
                          style: DungeonText.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: DungeonSpacing.lg),

          // Secondary buttons
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: "View last run",
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.history,
                      color: DungeonColors.textPrimary,
                    ),
                    label: const Text("LAST RUN"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DungeonColors.textPrimary,
                      side: const BorderSide(color: DungeonColors.textDim),
                      padding: const EdgeInsets.symmetric(
                        vertical: DungeonSpacing.md,
                      ),
                    ),
                    onPressed: () {
                      // TODO: navigate to last session traces
                    },
                  ),
                ),
              ),
              const SizedBox(width: DungeonSpacing.md),
              Expanded(
                child: Semantics(
                  button: true,
                  label: "View leaderboard",
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.emoji_events,
                      color: DungeonColors.textPrimary,
                    ),
                    label: const Text("RANKS"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DungeonColors.textPrimary,
                      side: const BorderSide(color: DungeonColors.textDim),
                      padding: const EdgeInsets.symmetric(
                        vertical: DungeonSpacing.md,
                      ),
                    ),
                    onPressed: () => context.push('/leaderboard'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DungeonSpacing.lg),

          // Last run card – empty state
          _LastRunCard(),
        ],
      ),
    );
  }
}

class _PlayerStatsCard extends StatelessWidget {
  final PlayerModel player;

  const _PlayerStatsCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DungeonSpacing.md),
      decoration: BoxDecoration(
        color: DungeonColors.surfaceElevated,
        borderRadius: const BorderRadius.all(DungeonRadius.md),
        border: Border.all(color: DungeonColors.goldDim.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${(player.playerClass ?? 'Adventurer').toUpperCase()} ${player.displayName.toUpperCase()}",
            style: DungeonText.headingMedium,
          ),
          const SizedBox(height: DungeonSpacing.xs),
          Row(
            children: [
              const Icon(Icons.star, color: DungeonColors.gold, size: 16),
              const SizedBox(width: DungeonSpacing.xs),
              Text(
                "High Score: ${_formatNumber(player.highScore)}",
                style: DungeonText.bodyMedium.copyWith(
                  color: DungeonColors.gold,
                ),
              ),
            ],
          ),
          const Divider(
            color: DungeonColors.textDim,
            height: DungeonSpacing.lg,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Wins: ${player.wins}", style: DungeonText.bodyMedium),
              Container(width: 1, height: 16, color: DungeonColors.textDim),
              Text("Losses: ${player.losses}", style: DungeonText.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return "${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k";
    }
    return n.toString();
  }
}

class _LastRunCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: integrate with actual last-session data
    return const EmptyStateCard(
      icon: Icons.play_circle_outline,
      title: "No runs yet",
      description: "Start your first dungeon adventure!",
    );
  }
}
