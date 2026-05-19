import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../../../app/theme.dart';
import '../dungeon_game.dart';
import 'tile_map_component.dart';

class PlayerComponent extends PositionComponent with HasGameReference<DungeonGame> {
  int gridRow;
  int gridCol;
  int hp;
  int maxHp;
  int attack;
  int defense;
  String playerClass;

  bool _isFlashing = false;

  PlayerComponent({
    required this.gridRow,
    required this.gridCol,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.playerClass,
  }) : super(size: Vector2(30, 30));

  @override
  void onLoad() {
    _updateScreenPosition();
    super.onLoad();
  }

  void _updateScreenPosition() {
    position = Vector2(
      gridCol * TileMapComponent.tileSize + 1, // +1 to center slightly within 32x32 tile
      gridRow * TileMapComponent.tileSize + 1,
    );
  }

  void move(String direction) {
    int targetRow = gridRow;
    int targetCol = gridCol;

    switch (direction) {
      case 'up':
        targetRow--;
        break;
      case 'down':
        targetRow++;
        break;
      case 'left':
        targetCol--;
        break;
      case 'right':
        targetCol++;
        break;
    }

    final grid = game.levelSchema.grid;
    if (targetRow >= 0 && targetRow < grid.length && targetCol >= 0 && targetCol < grid[targetRow].length) {
      final tile = grid[targetRow][targetCol];
      // Cannot move into wall (0)
      if (tile != 0) {
        gridRow = targetRow;
        gridCol = targetCol;
        _updateScreenPosition();
      }
    }
  }

  void takeHit() {
    _isFlashing = true;
    add(
      TimerComponent(
        period: 0.2, // 200ms
        onTick: () {
          _isFlashing = false;
        },
        removeOnFinish: true,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, width, height);

    // Inner square
    final paint = Paint()..color = _isFlashing ? DungeonColors.crimson : DungeonColors.sapphire;
    canvas.drawRect(rect, paint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, borderPaint);
  }
}
