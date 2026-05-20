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
import '../result/post_game_screen.dart';
import 'flame/dungeon_game.dart';
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

    try {
      gameStateNotifier.setAiThinking(
        true,
        decision: "DungeonMaster is preparing the session…",
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
        playerCurrentHp: 150,
      );

      gameStateNotifier.startNewFloor(level);

      if (_dungeonGame == null) {
        _initGame();
      } else {
        _dungeonGame!.loadLevel(level);
      }

      gameStateNotifier.setAiThinking(false);
    } catch (e) {
      gameStateNotifier.setAiThinking(false);
      if (mounted) {
        ErrorCard.showSnackBarError(
          context,
          message: "Failed to start your dungeon. Check your connection.",
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
      setState(() {
        _dungeonGame = DungeonGame(
          levelSchema: gameState.currentLevel!,
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

    if (event == GameEvent.playerMoved || event == GameEvent.playerAttacked) {
      try {
        gameStateNotifier.setAiThinking(true, decision: "Validating action…");

        final direction = data['direction'] as String;
        final action = <String, dynamic>{
          "type": event == GameEvent.playerAttacked ? "attack" : "move",
          "direction": direction,
          "target": data['target'],
        };

        if (event == GameEvent.playerAttacked && data['damage'] != null) {
          _showDamageNumber(data['damage'], isPlayerDamage: false);
        }

        final boardState = <String, dynamic>{
          "grid": gameState.currentLevel!.grid,
          "all_enemy_positions": gameState.enemies
              .where((e) => e['is_alive'] == true)
              .map((e) => e['position'])
              .toList(),
          "items": gameState.items,
        };

        final result = await _agentService.validateAction(
          sessionId: sessionId,
          playerState: gameState.playerState!.toJson(),
          action: action,
          boardState: boardState,
        );

        gameStateNotifier.applyActionResult(result);

        if (result.floorCleared) {
          await _handleFloorCleared(session, ref.read(gameStateProvider));
          return;
        }
        if (result.sessionOver) {
          await _handleGameOver(session, ref.read(gameStateProvider));
          return;
        }

        // Enemy turn
        gameStateNotifier.setAiThinking(
          true,
          decision: "RivalAgent calculating enemy moves…",
        );

        final currentGameState = ref.read(gameStateProvider);
        final aliveEnemies = currentGameState.enemies
            .where((e) => e['is_alive'] == true)
            .toList();

        for (var enemy in aliveEnemies) {
          try {
            final enemyAction = await _agentService.getNPCDecision(
              sessionId: sessionId,
              enemyState: enemy,
              playerState: currentGameState.playerState!.toJson(),
              boardState: boardState,
              playerLastMoves: [direction],
            );

            // Apply visual movement in Flame
            _dungeonGame?.applyEnemyAction(enemyAction);

            // If enemy attacks, reduce player HP
            if (enemyAction.actionType == 'attack' &&
                enemyAction.damage != null) {
              gameStateNotifier.applyEnemyDamage(enemyAction.damage!);

              // Flash player component to show damage received
              _dungeonGame?.player.takeHit();

              // Show floating damage number
              _showDamageNumber(enemyAction.damage!, isPlayerDamage: true);

              // Check if player died
              final updatedState = ref.read(gameStateProvider);
              if ((updatedState.playerState?.hp ?? 1) <= 0) {
                await _handleGameOver(ref.read(sessionProvider), updatedState);
                return;
              }
            }

            // Update AI Decision Panel with what enemy did
            final reasoning = enemyAction.reasoning;
            gameStateNotifier.setAiThinking(
              false,
              decision: '${_getEnemyName(enemy["type"])} — $reasoning',
            );

            await Future.delayed(const Duration(milliseconds: 300));
          } catch (e) {
            debugPrint('Enemy action error: $e');
          }
        }

        // After all enemies done, return to player turn
        gameStateNotifier.setTurnPhase(TurnPhase.playerTurn);

        gameStateNotifier.setAiThinking(false);
      } catch (e) {
        gameStateNotifier.setAiThinking(false);
        if (mounted) {
          ErrorCard.showSnackBarError(
            context,
            message: "The AI took too long to respond. Please try again.",
          );
        }
      }
    } else if (event == GameEvent.floorCleared) {
      await _handleFloorCleared(session, gameState);
    }
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
            if (mounted)
              setState(() => _floatingTexts.removeWhere((w) => w.key == key));
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
    final gameStateNotifier = ref.read(gameStateProvider.notifier);

    // Show floor cleared overlay
    if (mounted) {
      setState(() => _showFloorCleared = true);
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _showFloorCleared = false);
    }

    try {
      gameStateNotifier.setAiThinking(
        true,
        decision: "NarrativeAgent describing victory…",
      );
      final narrative = await _agentService.getNarrative(
        sessionId: session.plan!.sessionId,
        eventType: "floor_cleared",
        playerClass: gameState.playerState!.playerClass,
        floorNumber: gameState.currentLevel!.floorNumber,
        theme: session.plan!.theme,
        context: {"enemies_killed": gameState.playerState!.enemiesKilled},
      );

      if (mounted) {
        setState(() {
          _narrativeText = narrative.text;
          _showNarrativeOverlay = true;
        });
      }
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) setState(() => _showNarrativeOverlay = false);

      final nextFloor = gameState.currentLevel!.floorNumber + 1;
      gameStateNotifier.setAiThinking(
        true,
        decision: "LevelGenerator building next floor…",
      );
      final level = await _agentService.generateLevel(
        sessionId: session.plan!.sessionId,
        floorNumber: nextFloor,
        difficultyLevel: session.plan!.difficultyLevel,
        theme: session.plan!.theme,
        playerClass: gameState.playerState!.playerClass,
        enemySpeedMultiplier: session.plan!.enemySpeedMultiplier,
        itemDropRate: session.plan!.itemDropRate,
        playerCurrentHp: gameState.playerState!.hp,
      );

      gameStateNotifier.startNewFloor(level);
      _dungeonGame?.loadLevel(level);
      gameStateNotifier.setAiThinking(false);
    } catch (e) {
      gameStateNotifier.setAiThinking(false);
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

  Widget _buildLoadingScreen(GameState gameState) {
    return Container(
      color: DungeonColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: DungeonColors.gold),
          const SizedBox(height: 24),
          Text(
            gameState.aiLastDecision ?? 'Preparing your dungeon...',
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
      color: Colors.black.withOpacity(0.7),
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
              'The dungeon shifts...',
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
    final gameState = ref.watch(gameStateProvider);

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
                  currentHp: gameState.playerState?.hp ?? 100,
                  maxHp: gameState.playerState?.maxHp ?? 100,
                  floorNumber: gameState.currentLevel?.floorNumber ?? 1,
                  turnCount: gameState.playerState?.turnCount ?? 0,
                  onPauseTap: _showAbandonDialog,
                ),
              ),
            // Game canvas — takes remaining space
            Expanded(
              child: Stack(
                children: [
                  if (_dungeonGame != null)
                    GameWidget(game: _dungeonGame!)
                  else
                    _buildLoadingScreen(gameState),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 8),
                  child: DPadControls(
                    onDirectionTap: (direction) {
                      _dungeonGame?.handlePlayerMove(direction);
                      ref
                          .read(gameStateProvider.notifier)
                          .playerMove(direction);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 180, child: const AiDecisionPanel()),
          ],
        ),
      ),
    );
  }
}
