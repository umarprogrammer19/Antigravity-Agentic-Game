import '../../providers/game_state_provider.dart';
import '../../models/enemy_action.dart';

class LocalAIEngine {
  static EnemyAction getEnemyDecision({
    required Map<String, dynamic> enemyState,
    required PlayerState playerState,
    required Map<String, dynamic> boardState,
  }) {
    final enemyId = enemyState['id'] as String;
    final behavior = enemyState['behavior'] as String? ?? 'rush_melee';
    final position = List<int>.from(enemyState['position'] as List);
    final distance = _getDistance(position, playerState.position);

    // Default tactics response
    final defaultTactics = PlayerTacticsProfile(
      prefersMelee: false,
      prefersRanged: false,
      retreatsWhenLowHp: false,
      cornersPreference: false,
      turnsObserved: playerState.turnCount,
    );

    // 1. Check slow_tank
    if (behavior == 'slow_tank' && playerState.turnCount % 2 != 0) {
      return EnemyAction(
        enemyId: enemyId,
        actionType: 'wait',
        reasoning: 'Slow tank is resting this turn.',
        updatedTactics: defaultTactics,
      );
    }

    // 2. Check ranged_2tile or flee_then_attack
    if (behavior == 'ranged_2tile' || behavior == 'flee_then_attack') {
      if (distance == 1) {
        // Flee
        final fleeDir = _stepAway(position, playerState.position, boardState);
        if (fleeDir != null) {
          return EnemyAction(
            enemyId: enemyId,
            actionType: 'move',
            direction: fleeDir,
            reasoning: 'Moving away to maintain distance.',
            updatedTactics: defaultTactics,
          );
        } else {
          // Trapped, attack
          return _attack(enemyState, playerState, 'Trapped! Attacking in panic.', defaultTactics);
        }
      } else if (distance == 2) {
        // Attack range
        return _attack(enemyState, playerState, 'Attacking from a distance.', defaultTactics);
      } else {
        // Move closer
        final approachDir = _stepToward(position, playerState.position, boardState);
        return EnemyAction(
          enemyId: enemyId,
          actionType: approachDir != null ? 'move' : 'wait',
          direction: approachDir,
          reasoning: approachDir != null ? 'Moving into range.' : 'No path available.',
          updatedTactics: defaultTactics,
        );
      }
    }

    // 3. hit_and_run
    if (behavior == 'hit_and_run') {
      if (distance == 1) {
        // We will attack, then we'd ideally flee next turn. We just attack now.
        return _attack(enemyState, playerState, 'Hit and run strike!', defaultTactics);
      } else {
        // Move closer
        final approachDir = _stepToward(position, playerState.position, boardState);
        return EnemyAction(
          enemyId: enemyId,
          actionType: approachDir != null ? 'move' : 'wait',
          direction: approachDir,
          reasoning: approachDir != null ? 'Darting in for an attack.' : 'Blocked.',
          updatedTactics: defaultTactics,
        );
      }
    }

    // 4. Default melee (rush_melee, tank_melee, swarm_melee)
    if (distance == 1) {
      return _attack(enemyState, playerState, 'Engaging in melee combat.', defaultTactics);
    }

    final dir = _stepToward(position, playerState.position, boardState);
    return EnemyAction(
      enemyId: enemyId,
      actionType: dir != null ? 'move' : 'wait',
      direction: dir,
      reasoning: dir != null ? 'Advancing towards player.' : 'Waiting for an opening.',
      updatedTactics: defaultTactics,
    );
  }

  static int _getDistance(List<int> a, List<int> b) {
    return (a[0] - b[0]).abs() + (a[1] - b[1]).abs();
  }

  static EnemyAction _attack(
    Map<String, dynamic> enemy,
    PlayerState player,
    String reasoning,
    PlayerTacticsProfile tactics,
  ) {
    final enemyAttack = enemy['attack'] as int? ?? 1;
    final damage = (enemyAttack - player.defense).clamp(1, enemyAttack).toInt();
    return EnemyAction(
      enemyId: enemy['id'] as String,
      actionType: 'attack',
      targetPosition: player.position,
      damage: damage,
      reasoning: reasoning,
      updatedTactics: tactics,
    );
  }

  static String? _stepToward(
    List<int> from,
    List<int> to,
    Map<String, dynamic> boardState,
  ) {
    final primaryVertical = (to[0] - from[0]).abs() >= (to[1] - from[1]).abs();
    final candidates = <MapEntry<String, List<int>>>[
      if (primaryVertical)
        MapEntry(to[0] < from[0] ? 'up' : 'down', [
          to[0] < from[0] ? from[0] - 1 : from[0] + 1,
          from[1],
        ]),
      if (!primaryVertical)
        MapEntry(to[1] < from[1] ? 'left' : 'right', [
          from[0],
          to[1] < from[1] ? from[1] - 1 : from[1] + 1,
        ]),
      MapEntry('up', [from[0] - 1, from[1]]),
      MapEntry('down', [from[0] + 1, from[1]]),
      MapEntry('left', [from[0], from[1] - 1]),
      MapEntry('right', [from[0], from[1] + 1]),
    ];
    return _findValidStep(candidates, boardState, to);
  }

  static String? _stepAway(
    List<int> from,
    List<int> to,
    Map<String, dynamic> boardState,
  ) {
    // Reverse the primary logic
    final primaryVertical = (to[0] - from[0]).abs() >= (to[1] - from[1]).abs();
    final candidates = <MapEntry<String, List<int>>>[
      if (primaryVertical)
        MapEntry(to[0] < from[0] ? 'down' : 'up', [
          to[0] < from[0] ? from[0] + 1 : from[0] - 1,
          from[1],
        ]),
      if (!primaryVertical)
        MapEntry(to[1] < from[1] ? 'right' : 'left', [
          from[0],
          to[1] < from[1] ? from[1] + 1 : from[1] - 1,
        ]),
      MapEntry('up', [from[0] - 1, from[1]]),
      MapEntry('down', [from[0] + 1, from[1]]),
      MapEntry('left', [from[0], from[1] - 1]),
      MapEntry('right', [from[0], from[1] + 1]),
    ];
    return _findValidStep(candidates, boardState, to);
  }

  static String? _findValidStep(
    List<MapEntry<String, List<int>>> candidates,
    Map<String, dynamic> boardState,
    List<int> playerPos,
  ) {
    final grid = boardState['grid'] as List;
    final occupied = (boardState['all_enemy_positions'] as List)
        .map((e) => List<int>.from(e as List))
        .toList();

    for (final entry in candidates) {
      final r = entry.value[0];
      final c = entry.value[1];
      if (r < 0 || r >= grid.length) continue;
      final row = grid[r] as List;
      if (c < 0 || c >= row.length || row[c] == 0) continue;
      // Cannot move onto another enemy
      if (occupied.any((p) => p[0] == r && p[1] == c)) continue;
      // Cannot move onto the player's tile
      if (r == playerPos[0] && c == playerPos[1]) continue;
      return entry.key;
    }
    return null;
  }
}
