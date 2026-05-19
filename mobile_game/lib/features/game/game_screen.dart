import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DungeonColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DungeonColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Text(
          "Game Coming Soon",
          style: DungeonText.displayLarge,
        ),
      ),
    );
  }
}
