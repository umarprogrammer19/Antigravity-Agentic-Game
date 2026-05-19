import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LEADERBOARD", style: DungeonText.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DungeonSpacing.md),
        child: Column(
          children: [
            _LeaderboardEntry(
              rank: 1,
              name: "DungeonMaster",
              score: 4820,
              subtitle: "Mage · 5 floors",
            ),
            const SizedBox(height: DungeonSpacing.sm),
            _LeaderboardEntry(
              rank: 2,
              name: "ShadowSlayer",
              score: 3640,
              subtitle: "Warrior · 5 floors",
            ),
            const SizedBox(height: DungeonSpacing.sm),
            const Divider(color: DungeonColors.textDim),
            const SizedBox(height: DungeonSpacing.sm),
            _LeaderboardEntry(
              rank: 15,
              name: "YOU",
              score: 1240,
              subtitle: "Warrior · 2 floors",
              isCurrentPlayer: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardEntry extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final String subtitle;
  final bool isCurrentPlayer;

  const _LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.subtitle,
    this.isCurrentPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DungeonSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? DungeonColors.surfaceElevated : DungeonColors.surface,
        borderRadius: const BorderRadius.all(DungeonRadius.md),
        border: isCurrentPlayer ? Border.all(color: DungeonColors.gold) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "#$rank",
              style: DungeonText.headingMedium.copyWith(
                color: isCurrentPlayer ? DungeonColors.gold : DungeonColors.textSecondary,
              ),
            ),
          ),
          if (isCurrentPlayer) ...[
            const Icon(Icons.star, color: DungeonColors.gold, size: 16),
            const SizedBox(width: DungeonSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DungeonText.headingMedium),
                Text(subtitle, style: DungeonText.caption),
              ],
            ),
          ),
          Text(
            score.toString(),
            style: DungeonText.headingMedium.copyWith(color: DungeonColors.gold),
          ),
        ],
      ),
    );
  }
}
