import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DUNGEONMIND", style: DungeonText.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(authProvider.notifier).signOut(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DungeonSpacing.lg),
        child: Column(
          children: [
            // Player stats card
            Container(
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
                    "WARRIOR SALMAN",
                    style: DungeonText.headingMedium,
                  ),
                  const SizedBox(height: DungeonSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.star, color: DungeonColors.gold, size: 16),
                      const SizedBox(width: DungeonSpacing.xs),
                      Text(
                        "High Score: 0",
                        style: DungeonText.bodyMedium.copyWith(color: DungeonColors.gold),
                      ),
                    ],
                  ),
                  const Divider(color: DungeonColors.textDim, height: DungeonSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("Wins: 0", style: DungeonText.bodyMedium),
                      Container(width: 1, height: 16, color: DungeonColors.textDim),
                      Text("Losses: 0", style: DungeonText.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DungeonSpacing.xl),
            
            // NEW RUN button
            GestureDetector(
              onTap: () => context.push('/character-select'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                    const Icon(Icons.play_circle_outline, color: DungeonColors.gold, size: 28),
                    const SizedBox(width: DungeonSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "NEW RUN",
                          style: DungeonText.headingMedium.copyWith(color: DungeonColors.gold),
                        ),
                        Text(
                          "Your Dungeon Master is ready...",
                          style: DungeonText.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DungeonSpacing.lg),
            
            // Secondary buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history, color: DungeonColors.textPrimary),
                    label: const Text("LAST RUN"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DungeonColors.textPrimary,
                      side: const BorderSide(color: DungeonColors.textDim),
                      padding: const EdgeInsets.symmetric(vertical: DungeonSpacing.md),
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: DungeonSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.emoji_events, color: DungeonColors.textPrimary),
                    label: const Text("RANKS"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DungeonColors.textPrimary,
                      side: const BorderSide(color: DungeonColors.textDim),
                      padding: const EdgeInsets.symmetric(vertical: DungeonSpacing.md),
                    ),
                    onPressed: () => context.push('/leaderboard'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DungeonSpacing.lg),
            
            // Last run placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DungeonSpacing.md),
              decoration: BoxDecoration(
                color: DungeonColors.surfaceElevated,
                borderRadius: const BorderRadius.all(DungeonRadius.md),
                border: Border.all(color: DungeonColors.textDim),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Last Run Summary", style: DungeonText.headingMedium),
                  const SizedBox(height: DungeonSpacing.sm),
                  Text("No runs yet", style: DungeonText.bodyMedium.copyWith(color: DungeonColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
