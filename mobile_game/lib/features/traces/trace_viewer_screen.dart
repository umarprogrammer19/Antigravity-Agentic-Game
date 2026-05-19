import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class TraceViewerScreen extends StatelessWidget {
  final String sessionId;

  const TraceViewerScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DungeonColors.background,
      appBar: AppBar(
        title: Text("Traces: $sessionId", style: DungeonText.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DungeonColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Text(
          "Traces Coming Soon",
          style: DungeonText.displayLarge,
        ),
      ),
    );
  }
}
