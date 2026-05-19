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
import 'flame/dungeon_game.dart';
import 'flame/components/hud_component.dart';
import 'widgets/ai_decision_panel.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  DungeonGame? _dungeonGame;
  final AgentService _agentService = AgentService();
  bool _showNarrativeOverlay = false;
  String _narrativeText = '';
  bool _sessionStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
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
      gameStateNotifier.setAiThinking(true, decision: "DungeonMaster is preparing the session...");
      
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
        setState(() {
          _showNarrativeOverlay = false;
        });
      }
      
      gameStateNotifier.setAiThinking(true, decision: "Level Generator creating Floor 1...");
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
      print("Error starting session: $e");
      gameStateNotifier.setAiThinking(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not reach server. Is the backend running?\n${e.toString().split(':').first}'),
            backgroundColor: Colors.red[900],
            duration: const Duration(seconds: 4),
          ),
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
          print('GameEvent: $event, Data: $data');
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
    
    if (sessionId == null || gameState.playerState == null || gameState.currentLevel == null) return;
    if (gameState.turnPhase != TurnPhase.playerTurn) return;

    if (event == GameEvent.playerMoved || event == GameEvent.playerAttacked) {
      try {
        gameStateNotifier.setAiThinking(true, decision: "Validating action...");

        String direction = data['direction'];
        Map<String, dynamic> action = {
          "type": event == GameEvent.playerAttacked ? "attack" : "move",
          "direction": direction,
          "target": data['target']
        };

        final boardState = {
          "grid": gameState.currentLevel!.grid,
          "all_enemy_positions": gameState.enemies.where((e) => e['is_alive'] == true).map((e) => e['position']).toList(),
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

        gameStateNotifier.setAiThinking(true, decision: "RivalAgent calculating enemy moves...");

        final currentGameState = ref.read(gameStateProvider);
        final aliveEnemies = currentGameState.enemies.where((e) => e['is_alive'] == true).toList();
        
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
        // We simulate setting turnPhase back to player_turn. The StateNotifier doesn't expose it directly yet.
        
      } catch (e) {
        print("Error processing turn: $e");
        gameStateNotifier.setAiThinking(false);
      }
    } else if (event == GameEvent.floorCleared) {
       await _handleFloorCleared(session, gameState);
    }
  }

  Future<void> _handleFloorCleared(SessionModel session, GameState gameState) async {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    try {
      gameStateNotifier.setAiThinking(true, decision: "NarrativeAgent describing victory...");
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
      if (mounted) {
        setState(() {
          _narrativeText = "Floor Cleared!";
        });
      }
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) setState(() => _showNarrativeOverlay = false);

      final nextFloor = gameState.currentLevel!.floorNumber + 1;
      gameStateNotifier.setAiThinking(true, decision: "LevelGenerator building next floor...");
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
      print("Error advancing floor: $e");
      gameStateNotifier.setAiThinking(false);
    }
  }

  Future<void> _handleGameOver(SessionModel session, GameState gameState) async {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    try {
      gameStateNotifier.setAiThinking(true, decision: "NarrativeAgent describing your fate...");
      await _agentService.getNarrative(
        sessionId: session.plan!.sessionId,
        eventType: "player_death",
        playerClass: gameState.playerState!.playerClass,
        floorNumber: gameState.currentLevel!.floorNumber,
        theme: session.plan!.theme,
        context: {"enemies_killed": gameState.playerState!.enemiesKilled},
      );
      
      if (mounted) {
        context.go('/result');
      }
    } catch (e) {
      print("Error ending game: $e");
      if (mounted) {
        context.go('/result');
      }
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
            const Center(
              child: CircularProgressIndicator(color: DungeonColors.gold),
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
            GameWidget(game: _dungeonGame!),

          HUDOverlay(
            currentHp: gameState.playerState?.hp ?? 150,
            maxHp: gameState.playerState?.maxHp ?? 150,
            floorNumber: gameState.currentLevel!.floorNumber,
            turnCount: gameState.playerState?.turnCount ?? 0,
          ),

          const DPadControls(),

          const AiDecisionPanel(),

          if (_showNarrativeOverlay) _buildNarrativeOverlay(),
        ],
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_up, size: 48, color: Colors.white54),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.keyboard_arrow_left, size: 48, color: Colors.white54),
              ),
              const SizedBox(width: 48),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.keyboard_arrow_right, size: 48, color: Colors.white54),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_down, size: 48, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
