import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/game_state_provider.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initGame();
  }

  void _initGame() {
    final gameState = ref.read(gameStateProvider);
    if (gameState.currentLevel != null && _dungeonGame == null) {
      _dungeonGame = DungeonGame(
        levelSchema: gameState.currentLevel!,
        onGameEvent: (event, {data}) {
          print('GameEvent: $event, Data: $data');
          // In actual flow, we would trigger AgentService / update GameStateNotifier here.
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    if (gameState.currentLevel == null) {
      return const Scaffold(
        backgroundColor: DungeonColors.background,
        body: Center(
          child: CircularProgressIndicator(color: DungeonColors.gold),
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
          // Flame Canvas
          if (_dungeonGame != null)
            GameWidget(game: _dungeonGame!),

          // Flutter HP bar + floor info
          HUDOverlay(
            currentHp: gameState.playerState?.hp ?? 150,
            maxHp: gameState.playerState?.maxHp ?? 150,
            floorNumber: gameState.currentLevel!.floorNumber,
            turnCount: gameState.playerState?.turnCount ?? 0,
          ),

          // Flutter d-pad widget
          const DPadControls(),

          // Flutter AI log panel
          const AiDecisionPanel(),
        ],
      ),
    );
  }
}

// Placeholder for DPadControls
class DPadControls extends StatelessWidget {
  const DPadControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120, // Moved up to leave space for AiDecisionPanel collapsed state
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
