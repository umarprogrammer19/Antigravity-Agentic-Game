import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../../../app/theme.dart';
import '../dungeon_game.dart';

// The prompt asked for:
// class HUDComponent extends Component with HasGameReference
// - Fixed position overlay (top of screen)
// - Does NOT use Flame rendering — this is implemented as Flutter Stack overlay

class HUDComponent extends Component with HasGameReference<DungeonGame> {
  // This component can be used to manage HUD state or logic within the Flame game,
  // but as requested, the actual rendering is done via Flutter Stack overlay.
}

class HUDOverlay extends StatelessWidget {
  final int currentHp;
  final int maxHp;
  final int floorNumber;
  final int turnCount;

  const HUDOverlay({
    super.key,
    required this.currentHp,
    required this.maxHp,
    required this.floorNumber,
    required this.turnCount,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: HP bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HP: $currentHp/$maxHp', style: DungeonText.headingMedium),
              const SizedBox(height: 4),
              Container(
                width: 150,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: DungeonColors.crimson,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Right: Floor & Turn
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Floor $floorNumber/5', style: DungeonText.headingMedium),
              Text('Turn $turnCount', style: DungeonText.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
