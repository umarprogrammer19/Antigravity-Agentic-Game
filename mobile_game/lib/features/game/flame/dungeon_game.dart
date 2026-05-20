import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../models/level_schema.dart';
import '../../../../models/enemy_action.dart';
import 'components/enemy_component.dart';
import 'components/hud_component.dart';
import 'components/player_component.dart';
import 'components/tile_map_component.dart';
import 'game_controller.dart';

enum GameEvent {
  playerMoved,
  playerAttacked,
  playerWaited,
  enemyKilled,
  floorCleared,
  playerDied,
  itemCollected,
}

class DungeonGame extends FlameGame with KeyboardEvents {
  LevelSchema levelSchema;
  final String playerClass;
  int playerHp;
  int playerMaxHp;
  int playerAttack;
  int playerDefense;
  bool inputEnabled = true;
  final void Function(GameEvent, {dynamic data})? onGameEvent;

  late TileMapComponent tileMap;
  late PlayerComponent player;
  late List<EnemyComponent> enemies;
  late HUDComponent hud;
  late GameController gameController;

  DungeonGame({
    required this.levelSchema,
    required this.playerClass,
    required this.playerHp,
    required this.playerMaxHp,
    required this.playerAttack,
    required this.playerDefense,
    this.onGameEvent,
  });

  Future<void> loadLevel(LevelSchema newLevel) async {
    levelSchema = newLevel;

    final toRemove = <Component>[];
    if (tileMap.parent != null) toRemove.add(tileMap);
    if (player.parent != null) toRemove.add(player);
    for (final enemy in enemies) {
      if (enemy.parent != null) toRemove.add(enemy);
    }
    if (hud.parent != null) toRemove.add(hud);

    removeAll(toRemove);
    await _loadComponents();
  }

  void syncPlayerStats({
    required int hp,
    required int maxHp,
    required int attack,
    required int defense,
  }) {
    playerHp = hp;
    playerMaxHp = maxHp;
    playerAttack = attack;
    playerDefense = defense;
  }

  void applyEnemyAction(EnemyAction action) {
    final enemy = enemies.where((e) => e.id == action.enemyId).firstOrNull;
    if (enemy == null || !enemy.isAlive) return;

    enemy.applyAction(action);
  }

  List<int>? enemyMoveTarget(EnemyAction action) {
    if (action.actionType != 'move' || action.direction == null) return null;

    final enemy = enemies.where((e) => e.id == action.enemyId).firstOrNull;
    if (enemy == null || !enemy.isAlive) return null;

    return gameController.getAdjacentPosition([
      enemy.gridRow,
      enemy.gridCol,
    ], action.direction!);
  }

  bool isEnemyMoveAllowed(EnemyAction action) {
    final target = enemyMoveTarget(action);
    if (target == null) return false;

    if (target[0] == player.gridRow && target[1] == player.gridCol) {
      return false;
    }

    if (!gameController.isTileWalkable(
      target[0],
      target[1],
      levelSchema.grid,
    )) {
      return false;
    }

    return gameController.isEnemy(target, enemies) == null;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadComponents();
  }

  Future<void> _loadComponents() async {
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
      hp: playerHp,
      maxHp: playerMaxHp,
      attack: playerAttack,
      defense: playerDefense,
      playerClass: playerClass,
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
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      String? direction;

      if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
          keysPressed.contains(LogicalKeyboardKey.keyW)) {
        direction = 'up';
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
          keysPressed.contains(LogicalKeyboardKey.keyS)) {
        direction = 'down';
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
          keysPressed.contains(LogicalKeyboardKey.keyA)) {
        direction = 'left';
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
          keysPressed.contains(LogicalKeyboardKey.keyD)) {
        direction = 'right';
      }

