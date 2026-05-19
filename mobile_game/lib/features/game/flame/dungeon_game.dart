import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../models/level_schema.dart';
import 'components/enemy_component.dart';
import 'components/hud_component.dart';
import 'components/player_component.dart';
import 'components/tile_map_component.dart';
import 'game_controller.dart';

enum GameEvent {
  playerMoved,
  playerAttacked,
  enemyKilled,
  floorCleared,
  playerDied,
  itemCollected,
}

class DungeonGame extends FlameGame with KeyboardEvents {
  final LevelSchema levelSchema;
  final void Function(GameEvent, {dynamic data})? onGameEvent;

  late TileMapComponent tileMap;
  late PlayerComponent player;
  late List<EnemyComponent> enemies;
  late HUDComponent hud;
  late GameController gameController;

  DungeonGame({
    required this.levelSchema,
    this.onGameEvent,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    gameController = GameController(levelSchema, (action) {
      // Typically used for local validation
    });

    // 1. TileMap
    tileMap = TileMapComponent(levelSchema);
    await add(tileMap);

    // 2. Player
    player = PlayerComponent(
      gridRow: levelSchema.playerStart[0],
      gridCol: levelSchema.playerStart[1],
      hp: 150, // These would normally come from PlayerState
      maxHp: 150,
      attack: 20,
      defense: 8,
      playerClass: levelSchema.theme, // Fallback placeholder
    );
    await add(player);

    // 3. Enemies
    enemies = [];
    for (var enemySpec in levelSchema.enemies) {
      final enemy = EnemyComponent(
        id: enemySpec.id,
        type: enemySpec.type,
        hp: enemySpec.hp,
        maxHp: enemySpec.maxHp,
        attack: enemySpec.attack,
        defense: enemySpec.defense,
        behavior: enemySpec.behavior,
        gridRow: enemySpec.position[0],
        gridCol: enemySpec.position[1],
      );
      enemies.add(enemy);
      await add(enemy);
    }

    // 4. HUD Component (Internal state/logic representation)
    hud = HUDComponent();
    await add(hud);

    // Camera follow player
    camera.follow(player);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      String? direction;
      
      if (keysPressed.contains(LogicalKeyboardKey.arrowUp) || keysPressed.contains(LogicalKeyboardKey.keyW)) {
        direction = 'up';
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) || keysPressed.contains(LogicalKeyboardKey.keyS)) {
        direction = 'down';
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) || keysPressed.contains(LogicalKeyboardKey.keyA)) {
        direction = 'left';
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD)) {
        direction = 'right';
      }

      if (direction != null) {
        _handlePlayerMove(direction);
        return KeyEventResult.handled;
      }
    }
    
    return KeyEventResult.ignored;
  }

  void _handlePlayerMove(String direction) {
    final targetPos = gameController.getAdjacentPosition([player.gridRow, player.gridCol], direction);
    
    // Validate bounds and wall
    if (!gameController.isTileWalkable(targetPos[0], targetPos[1], levelSchema.grid)) {
      return;
    }

    // Check if enemy is there
    final enemyAtTarget = gameController.isEnemy(targetPos, enemies);
    if (enemyAtTarget != null) {
      // Attack!
      onGameEvent?.call(GameEvent.playerAttacked, data: {'direction': direction, 'target': targetPos});
      // (Actual damage application would happen via API -> ActionResult update)
    } else {
      // Move!
      player.move(direction);
      onGameEvent?.call(GameEvent.playerMoved, data: {'direction': direction});

      // Check exit
      if (player.gridRow == levelSchema.exitPosition[0] && player.gridCol == levelSchema.exitPosition[1]) {
        onGameEvent?.call(GameEvent.floorCleared);
      }
      
      // Check items
      for (var item in levelSchema.items) {
        if (player.gridRow == item.position[0] && player.gridCol == item.position[1]) {
          onGameEvent?.call(GameEvent.itemCollected, data: {'item': item.id});
          // Typically we'd remove it, but rely on updated LevelSchema/GameState to re-render
        }
      }
    }
  }
}
