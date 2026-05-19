import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../../../../app/theme.dart';
import '../../../../models/enemy_action.dart';
import '../dungeon_game.dart';
import 'tile_map_component.dart';

class EnemyComponent extends PositionComponent with HasGameReference<DungeonGame>, HasPaint {
  final String id;
  final String type;
  int hp;
  int maxHp;
  int attack;
  int defense;
  String behavior;
  bool isAlive = true;

  int gridRow;
  int gridCol;

  EnemyComponent({
    required this.id,
    required this.type,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.behavior,
    required this.gridRow,
    required this.gridCol,
  }) : super(size: Vector2(28, 28));

  @override
  void onLoad() {
    _updateScreenPosition();
    super.onLoad();
  }

  void _updateScreenPosition() {
    position = Vector2(
      gridCol * TileMapComponent.tileSize + 2, // +2 to center 28x28 inside 32x32
      gridRow * TileMapComponent.tileSize + 2,
    );
  }

  void applyAction(EnemyAction action) {
    if (!isAlive) return;

    if (action.actionType == 'move' && action.direction != null) {
      switch (action.direction) {
        case 'up':
          gridRow--;
          break;
        case 'down':
          gridRow++;
          break;
        case 'left':
          gridCol--;
          break;
        case 'right':
          gridCol++;
          break;
      }
      _updateScreenPosition();
    }
  }

  void takeHit(int damage) {
    hp -= damage;
    if (hp <= 0) {
      die();
    }
  }

  void die() {
    isAlive = false;
    add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.4), // 400ms
        onComplete: () {
          removeFromParent();
        },
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, width, height);
    final bgPaint = Paint()..color = DungeonColors.crimson;
    
    // Support opacity fading for death animation
    bgPaint.color = bgPaint.color.withValues(alpha: paint.color.a);
    canvas.drawRect(rect, bgPaint);

    // Letter indicator
    final letter = type.isNotEmpty ? type[0].toUpperCase() : 'E';
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.white.withValues(alpha: paint.color.a),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2),
    );

    // HP indicator
    if (isAlive) {
      final hpBarWidth = width;
      final currentHpWidth = (hp / maxHp) * hpBarWidth;
      
      // Background bar
      final backPaint = Paint()..color = Colors.black.withValues(alpha: paint.color.a);
      canvas.drawRect(Rect.fromLTWH(0, height + 2, hpBarWidth, 4), backPaint);
      
      // Current HP
      final hpPaint = Paint()..color = Colors.redAccent.withValues(alpha: paint.color.a);
      canvas.drawRect(Rect.fromLTWH(0, height + 2, currentHpWidth, 4), hpPaint);
    }
  }
}
