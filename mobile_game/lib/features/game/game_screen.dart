import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/game_state_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/agent_service.dart';
import '../../widgets/error_card.dart';
import '../../models/enemy_action.dart';
import '../result/post_game_screen.dart';
import 'flame/dungeon_game.dart';
import 'flame/components/tile_map_component.dart';
import 'widgets/ai_decision_panel.dart';
import 'widgets/dpad_controls.dart';
import 'widgets/hud_overlay.dart';
import 'widgets/floating_damage.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  DungeonGame? _dungeonGame;
  final AgentService _agentService = AgentService();
  bool _showNarrativeOverlay = false;
  String _narrativeText = '';
  bool _sessionStarted = false;
  bool _showFloorCleared = false;
  bool _turnInProgress = false;
  bool _floorTransitionInProgress = false;
  bool _aiPanelExpanded = false;
  final List<Widget> _floatingTexts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
  }

  // ---------------------------------------------------------------------------
  // Session startup
  // ---------------------------------------------------------------------------

  Future<void> _startSession() async {
    if (_sessionStarted) return;
    _sessionStarted = true;

    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final sessionNotifier = ref.read(sessionProvider.notifier);
    final player = ref.read(playerProvider).value;

    final playerId = ref.read(authProvider).value?.uid ?? "guest_123";
    final playerClass = player?.playerClass ?? "warrior";
    gameStateNotifier.initializeRun(
      playerId: playerId,
      playerClass: playerClass,
    );

    try {
      gameStateNotifier.setAiThinking(
        true,
        decision: "DungeonMaster is preparing the session…",
      );

      gameStateNotifier.setAiThinking(
        true,
        decision: "Checking backend connection...",
      );

      final backendUrl = await _agentService.checkHealth();
      debugPrint('Starting dungeon through $backendUrl');

      gameStateNotifier.setAiThinking(
        true,
        decision: "DungeonMaster is preparing the session...",
      );

      final plan = await _agentService.startSession(
        playerId: playerId,
        playerClass: playerClass,
      );

      sessionNotifier.setPlan(plan);

      if (mounted) {
        setState(() {
          _narrativeText = plan.narrativeIntro;
          _showNarrativeOverlay = true;
        });
      }

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _showNarrativeOverlay = false);
      }

      gameStateNotifier.setAiThinking(
        true,
        decision: "Level Generator creating Floor 1…",
      );

      final level = await _agentService.generateLevel(
        sessionId: plan.sessionId,
        floorNumber: 1,
        difficultyLevel: plan.difficultyLevel,
        theme: plan.theme,
        playerClass: playerClass,
        enemySpeedMultiplier: plan.enemySpeedMultiplier,
        itemDropRate: plan.itemDropRate,
        playerCurrentHp: ref.read(gameStateProvider).playerState!.hp,
      );

      gameStateNotifier.startNewFloor(level);

      if (_dungeonGame == null) {
        _initGame();
      } else {
        final playerState = ref.read(gameStateProvider).playerState!;
        _dungeonGame!.syncPlayerStats(
          hp: playerState.hp,
          maxHp: playerState.maxHp,
          attack: playerState.attack,
          defense: playerState.defense,
        );
        await _dungeonGame!.loadLevel(level);
      }

      gameStateNotifier.setAiThinking(false);
    } catch (e) {
      gameStateNotifier.setAiThinking(false);
      if (mounted) {
        final message = e is AgentException
            ? e.message
            : 'Unexpected error: ${e.toString()}';
        ErrorCard.showSnackBarError(
          context,
          message: "Failed to start dungeon. $message",
          onRetry: () {
            _sessionStarted = false;
            _startSession();
          },
        );
        context.pop();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Flame game initialization
  // ---------------------------------------------------------------------------

  void _initGame() {
    final gameState = ref.read(gameStateProvider);
    if (gameState.currentLevel != null && _dungeonGame == null) {
      final level = gameState.currentLevel!;
      final playerState = gameState.playerState!;
      final screenSize = MediaQuery.of(context).size;
      final gridRows = level.grid.length;
      final gridCols = gridRows > 0 ? level.grid.first.length : 0;

      if (gridRows > 0 && gridCols > 0) {
        TileMapComponent.calibrateToScreen(
          screenSize.width,
          screenSize.height,
          gridRows,
          gridCols,
        );
      }

      setState(() {
        _dungeonGame = DungeonGame(
          levelSchema: level,
          playerClass: playerState.playerClass,
          playerHp: playerState.hp,
          playerMaxHp: playerState.maxHp,
          playerAttack: playerState.attack,
          playerDefense: playerState.defense,
          onGameEvent: (event, {data}) {
            _handleGameEvent(event, data);
          },
        );
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Game event handler (from Flame → Flutter)
  // ---------------------------------------------------------------------------

  Future<void> _handleGameEvent(GameEvent event, dynamic data) async {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final gameState = ref.read(gameStateProvider);
    final session = ref.read(sessionProvider);
    final sessionId = session.plan?.sessionId;

    if (sessionId == null ||
        gameState.playerState == null ||
        gameState.currentLevel == null) {
      return;
    }

    if (_floorTransitionInProgress) return;

    if (event == GameEvent.floorCleared) {
      if (data is Map && data['position'] is List) {
        gameStateNotifier.updatePlayerPosition(
          List<int>.from(data['position']),
        );
      }
      await _handleFloorCleared(session, ref.read(gameStateProvider));
      return;
    }

    if (event == GameEvent.playerMoved ||
        event == GameEvent.playerAttacked ||
        event == GameEvent.playerWaited) {
      if (_turnInProgress ||
          gameState.turnPhase != TurnPhase.playerTurn ||
          gameState.status != GameStatus.playing) {
        return;
      }
      try {
        _turnInProgress = true;
        if (mounted) setState(() {});

        final direction = data['direction'] as String;
        if (event == GameEvent.playerMoved) {
          gameStateNotifier.playerMove(direction);
          gameStateNotifier.setTurnPhase(TurnPhase.enemyTurn);
        } else if (event == GameEvent.playerAttacked) {
          gameStateNotifier.setAiThinking(true, decision: "Validating action…");
          final damage = data['damage'] as int? ?? 0;
          final enemyKilled = data['enemyKilled'] == true;
          gameStateNotifier.applyLocalAttack(
            enemyId: data['enemyId'] as String,
            damage: damage,
            enemyKilled: enemyKilled,
            xpGained: enemyKilled ? (data['xpGained'] as int? ?? 0) : 0,
          );
          if (damage > 0) {
            _showDamageNumber(damage, isPlayerDamage: false);
          }
        } else {
          gameStateNotifier.setAiThinking(true, decision: "Validating action…");
          final isWait = event == GameEvent.playerWaited;
          gameStateNotifier.setAiThinking(
            true,
            decision: isWait ? "Waiting..." : "Validating move...",
          );
          final latestState = ref.read(gameStateProvider);
          final result = await _agentService.validateAction(
            sessionId: sessionId,
            playerState: latestState.playerState!.toJson(),
            action: {"type": isWait ? "wait" : "move", "direction": direction},
            boardState: _buildBoardState(latestState),
          );

          if (!result.actionValid) {
            gameStateNotifier.setAiThinking(
              false,
              decision: result.resultNarrative,
            );
            return;
          }

          gameStateNotifier.applyActionResult(result);
        }
        // Enemy turn
        gameStateNotifier.setAiThinking(
          true,
          decision: "RivalAgent calculating enemy moves…",
        );

        final aliveEnemies = ref
            .read(gameStateProvider)
            .enemies
            .where((e) => e['is_alive'] == true)
            .toList();

        final currentGameState = ref.read(gameStateProvider);
        final playerState = currentGameState.playerState!;
        final boardState = _buildBoardState(currentGameState);

        final enemyFutures = aliveEnemies.map((enemy) {
          final matches = currentGameState.enemies.where(
            (e) => e['id'] == enemy['id'],
          );
          final latestEnemy = matches.isNotEmpty ? matches.first : enemy;
          if (latestEnemy['is_alive'] != true) {
            return Future.value(null);
          }

          if (_isAdjacentToPlayer(latestEnemy, playerState)) {
            return Future.value(
              _enemyAttackAction(
                latestEnemy,
                playerState,
                'Enemy is adjacent and attacks.',
              ),
            );
          }

          return _agentService
              .getNPCDecision(
                sessionId: sessionId,
                enemyState: latestEnemy,
                playerState: playerState.toJson(),
                boardState: boardState,
                playerLastMoves: [direction],
              )
              .timeout(
                const Duration(milliseconds: 1200),
                onTimeout: () =>
                    _fallbackEnemyAction(latestEnemy, playerState, boardState),
              )
              .catchError((e) {
                debugPrint('Enemy action error: $e');
                return _fallbackEnemyAction(
                  latestEnemy,
                  playerState,
                  boardState,
                );
              });
        }).toList();

        final enemyActions = await Future.wait(enemyFutures);

        for (int i = 0; i < aliveEnemies.length; i++) {
          final enemy = aliveEnemies[i];
          var action = enemyActions[i];
          if (action == null) continue;

          final latestState = ref.read(gameStateProvider);
          final pState = latestState.playerState!;
          final matches = latestState.enemies.where(
            (e) => e['id'] == enemy['id'],
          );
          final latestEnemy = matches.isNotEmpty ? matches.first : enemy;
          if (latestEnemy['is_alive'] != true) continue;

          final target = _dungeonGame?.enemyMoveTarget(action);
          if (target != null && _positionsEqual(target, pState.position)) {
            action = _enemyAttackAction(
              latestEnemy,
              pState,
              'Enemy reached melee range and attacks instead of overlapping.',
            );
          }

          if (action.actionType == 'move') {
            if (_dungeonGame?.isEnemyMoveAllowed(action) == true) {
              final moveTarget = _dungeonGame!.enemyMoveTarget(action)!;
              _dungeonGame?.applyEnemyAction(action);
              gameStateNotifier.applyEnemyMove(action.enemyId, moveTarget);
            } else {
              action = _fallbackEnemyAction(
                latestEnemy,
                pState,
                _buildBoardState(latestState),
              );
              if (action.actionType == 'move' &&
                  _dungeonGame?.isEnemyMoveAllowed(action) == true) {
                final moveTarget = _dungeonGame!.enemyMoveTarget(action)!;
                _dungeonGame?.applyEnemyAction(action);
                gameStateNotifier.applyEnemyMove(action.enemyId, moveTarget);
              }
            }
          }

          if (action.actionType == 'attack' && action.damage != null) {
            _dungeonGame?.applyEnemyAction(action);
            gameStateNotifier.applyEnemyDamage(action.damage!);
            _dungeonGame?.player.takeHit();
            _showDamageNumber(action.damage!, isPlayerDamage: true);
            final updatedState = ref.read(gameStateProvider);
            if ((updatedState.playerState?.hp ?? 1) <= 0) {
              await _handleGameOver(ref.read(sessionProvider), updatedState);
              return;
            }
          }

          if (action.reasoning.isNotEmpty) {
            gameStateNotifier.setAiThinking(
              false,
              decision:
                  '${_getEnemyName(latestEnemy["type"])} — ${action.reasoning}',
            );
          }

          await Future.delayed(const Duration(milliseconds: 300));
        }

        // After all enemies done, return to player turn
        gameStateNotifier.setTurnPhase(TurnPhase.playerTurn);

        gameStateNotifier.setAiThinking(false);
      } catch (e, st) {
        gameStateNotifier.setAiThinking(false);
        if (mounted) {
          debugPrint('Turn loop error: $e\n$st');
          ErrorCard.showSnackBarError(
            context,
            message: "The AI took too long to respond. $e",
          );
        }
      } finally {
        _turnInProgress = false;
        if (mounted) setState(() {});
      }
    } else if (event == GameEvent.floorCleared) {
      await _handleFloorCleared(session, gameState);
    }
  }

  Map<String, dynamic> _buildBoardState(GameState state) => {
    "grid": state.currentLevel!.grid,
    "all_enemy_positions": state.enemies
        .where((e) => e['is_alive'] == true)
        .map((e) => e['position'])
        .toList(),
    "items": state.items,
  };

  bool _positionsEqual(List<int> a, List<int> b) =>
      a.length == b.length && a[0] == b[0] && a[1] == b[1];

  bool _isAdjacentToPlayer(Map<String, dynamic> enemy, PlayerState player) {
    final position = List<int>.from(enemy['position'] as List);
    final distance =
        (position[0] - player.position[0]).abs() +
        (position[1] - player.position[1]).abs();
    return distance == 1;
  }

  EnemyAction _enemyAttackAction(
    Map<String, dynamic> enemy,
    PlayerState player,
    String reasoning,
  ) {
    final enemyAttack = enemy['attack'] as int? ?? 1;
    final damage = (enemyAttack - player.defense).clamp(1, enemyAttack).toInt();
    return EnemyAction(
      enemyId: enemy['id'] as String,
      actionType: 'attack',
      targetPosition: player.position,
      damage: damage,
      reasoning: reasoning,
      updatedTactics: PlayerTacticsProfile(
        prefersMelee: true,
        prefersRanged: false,
        retreatsWhenLowHp: false,
        cornersPreference: false,
        turnsObserved: player.turnCount,
      ),
    );
  }

  EnemyAction _fallbackEnemyAction(
    Map<String, dynamic> enemy,
    PlayerState player,
    Map<String, dynamic> boardState,
  ) {
    final position = List<int>.from(enemy['position'] as List);
    final distance =
        (position[0] - player.position[0]).abs() +
        (position[1] - player.position[1]).abs();
    if (distance == 1) {
      return _enemyAttackAction(
        enemy,
        player,
        'Fallback melee attack while adjacent.',
      );
    }

    final direction = _stepToward(position, player.position, boardState);
    return EnemyAction(
      enemyId: enemy['id'] as String,
      actionType: direction == null ? 'wait' : 'move',
      direction: direction,
      reasoning: direction == null
          ? 'Fallback waits because no safe path is open.'
          : 'Fallback moves one safe step toward the player.',
      updatedTactics: PlayerTacticsProfile(
        prefersMelee: true,
        prefersRanged: false,
        retreatsWhenLowHp: false,
        cornersPreference: false,
        turnsObserved: player.turnCount,
      ),
    );
  }

  String? _stepToward(
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
      if (occupied.any((p) => p[0] == r && p[1] == c)) continue;
      if (r == to[0] && c == to[1]) continue;
      return entry.key;
    }
    return null;
  }

  String _getEnemyName(String? type) {
    switch (type) {
      case 'goblin':
        return 'Goblin';
      case 'forest_witch':
        return 'Forest Witch';
      case 'shadow_mage':
        return 'Shadow Mage';
      case 'book_golem':
        return 'Book Golem';
      case 'fire_elemental':
        return 'Fire Elemental';
      case 'rock_troll':
        return 'Rock Troll';
      default:
        return type ?? 'Enemy';
    }
  }

  void _showDamageNumber(int damage, {bool isPlayerDamage = false}) {
    final key = UniqueKey();
    final color = isPlayerDamage
        ? DungeonColors.crimsonLight
        : DungeonColors.gold;

    setState(() {
      _floatingTexts.add(
        FloatingDamageNumber(
          key: key,
          damage: damage,
          color: color,
          isPlayerDamage: isPlayerDamage,
          onComplete: () {
            if (mounted) {
              setState(() => _floatingTexts.removeWhere((w) => w.key == key));
            }
          },
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Floor cleared
  // ---------------------------------------------------------------------------

  Future<void> _handleFloorCleared(
    SessionModel session,
    GameState gameState,
  ) async {
    if (_floorTransitionInProgress) return;
    _floorTransitionInProgress = true;
    _turnInProgress = false;
    if (mounted) setState(() {});

    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    gameStateNotifier.completeFloor();
    final completedState = ref.read(gameStateProvider);

    if (completedState.status == GameStatus.gameOverWin) {
      _floorTransitionInProgress = false;
      await _handleGameOver(session, completedState);
      return;
    }

    // Show floor cleared overlay
    if (mounted) {
      setState(() => _showFloorCleared = true);
    }
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _showFloorCleared = false);
    }

    try {
      gameStateNotifier.setAiThinking(
        true,
        decision: "NarrativeAgent describing victory…",
      );
      final nextFloor = completedState.currentLevel!.floorNumber + 1;
      gameStateNotifier.setAiThinking(
        true,
        decision: "LevelGenerator building next floor…",
      );
      final level = await _agentService.generateLevel(
        sessionId: session.plan!.sessionId,
        floorNumber: nextFloor,
        difficultyLevel: session.plan!.difficultyLevel,
        theme: session.plan!.theme,
        playerClass: completedState.playerState!.playerClass,
        enemySpeedMultiplier: session.plan!.enemySpeedMultiplier,
        itemDropRate: session.plan!.itemDropRate,
        playerCurrentHp: completedState.playerState!.hp,
      );

      gameStateNotifier.startNewFloor(level);
      final playerState = ref.read(gameStateProvider).playerState!;
      _dungeonGame?.syncPlayerStats(
        hp: playerState.hp,
        maxHp: playerState.maxHp,
        attack: playerState.attack,
        defense: playerState.defense,
      );
      await _dungeonGame?.loadLevel(level);
      gameStateNotifier.setAiThinking(false);
      unawaited(_showFloorNarrative(session, completedState));
    } catch (e) {
      gameStateNotifier.setAiThinking(false);
      if (mounted) {
        ErrorCard.showSnackBarError(
          context,
          message: "Could not load the next floor. ${e.toString()}",
        );
      }
    } finally {
      _floorTransitionInProgress = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _showFloorNarrative(
    SessionModel session,
    GameState completedState,
  ) async {
    try {
      final narrative = await _agentService
          .getNarrative(
            sessionId: session.plan!.sessionId,
            eventType: "floor_cleared",
            playerClass: completedState.playerState!.playerClass,
            floorNumber: completedState.currentLevel!.floorNumber,
            theme: session.plan!.theme,
            context: {
              "enemies_killed": completedState.playerState!.enemiesKilled,
            },
          )
          .timeout(const Duration(seconds: 2));

      if (!mounted || _floorTransitionInProgress) return;
      setState(() {
        _narrativeText = narrative.text;
        _showNarrativeOverlay = true;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _showNarrativeOverlay = false);
    } catch (_) {
      // Narrative is flavor text; never block floor progression on it.
    }
  }

  // ---------------------------------------------------------------------------
  // Game over
  // ---------------------------------------------------------------------------

  Future<void> _handleGameOver(
    SessionModel session,
    GameState gameState,
  ) async {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    try {
      gameStateNotifier.setAiThinking(
        true,
        decision: "NarrativeAgent describing your fate…",
      );
      await _agentService.getNarrative(
        sessionId: session.plan!.sessionId,
        eventType: "player_death",
        playerClass: gameState.playerState!.playerClass,
        floorNumber: gameState.currentLevel!.floorNumber,
        theme: session.plan!.theme,
        context: {"enemies_killed": gameState.playerState!.enemiesKilled},
      );
    } catch (_) {}

    if (mounted) {
      context.go(
        '/result',
        extra: PostGameArgs(
          won: gameState.status == GameStatus.gameOverWin,
          score: gameState.playerState?.score ?? 0,
          floorsCleared: gameState.playerState?.floorsCleared ?? 0,
          enemiesKilled: gameState.playerState?.enemiesKilled ?? 0,
          totalTurns: gameState.playerState?.turnCount ?? 0,
          sessionId: session.plan?.sessionId ?? '',
          deathCause: null,
          theme: session.plan?.theme ?? 'enchanted_forest',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI Builders
  // ---------------------------------------------------------------------------

  Widget _buildLoadingScreen(String? lastDecision) {
    return Container(
      color: DungeonColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: DungeonColors.gold),
          const SizedBox(height: 24),
          Text(
            lastDecision ?? 'Preparing your dungeon...',
            style: DungeonText.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAbandonDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DungeonColors.surfaceElevated,
        title: Text('Abandon Run?', style: DungeonText.headingMedium),
        content: Text(
          'Your progress will be lost.',
          style: DungeonText.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CONTINUE',
              style: TextStyle(color: DungeonColors.gold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DungeonColors.crimson,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/menu');
            },
            child: const Text('ABANDON'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorClearedOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦ FLOOR CLEARED ✦',
              style: DungeonText.displayLarge.copyWith(
                color: DungeonColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '+100 score reward. Loading next floor...',
              style: DungeonText.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrativeOverlay() {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Text(
        _narrativeText,
        style: DungeonText.headingMedium.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isThinking = ref.watch(
      gameStateProvider.select((s) => s.aiIsThinking),
    );
    final lastDecision = ref.watch(
      gameStateProvider.select((s) => s.aiLastDecision),
    );
    final playerHp = ref.watch(
      gameStateProvider.select((s) => s.playerState?.hp ?? 100),
    );
    final playerMaxHp = ref.watch(
      gameStateProvider.select((s) => s.playerState?.maxHp ?? 100),
    );
    final floorNumber = ref.watch(
      gameStateProvider.select((s) => s.currentLevel?.floorNumber ?? 1),
    );
    final turnCount = ref.watch(
      gameStateProvider.select((s) => s.playerState?.turnCount ?? 0),
    );
    final gameStatus = ref.watch(gameStateProvider.select((s) => s.status));
    final turnPhase = ref.watch(gameStateProvider.select((s) => s.turnPhase));

    final screenHeight = MediaQuery.sizeOf(context).height;
    final compactControls = screenHeight < 720;
    final dpadButtonSize = compactControls ? 44.0 : 56.0;
    final dpadCenterSize = compactControls ? 38.0 : 48.0;
    final dpadIconSize = compactControls ? 22.0 : 28.0;
    final aiPanelHeight = _aiPanelExpanded
        ? (screenHeight * 0.46).clamp(260.0, 420.0).toDouble()
        : (screenHeight * 0.18).clamp(120.0, 150.0).toDouble();
    final canAcceptInput =
        gameStatus == GameStatus.playing &&
        turnPhase == TurnPhase.playerTurn &&
        !isThinking &&
        !_turnInProgress &&
        !_floorTransitionInProgress &&
        !_showNarrativeOverlay &&
        !_showFloorCleared;
    _dungeonGame?.inputEnabled = canAcceptInput;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _showAbandonDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // HUD at top — fixed height
            if (_dungeonGame != null)
              SafeArea(
                bottom: false,
                child: HUDOverlay(
                  currentHp: playerHp,
                  maxHp: playerMaxHp,
                  floorNumber: floorNumber,
                  turnCount: turnCount,
                  onPauseTap: _showAbandonDialog,
                ),
              ),
            // Game canvas — takes remaining space
            Expanded(
              child: Stack(
                children: [
                  if (_dungeonGame != null)
                    RepaintBoundary(child: GameWidget(game: _dungeonGame!))
                  else
                    _buildLoadingScreen(lastDecision),
                  // Overlays on top of game only
                  if (_showNarrativeOverlay)
                    Positioned.fill(child: _buildNarrativeOverlay()),
                  if (_showFloorCleared)
                    Positioned.fill(child: _buildFloorClearedOverlay()),
                  ..._floatingTexts,
                ],
              ),
            ),
            // D-pad and AI panel at bottom — always below game
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: SizedBox(
                      width: 118,
                      child: Text(
                        canAcceptInput
                            ? 'Move into enemies to attack.'
                            : 'Resolving turn...',
                        style: DungeonText.caption.copyWith(
                          color: canAcceptInput
                              ? DungeonColors.textSecondary
                              : DungeonColors.gold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: DPadControls(
                      buttonSize: dpadButtonSize,
                      centerSize: dpadCenterSize,
                      iconSize: dpadIconSize,
                      enabled: canAcceptInput,
                      onDirectionTap: (direction) {
                        _dungeonGame?.handlePlayerMove(direction);
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: aiPanelHeight,
              child: AiDecisionPanel(
                expanded: _aiPanelExpanded,
                onToggleExpanded: () {
                  setState(() => _aiPanelExpanded = !_aiPanelExpanded);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
