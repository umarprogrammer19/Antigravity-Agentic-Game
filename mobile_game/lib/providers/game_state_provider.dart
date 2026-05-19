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
      playerId: playerId,
      playerClass: playerClass,
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
            playerClass: "Warrior",
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

  void startNewFloor(LevelSchema level) {
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

    final items = level.items
        .map(
          (i) => {
            'id': i.id,
            'type': i.type,
            'position': i.position,
            'collected': false,
          },
        )
        .toList();

    state = state.copyWith(
      status: GameStatus.playing,
      currentLevel: level,
      enemies: enemies,
      items: items,
      turnPhase: TurnPhase.playerTurn,
    );

    // In a real flow, if playerState is null, you'd initialize it here or earlier.
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

    if (result.newPlayerPosition != null) {
      newPlayerState = newPlayerState.copyWith(
        position: result.newPlayerPosition,
      );
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

  void setAiThinking(bool isThinking, {String? decision}) {
    state = state.copyWith(
      aiIsThinking: isThinking,
      aiLastDecision: decision ?? state.aiLastDecision,
    );
  }

  void addTrace(TraceEntry trace) {
    state = state.copyWith(sessionTraces: [...state.sessionTraces, trace]);
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((
  ref,
) {
  return GameStateNotifier();
});
