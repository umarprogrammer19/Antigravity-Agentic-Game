import 'package:flutter_riverpod/legacy.dart';
import '../models/action_result.dart';
import '../models/level_schema.dart';
import '../models/trace_entry.dart';

enum GameStatus {
  loading,
  playing,
  enemyTurn,
  floorCleared,
  gameOverWin,
  gameOverLose,
  paused,
}

enum TurnPhase { playerTurn, processing, enemyTurn, animating, transition }

class PlayerState {
  final String playerId;
  final String playerClass;
  final List<int> position;
  final int hp;
  final int maxHp;
  final int attack;
  final int defense;
  final int turnCount;
  final int floorsCleared;
  final int enemiesKilled;
  final int score;
  final bool specialUsed;
  final List<String> inventory;
  final Map<String, dynamic> activeBuffs;

  PlayerState({
    required this.playerId,
    required this.playerClass,
    required this.position,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.turnCount,
    required this.floorsCleared,
    required this.enemiesKilled,
    required this.score,
    required this.specialUsed,
    required this.inventory,
    required this.activeBuffs,
  });

  PlayerState copyWith({
    String? playerId,
    String? playerClass,
    List<int>? position,
    int? hp,
    int? maxHp,
    int? attack,
    int? defense,
    int? turnCount,
    int? floorsCleared,
    int? enemiesKilled,
    int? score,
    bool? specialUsed,
    List<String>? inventory,
    Map<String, dynamic>? activeBuffs,
  }) {
    return PlayerState(
      playerId: playerId ?? this.playerId,
      playerClass: playerClass ?? this.playerClass,
      position: position ?? this.position,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      turnCount: turnCount ?? this.turnCount,
      floorsCleared: floorsCleared ?? this.floorsCleared,
      enemiesKilled: enemiesKilled ?? this.enemiesKilled,
      score: score ?? this.score,
      specialUsed: specialUsed ?? this.specialUsed,
      inventory: inventory ?? this.inventory,
      activeBuffs: activeBuffs ?? this.activeBuffs,
    );
  }

  Map<String, dynamic> toJson() => {
    'player_id': playerId,
    'player_class': playerClass,
    'position': position,
    'hp': hp,
    'max_hp': maxHp,
    'attack': attack,
    'defense': defense,
    'turn_count': turnCount,
    'floors_cleared': floorsCleared,
    'enemies_killed': enemiesKilled,
    'score': score,
    'special_used': specialUsed,
    'inventory': inventory,
    'active_buffs': activeBuffs,
  };
}

class GameState {
  final GameStatus status;
  final LevelSchema? currentLevel;
  final PlayerState? playerState;
  final List<Map<String, dynamic>> enemies;
  final List<Map<String, dynamic>> items;
  final TurnPhase turnPhase;
  final ActionResult? lastActionResult;
  final bool aiIsThinking;
  final String? aiLastDecision;
  final List<TraceEntry> sessionTraces;

  GameState({
    this.status = GameStatus.loading,
    this.currentLevel,
    this.playerState,
    this.enemies = const [],
    this.items = const [],
    this.turnPhase = TurnPhase.playerTurn,
    this.lastActionResult,
    this.aiIsThinking = false,
    this.aiLastDecision,
    this.sessionTraces = const [],
  });

