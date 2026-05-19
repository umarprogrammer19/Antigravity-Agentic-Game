import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../../../../app/theme.dart';
import '../../../../models/enemy_action.dart';
import '../dungeon_game.dart';
import 'tile_map_component.dart';

class EnemyComponent extends PositionComponent
    with HasGameReference<DungeonGame>, HasPaint {
  final String id;
  final String type;
  int hp;
  int maxHp;
  int attack;
  int defense;
  String behavior;
  bool isAlive = true;
  bool _isAttacking = false;

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
      gridCol * TileMapComponent.tileSize +
          2, // +2 to center 28x28 inside 32x32
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
      _updateScreenPosition(); // ← CRITICAL: this was missing
    }

    if (action.actionType == 'attack') {
      // Show attack animation — flash brighter
      _isAttacking = true;
      add(
        TimerComponent(
          period: 0.2,
          onTick: () => _isAttacking = false,
          removeOnFinish: true,
        ),
      );
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

    if (!isAlive) return;

    final rect = Rect.fromLTWH(0, 0, width, height);

    // Enemy background — brighter red when attacking
    final color = _isAttacking
        ? const Color(0xFFFF6B6B)
        : DungeonColors.crimson;

    final bgPaint = Paint()..color = color.withValues(alpha: paint.color.a);
    canvas.drawRect(rect, bgPaint);

    // Dark border
    final borderPaint = Paint()
      ..color = const Color(0xFF7F0000).withValues(alpha: paint.color.a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, borderPaint);

    // Enemy type letter
    final letter = type.isNotEmpty ? type[0].toUpperCase() : 'E';
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.white.withValues(alpha: paint.color.a),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    // HP bar below enemy (only when alive)
    final hpRatio = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;
    final barY = height + 2;

    // Background bar
    canvas.drawRect(
      Rect.fromLTWH(0, barY, width, 4),
      Paint()..color = Colors.black45,
    );
    // HP fill
    canvas.drawRect(
      Rect.fromLTWH(0, barY, width * hpRatio, 4),
      Paint()..color = const Color(0xFFEF4444).withValues(alpha: paint.color.a),
    );
  }
}
