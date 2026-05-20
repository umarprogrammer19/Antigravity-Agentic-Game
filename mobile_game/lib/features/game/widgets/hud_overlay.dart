import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Compact, fixed-position HUD overlay showing animated HP bar, floor, and turn count.
/// Sits at the top of the game screen above the Flame canvas without overlapping the game grid.
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

    final hpColor = hpRatio > 0.6
        ? const Color(0xFF22C55E) // Green
        : hpRatio > 0.3
        ? const Color(0xFFF59E0B) // Yellow/amber
        : const Color(0xFFEF4444); // Red (danger)

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        border: const Border(
          bottom: BorderSide(color: DungeonColors.goldDim, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Heart icon
          Icon(Icons.favorite, color: hpColor, size: 16),
          const SizedBox(width: 6),

          // HP bar + number
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated HP bar
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: hpRatio, end: hpRatio),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(hpColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$currentHp / $maxHp',
                  style: TextStyle(
                    fontSize: 10,
                    color: hpColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Floor + Turn
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Floor $floorNumber/5',
                style: const TextStyle(
                  fontSize: 11,
                  color: DungeonColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Turn $turnCount',
                style: const TextStyle(
                  fontSize: 10,
                  color: DungeonColors.textSecondary,
                ),
              ),
            ],
          ),

          // Pause button
          if (onPauseTap != null)
            IconButton(
              padding: const EdgeInsets.only(left: 8),
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.pause,
                color: DungeonColors.textDim,
                size: 18,
              ),
              onPressed: onPauseTap,
            ),
        ],
      ),
    );
  }
}