      if (direction != null) {
        handlePlayerMove(direction);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void handlePlayerMove(String direction) {
    if (!inputEnabled) return;

    final targetPos = gameController.getAdjacentPosition([
      player.gridRow,
      player.gridCol,
    ], direction);

    if (!gameController.isTileWalkable(
      targetPos[0],
      targetPos[1],
      levelSchema.grid,
    )) {
      return; // Hit a wall — do nothing
    }

    final enemyAtTarget = gameController.isEnemy(targetPos, enemies);
    if (enemyAtTarget != null && enemyAtTarget.isAlive) {
      // PLAYER ATTACKS ENEMY
      final effectiveAttack = player.playerClass == 'warrior'
          ? (player.attack * 1.5).round()
          : player.attack;
      final damage = gameController.computeDamage(
        effectiveAttack,
        enemyAtTarget.defense,
      );
      enemyAtTarget.takeHit(damage);
      // Trigger visual attack flash on player
      player.showAttack();
      // Fire event with damage info
      onGameEvent?.call(
        GameEvent.playerAttacked,
        data: {
          'direction': direction,
          'target': targetPos,
          'damage': damage,
          'enemyId': enemyAtTarget.id,
          'enemyKilled': !enemyAtTarget.isAlive,
          'xpGained': enemyAtTarget.maxHp ~/ 5,
        },
      );
    } else {
      player.move(direction);

      // Check exit
      if (player.gridRow == levelSchema.exitPosition[0] &&
          player.gridCol == levelSchema.exitPosition[1]) {
        onGameEvent?.call(
          GameEvent.floorCleared,
          data: {
            'position': [player.gridRow, player.gridCol],
          },
        );
        return;
      }

      onGameEvent?.call(GameEvent.playerMoved, data: {'direction': direction});

      // Check items
      for (var item in levelSchema.items) {
        if (player.gridRow == item.position[0] &&
            player.gridCol == item.position[1]) {
          onGameEvent?.call(GameEvent.itemCollected, data: {'item': item.id});
        }
      }
    }
  }

  void handleAttackAction() {
    if (!inputEnabled) return;

    final playerPos = [player.gridRow, player.gridCol];
    EnemyComponent? target;
    String attackDir = 'up';

    if (player.playerClass == 'mage') {
      // Mage: UP TO 2 tiles away, straight line
      final candidates = enemies.where((e) {
        if (!e.isAlive) return false;
        final dr = (e.gridRow - playerPos[0]).abs();
        final dc = (e.gridCol - playerPos[1]).abs();
        return (dr == 0 && dc <= 2 && dc > 0) || (dc == 0 && dr <= 2 && dr > 0);
      }).toList();
      
      if (candidates.isNotEmpty) {
        candidates.sort((a, b) {
          final distA = (a.gridRow - playerPos[0]).abs() + (a.gridCol - playerPos[1]).abs();
          final distB = (b.gridRow - playerPos[0]).abs() + (b.gridCol - playerPos[1]).abs();
          return distA.compareTo(distB); // closest first
        });
        target = candidates.first;
      }
    } else if (player.playerClass == 'ranger') {
      // Ranger: 1 tile range, diagonal allowed
      final candidates = enemies.where((e) {
        if (!e.isAlive) return false;
        final dr = (e.gridRow - playerPos[0]).abs();
        final dc = (e.gridCol - playerPos[1]).abs();
        return dr <= 1 && dc <= 1 && !(dr == 0 && dc == 0);
      }).toList();

      if (candidates.isNotEmpty) {
        target = candidates.first;
      }
    } else {
      // Warrior: adjacent orthogonal only
      final candidates = enemies.where((e) {
        if (!e.isAlive) return false;
        final dr = (e.gridRow - playerPos[0]).abs();
        final dc = (e.gridCol - playerPos[1]).abs();
        return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
      }).toList();

      if (candidates.isNotEmpty) {
        target = candidates.first;
      }
    }

    if (target != null) {
      // Determine logical direction for animation/event
      if (target.gridRow < playerPos[0]) attackDir = 'up';
      else if (target.gridRow > playerPos[0]) attackDir = 'down';
      else if (target.gridCol < playerPos[1]) attackDir = 'left';
      else if (target.gridCol > playerPos[1]) attackDir = 'right';

      final effectiveAttack = player.playerClass == 'warrior'
          ? (player.attack * 1.5).round()
          : player.attack;
      final damage = gameController.computeDamage(
        effectiveAttack,
        target.defense,
      );
      target.takeHit(damage);
      player.showAttack();

      onGameEvent?.call(
        GameEvent.playerAttacked,
        data: {
          'direction': attackDir,
          'target': [target.gridRow, target.gridCol],
          'damage': damage,
          'enemyId': target.id,
          'enemyKilled': !target.isAlive,
          'xpGained': target.maxHp ~/ 5,
        },
      );
    } else {
      // If no target in range, just wait
      onGameEvent?.call(GameEvent.playerWaited, data: {'direction': 'wait'});
    }
  }
}
