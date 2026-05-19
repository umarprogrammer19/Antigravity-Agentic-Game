import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/game_state_provider.dart';
import 'flame/dungeon_game.dart';
import 'flame/components/hud_component.dart';

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
      bottom: 20,
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

// Placeholder for AiDecisionPanel
class AiDecisionPanel extends StatelessWidget {
  const AiDecisionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(DungeonSpacing.sm),
        decoration: BoxDecoration(
          color: DungeonColors.surfaceElevated.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.all(DungeonRadius.sm),
          border: Border.all(color: DungeonColors.goldDim),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AI Trace Log', style: DungeonText.caption.copyWith(color: DungeonColors.gold)),
            const SizedBox(height: 4),
            Text('Enemy reasoning will appear here...', style: DungeonText.trace),
          ],
        ),
      ),
    );
  }
}
