import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Fixed-position HUD overlay showing HP bar, floor, and turn count.
/// Sits at the top of the game screen above the Flame canvas.
class HUDOverlay extends StatelessWidget {
  final int currentHp;
  final int maxHp;
  final int floorNumber;
  final int turnCount;
  final VoidCallback? onPauseTap;

  const HUDOverlay({
    super.key,
    required this.currentHp,
    required this.maxHp,
    required this.floorNumber,
    required this.turnCount,
    this.onPauseTap,
  });

  @override
  Widget build(BuildContext context) {
    final hpRatio = maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0.0;
    final hpColor = hpRatio > 0.5
        ? DungeonColors.emerald
        : hpRatio > 0.25
        ? DungeonColors.amber
        : DungeonColors.crimsonLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DungeonColors.surface.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.all(DungeonRadius.sm),
      ),
      child: Row(
        children: [
          // HP Heart icon
          const Icon(
            Icons.favorite,
            color: DungeonColors.crimsonLight,
            size: 18,
          ),
          const SizedBox(width: 6),

          // HP Bar + Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: hpRatio, end: hpRatio),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    builder: (context, value, _) {
                      return SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: DungeonColors.textDim,
                          valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$currentHp / $maxHp",
                  style: DungeonText.caption.copyWith(
                    color: hpColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Floor & Turn
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Floor $floorNumber",
                style: DungeonText.caption.copyWith(
                  color: DungeonColors.textPrimary,
                ),
              ),
              Text("Turn $turnCount", style: DungeonText.caption),
            ],
          ),

          // Pause button
          if (onPauseTap != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.pause,
                  color: DungeonColors.textSecondary,
                  size: 20,
                ),
                tooltip: "Pause",
                onPressed: onPauseTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