  GameState copyWith({
    GameStatus? status,
    LevelSchema? currentLevel,
    PlayerState? playerState,
    List<Map<String, dynamic>>? enemies,
    List<Map<String, dynamic>>? items,
    TurnPhase? turnPhase,
    ActionResult? lastActionResult,
    bool? aiIsThinking,
    String? aiLastDecision,
    List<TraceEntry>? sessionTraces,
  }) {
    return GameState(
      status: status ?? this.status,
      currentLevel: currentLevel ?? this.currentLevel,
      playerState: playerState ?? this.playerState,
      enemies: enemies ?? this.enemies,
      items: items ?? this.items,
      turnPhase: turnPhase ?? this.turnPhase,
      lastActionResult: lastActionResult ?? this.lastActionResult,
      aiIsThinking: aiIsThinking ?? this.aiIsThinking,
      aiLastDecision: aiLastDecision ?? this.aiLastDecision,
      sessionTraces: sessionTraces ?? this.sessionTraces,
    );
  }
}

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier()
    : super(
        GameState(
          playerState: PlayerState(
            playerId: "",
            playerClass: "warrior",
            position: [0, 0],
            hp: 100,
            maxHp: 100,
            attack: 10,
            defense: 5,
            turnCount: 0,
            floorsCleared: 0,
            enemiesKilled: 0,
            score: 0,
            specialUsed: false,
            inventory: [],
            activeBuffs: {},
          ),
        ),
      );

  ({int hp, int attack, int defense}) _classStats(String playerClass) {
    switch (playerClass) {
      case 'mage':
        return (hp: 80, attack: 35, defense: 3);
      case 'ranger':
        return (hp: 100, attack: 25, defense: 5);
      case 'warrior':
      default:
        return (hp: 150, attack: 20, defense: 8);
    }
  }

  void initializeRun({required String playerId, required String playerClass}) {
    final stats = _classStats(playerClass);
    state = state.copyWith(
      status: GameStatus.loading,
      playerState: PlayerState(
        playerId: playerId,
        playerClass: playerClass,
        position: const [0, 0],
        hp: stats.hp,
        maxHp: stats.hp,
        attack: stats.attack,
        defense: stats.defense,
        turnCount: 0,
        floorsCleared: 0,
        enemiesKilled: 0,
        score: 0,
        specialUsed: false,
        inventory: const [],
        activeBuffs: const {},
      ),
      enemies: const [],
      items: const [],
      sessionTraces: const [],
      turnPhase: TurnPhase.playerTurn,
      aiIsThinking: false,
      aiLastDecision: null,
    );
  }

  void startNewFloor(LevelSchema level) {
    final currentPlayer = state.playerState;

    // Only reset position; keep HP, score, etc. from previous floor
    final updatedPlayer =
        currentPlayer?.copyWith(
          position: level.playerStart,
          specialUsed: false,
        ) ??
        PlayerState(
          playerId: '',
          playerClass: 'warrior',
          position: level.playerStart,
          hp: 150,
          maxHp: 150,
          attack: 20,
          defense: 8,
          turnCount: 0,
          floorsCleared: 0,
          enemiesKilled: 0,
          score: 0,
          specialUsed: false,
          inventory: [],
          activeBuffs: {},
        );

    final enemies = level.enemies
        .map(
          (e) => {
            'id': e.id,
            'type': e.type,
            'position': e.position,
            'hp': e.hp,
            'max_hp': e.maxHp,
            'attack': e.attack,
            'defense': e.defense,
            'behavior': e.behavior,
            'is_alive': true,
          },
        )
        .toList();

    state = state.copyWith(
      status: GameStatus.playing,
      currentLevel: level,
      playerState: updatedPlayer,
      enemies: enemies,
      items: level.items
          .map(
            (i) => {
              'id': i.id,
              'type': i.type,
              'position': i.position,
              'collected': false,
            },
          )
          .toList(),
      turnPhase: TurnPhase.playerTurn,
      aiIsThinking: false,
    );
  }

  void updatePlayerPosition(List<int> position) {
    if (state.playerState != null) {
      state = state.copyWith(
        playerState: state.playerState!.copyWith(position: position),
      );
    }
  }

  void applyActionResult(ActionResult result) {
    if (state.playerState == null) return;

    var newPlayerState = state.playerState!;
    var newEnemies = List<Map<String, dynamic>>.from(state.enemies);

    newPlayerState = newPlayerState.copyWith(
      turnCount: newPlayerState.turnCount + 1,
    );

    if (result.newPlayerPosition != null) {
      newPlayerState = newPlayerState.copyWith(
        position: result.newPlayerPosition,
      );
    }

    if (result.damageDealt != null &&
        result.damageDealt! > 0 &&
        result.enemyIdKilled != null) {
      final target = result.enemyIdKilled;
      newEnemies = newEnemies.map((e) {
        if (e['id'] != target) return e;
        final updated = Map<String, dynamic>.from(e);
        final hp = ((updated['hp'] as int? ?? 0) - result.damageDealt!).clamp(
          0,
          updated['max_hp'] as int? ?? 999,
        );
        updated['hp'] = hp;
        if (hp == 0) updated['is_alive'] = false;
        return updated;
      }).toList();
    }

    if (result.enemyKilled && result.enemyIdKilled != null) {
      newEnemies = newEnemies.map((e) {
        if (e['id'] == result.enemyIdKilled) {
          final updated = Map<String, dynamic>.from(e);
          updated['is_alive'] = false;
          updated['hp'] = 0;
          return updated;
        }
        return e;
      }).toList();
      newPlayerState = newPlayerState.copyWith(
        enemiesKilled: newPlayerState.enemiesKilled + 1,
        score: newPlayerState.score + result.xpGained,
      );
    }

    // handle items collected if necessary

    state = state.copyWith(
      playerState: newPlayerState,
      enemies: newEnemies,
      lastActionResult: result,
      turnPhase: TurnPhase
          .enemyTurn, // Usually moves to enemy turn after player action
    );
  }

  void applyLocalAttack({
    required String enemyId,
    required int damage,
    required bool enemyKilled,
    required int xpGained,
  }) {
    if (state.playerState == null) return;

    final updatedEnemies = state.enemies.map((e) {
      if (e['id'] != enemyId) return e;
      final updated = Map<String, dynamic>.from(e);
      final hp = ((updated['hp'] as int? ?? 0) - damage).clamp(
        0,
        updated['max_hp'] as int? ?? 999,
      );
      updated['hp'] = hp;
      updated['is_alive'] = !enemyKilled && hp > 0;
      return updated;
    }).toList();

    state = state.copyWith(
      playerState: state.playerState!.copyWith(
        turnCount: state.playerState!.turnCount + 1,
        enemiesKilled: enemyKilled
            ? state.playerState!.enemiesKilled + 1
            : state.playerState!.enemiesKilled,
        score: state.playerState!.score + xpGained,
      ),
      enemies: updatedEnemies,
      turnPhase: TurnPhase.enemyTurn,
    );
  }

  void completeFloor() {
    if (state.playerState == null || state.currentLevel == null) return;

    final cleared = state.currentLevel!.floorNumber;
    final won = cleared >= 5;
    state = state.copyWith(
      status: won ? GameStatus.gameOverWin : GameStatus.floorCleared,
      playerState: state.playerState!.copyWith(
        floorsCleared: cleared,
        score: state.playerState!.score + 100,
      ),
      turnPhase: TurnPhase.transition,
    );
  }

  void setAiThinking(bool isThinking, {String? decision}) {
    state = state.copyWith(
      aiIsThinking: isThinking,
      aiLastDecision: decision ?? state.aiLastDecision,
    );
  }

  void applyEnemyDamage(int damage) {
    if (state.playerState == null) return;

    final newHp = (state.playerState!.hp - damage).clamp(
      0,
      state.playerState!.maxHp,
    );
    final isAlive = newHp > 0;

    state = state.copyWith(
      playerState: state.playerState!.copyWith(hp: newHp),
      status: isAlive ? GameStatus.playing : GameStatus.gameOverLose,
    );
  }

  void applyEnemyMove(String enemyId, List<int> position) {
    final updatedEnemies = state.enemies.map((enemy) {
      if (enemy['id'] != enemyId) return enemy;
      final updated = Map<String, dynamic>.from(enemy);
      updated['position'] = position;
      return updated;
    }).toList();

    state = state.copyWith(enemies: updatedEnemies);
  }

  void addTrace(TraceEntry trace) {
    state = state.copyWith(sessionTraces: [...state.sessionTraces, trace]);
  }

  /// Update the turn phase (e.g. after enemy turn completes).
  void setTurnPhase(TurnPhase phase) {
    state = state.copyWith(turnPhase: phase);
  }

  /// Provider-level movement handler. Updates player position in state
  /// and increments the turn counter. Call this after Flame has validated
  /// and visually moved the player.
  void playerMove(String direction) {
    if (state.playerState == null || state.currentLevel == null) return;
    if (state.turnPhase != TurnPhase.playerTurn) {
      return; // Block during enemy turn
    }

    final pos = List<int>.from(state.playerState!.position);
    switch (direction) {
      case 'up':
        pos[0]--;
        break;
      case 'down':
        pos[0]++;
        break;
      case 'left':
        pos[1]--;
        break;
      case 'right':
        pos[1]++;
        break;
      default:
        return;
    }

    final grid = state.currentLevel!.grid;
    if (pos[0] < 0 || pos[0] >= grid.length) return;
    if (pos[1] < 0 || pos[1] >= grid[pos[0]].length) return;
    if (grid[pos[0]][pos[1]] == 0) return; // Wall

    state = state.copyWith(
      playerState: state.playerState!.copyWith(
        position: pos,
        turnCount: state.playerState!.turnCount + 1,
      ),
      turnPhase: TurnPhase.processing, // Signals enemy turn starting
    );
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((
  ref,
) {
  return GameStateNotifier();
});
