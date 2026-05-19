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
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_card.dart';
import '../result/post_game_screen.dart';
import 'flame/dungeon_game.dart';

import 'widgets/ai_decision_panel.dart';

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
  String _loadingMessage = 'Summoning your Dungeon Master…';
  String? _loadingSubMessage;
  bool _showFloorClearedOverlay = false;

  // Floor cleared animation
  late final AnimationController _floorClearedController;
  late final Animation<double> _floorClearedOpacity;
  late final Animation<double> _floorClearedScale;

  @override
  void initState() {
    super.initState();

    _floorClearedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _floorClearedOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floorClearedController, curve: Curves.easeIn),
    );
    _floorClearedScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _floorClearedController,
        curve: Curves.easeOutBack,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
  }

  @override
  void dispose() {
    _floorClearedController.dispose();
    super.dispose();
  }

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
      setState(() {
        _loadingMessage = '🧠 Your Dungeon Master is preparing your run…';
        _loadingSubMessage = 'Step 1/2: Analyzing your history';
      });

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
      setState(() {
        _loadingMessage = '🏗️ Generating your dungeon…';
        _loadingSubMessage = 'Step 2/2: Building Floor 1';
      });

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

  void _initGame() {
    final gameState = ref.read(gameStateProvider);
    if (gameState.currentLevel != null && _dungeonGame == null) {
      _dungeonGame = DungeonGame(
        levelSchema: gameState.currentLevel!,
        onGameEvent: (event, {data}) {
          _handleGameEvent(event, data);
        },
      );
    }
  }

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
    if (gameState.turnPhase != TurnPhase.playerTurn) return;

    if (event == GameEvent.playerMoved || event == GameEvent.playerAttacked) {
      try {
        gameStateNotifier.setAiThinking(true, decision: "Validating action…");

        String direction = data['direction'];
        Map<String, dynamic> action = {
          "type": event == GameEvent.playerAttacked ? "attack" : "move",
          "direction": direction,
          "target": data['target'],
        };

        final boardState = {
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

        gameStateNotifier.setAiThinking(
          true,
          decision: "RivalAgent calculating enemy moves…",
        );

        final currentGameState = ref.read(gameStateProvider);
        final aliveEnemies = currentGameState.enemies
            .where((e) => e['is_alive'] == true)
            .toList();

        for (var enemy in aliveEnemies) {
          final enemyAction = await _agentService.getNPCDecision(
            sessionId: sessionId,
            enemyState: enemy,
            playerState: currentGameState.playerState!.toJson(),
            boardState: boardState,
            playerLastMoves: [direction],
          );

          _dungeonGame?.applyEnemyAction(enemyAction);
          await Future.delayed(const Duration(milliseconds: 200));
        }

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

  Future<void> _handleFloorCleared(
    SessionModel session,
    GameState gameState,
  ) async {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);

    // Show floor cleared overlay
    if (mounted) {
      setState(() => _showFloorClearedOverlay = true);
      _floorClearedController.forward();
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _floorClearedController.reverse();
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _showFloorClearedOverlay = false);
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

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    if (gameState.currentLevel == null) {
      return Scaffold(
        backgroundColor: DungeonColors.background,
        body: Stack(
          children: [
            LoadingOverlay(
              message: _loadingMessage,
              subMessage: _loadingSubMessage,
              onTimeout: () {
                if (mounted) {
                  ErrorCard.showSnackBarError(
                    context,
                    message:
                        "Session start is taking too long. Try again later.",
                  );
                }
              },
            ),
            if (_showNarrativeOverlay) _buildNarrativeOverlay(),
          ],
        ),
      );
    }

    if (_dungeonGame == null) {
      _initGame();
    }

    return Scaffold(
      backgroundColor: DungeonColors.background,
      body: Stack(
        children: [
          if (_dungeonGame != null)
            RepaintBoundary(child: GameWidget(game: _dungeonGame!)),

          // HUD
          _AnimatedHUD(
            currentHp: gameState.playerState?.hp ?? 150,
            maxHp: gameState.playerState?.maxHp ?? 150,
            floorNumber: gameState.currentLevel!.floorNumber,
            turnCount: gameState.playerState?.turnCount ?? 0,
          ),

          const DPadControls(),

          const AiDecisionPanel(),

          // Floor cleared overlay
          if (_showFloorClearedOverlay) _buildFloorClearedOverlay(),

          // Narrative overlay
          if (_showNarrativeOverlay) _buildNarrativeOverlay(),
        ],
      ),
    );
  }

  Widget _buildFloorClearedOverlay() {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: FadeTransition(
        opacity: _floorClearedOpacity,
        child: ScaleTransition(
          scale: _floorClearedScale,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DungeonSpacing.xl,
              vertical: DungeonSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(DungeonRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: DungeonColors.gold.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Text(
              "✦ FLOOR CLEARED ✦",
              style: DungeonText.displayLarge.copyWith(
                color: DungeonColors.gold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNarrativeOverlay() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _showNarrativeOverlay ? 1.0 : 0.0,
      child: Container(
        color: Colors.black87,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Text(
          _narrativeText,
          style: DungeonText.headingMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// HUD overlay with animated HP bar.
class _AnimatedHUD extends StatelessWidget {
  final int currentHp;
  final int maxHp;
  final int floorNumber;
  final int turnCount;

  const _AnimatedHUD({
    required this.currentHp,
    required this.maxHp,
    required this.floorNumber,
    required this.turnCount,
  });

  @override
  Widget build(BuildContext context) {
    final hpRatio = maxHp > 0 ? currentHp / maxHp : 0.0;
    final hpColor = hpRatio > 0.5
        ? DungeonColors.emerald
        : hpRatio > 0.25
        ? DungeonColors.amber
        : DungeonColors.crimsonLight;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DungeonColors.surface.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.all(DungeonRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.favorite,
              color: DungeonColors.crimsonLight,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 8,
                      child: LinearProgressIndicator(
                        value: hpRatio,
                        backgroundColor: DungeonColors.textDim,
                        valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$currentHp/$maxHp",
                    style: DungeonText.caption.copyWith(
                      color: DungeonColors.crimsonLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text("Floor $floorNumber", style: DungeonText.caption),
            const SizedBox(width: 8),
            Text("Turn $turnCount", style: DungeonText.caption),
          ],
        ),
      ),
    );
  }
}

class DPadControls extends StatelessWidget {
  const DPadControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: "Move up",
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.keyboard_arrow_up,
                size: 48,
                color: Colors.white54,
              ),
              tooltip: "Move up",
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                label: "Move left",
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.keyboard_arrow_left,
                    size: 48,
                    color: Colors.white54,
                  ),
                  tooltip: "Move left",
                ),
              ),
              const SizedBox(width: 48),
              Semantics(
                button: true,
                label: "Move right",
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.keyboard_arrow_right,
                    size: 48,
                    color: Colors.white54,
                  ),
                  tooltip: "Move right",
                ),
              ),
            ],
          ),
          Semantics(
            button: true,
            label: "Move down",
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 48,
                color: Colors.white54,
              ),
              tooltip: "Move down",
            ),
          ),
        ],
      ),
    );
  }
}
