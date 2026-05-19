import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/agent_service.dart';
import '../../models/narrative_response.dart';

class PostGameArgs {
  final bool won;
  final int score;
  final int floorsCleared;
  final int enemiesKilled;
  final int totalTurns;
  final String sessionId;
  final String? deathCause;
  final String theme;

  PostGameArgs({
    required this.won,
    required this.score,
    required this.floorsCleared,
    required this.enemiesKilled,
    required this.totalTurns,
    required this.sessionId,
    this.deathCause,
    required this.theme,
  });
}

class PostGameScreen extends ConsumerStatefulWidget {
  final PostGameArgs args;

  const PostGameScreen({super.key, required this.args});

  @override
  ConsumerState<PostGameScreen> createState() => _PostGameScreenState();
}

class _PostGameScreenState extends ConsumerState<PostGameScreen> {
  bool _isLoading = true;
  String? _error;
  NarrativeResponse? _narrative;
  Map<String, dynamic>? _saveResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPostGame();
    });
  }

  Future<void> _processPostGame() async {
    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final player = ref.read(playerProvider).value;
      final session = ref.read(sessionProvider);

      final agentService = AgentService();

      final narrativeFuture = agentService.getNarrative(
        sessionId: widget.args.sessionId,
        eventType: widget.args.won ? "session_won" : "player_death",
        playerClass: player?.playerClass ?? "warrior",
        floorNumber: widget.args.floorsCleared,
        theme: widget.args.theme,
        context: {
          "enemies_killed": widget.args.enemiesKilled,
          "turns_taken": widget.args.totalTurns,
        },
      );

      final saveFuture = agentService.saveSession(
        playerId: user.uid,
        sessionId: widget.args.sessionId,
        won: widget.args.won,
        score: widget.args.score,
        floorsCleared: widget.args.floorsCleared,
        enemiesKilled: widget.args.enemiesKilled,
        deathCause: widget.args.deathCause,
        deathFloor: widget.args.won ? null : widget.args.floorsCleared,
        playerClass: player?.playerClass ?? "warrior",
        theme: widget.args.theme,
        difficultyLevel: session.plan?.difficultyLevel ?? 3,
        totalTurns: widget.args.totalTurns,
        sessionDurationSeconds: 120, // Placeholder
        aiDecisionsMade: 14, // Placeholder
      );

      final results = await Future.wait([narrativeFuture, saveFuture]);

      if (mounted) {
        setState(() {
          _narrative = results[0] as NarrativeResponse;
          _saveResult = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DungeonColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: DungeonColors.gold),
                )
              : _error != null
              ? _buildErrorState()
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DungeonSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: DungeonColors.crimson,
              size: 48,
            ),
            const SizedBox(height: DungeonSpacing.md),
            Text("Failed to save session", style: DungeonText.headingMedium),
            const SizedBox(height: DungeonSpacing.sm),
            Text(
              _error!,
              style: DungeonText.bodyMedium.copyWith(
                color: DungeonColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DungeonSpacing.xl),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _processPostGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DungeonColors.surfaceElevated,
                side: const BorderSide(color: DungeonColors.gold),
              ),
              child: const Text(
                "RETRY",
                style: TextStyle(color: DungeonColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DungeonSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: DungeonSpacing.xl),
          if (widget.args.won) _buildWinHeader() else _buildDeathHeader(),

          const SizedBox(height: DungeonSpacing.xl),
          _buildScoreCard(),

          const SizedBox(height: DungeonSpacing.lg),
          if (widget.args.won) _buildWinFeedback() else _buildDeathFeedback(),

          if (_saveResult?['updated_stats']?['leaderboard_rank'] != null) ...[
            const SizedBox(height: DungeonSpacing.md),
            Text(
              "New rank: #${_saveResult!['updated_stats']['leaderboard_rank']} 🎉",
              style: DungeonText.headingMedium.copyWith(
                color: DungeonColors.gold,
              ),
            ),
          ],

          const SizedBox(height: DungeonSpacing.xxl),
          _buildActions(),
          const SizedBox(height: DungeonSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildWinHeader() {
    return Column(
      children: [
        Text(
          "✦ DUNGEON CLEARED ✦",
          style: DungeonText.displayLarge.copyWith(color: DungeonColors.gold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDeathHeader() {
    return Column(
      children: [
        Text(
          "💀 SLAIN ON FLOOR ${widget.args.floorsCleared}",
          style: DungeonText.displayLarge.copyWith(
            color: DungeonColors.crimson,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.args.deathCause != null) ...[
          const SizedBox(height: DungeonSpacing.sm),
          Text(
            "By ${widget.args.deathCause}",
            style: DungeonText.headingMedium.copyWith(
              color: DungeonColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DungeonSpacing.lg),
      decoration: BoxDecoration(
        color: DungeonColors.surfaceElevated,
        borderRadius: BorderRadius.circular(DungeonRadius.md.x),
        border: Border.all(color: DungeonColors.goldDim.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SCORE:", style: DungeonText.headingMedium),
              Text(
                "${widget.args.score}",
                style: DungeonText.headingMedium.copyWith(
                  color: DungeonColors.gold,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: DungeonSpacing.sm),
            child: Divider(color: DungeonColors.textDim),
          ),
          _buildStatRow("Floors Cleared", "${widget.args.floorsCleared}/5"),
          const SizedBox(height: DungeonSpacing.xs),
          _buildStatRow("Enemies Killed", "${widget.args.enemiesKilled}"),
          const SizedBox(height: DungeonSpacing.xs),
          _buildStatRow("Turns Taken", "${widget.args.totalTurns}"),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DungeonText.bodyMedium.copyWith(
            color: DungeonColors.textSecondary,
          ),
        ),
        Text(value, style: DungeonText.bodyMedium),
      ],
    );
  }

  Widget _buildWinFeedback() {
    final text =
        _narrative?.text ?? "Exceptional run. You adapted to each floor.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DungeonSpacing.lg),
      decoration: BoxDecoration(
        color: DungeonColors.surfaceElevated,
        borderRadius: BorderRadius.circular(DungeonRadius.md.x),
        border: Border.all(
          color: DungeonColors.agentNarrative.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: DungeonColors.agentNarrative),
              const SizedBox(width: DungeonSpacing.sm),
              Expanded(
                child: Text(
                  "AI DUNGEON MASTER SAYS",
                  style: DungeonText.caption.copyWith(
                    color: DungeonColors.agentNarrative,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DungeonSpacing.md),
          Text(
            '"$text"',
            style: DungeonText.bodyMedium.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildDeathFeedback() {
    final session = ref.read(sessionProvider);
    final dmReasoning = session.plan?.dmReasoning ?? "You fell in battle.";
    final recommendedStrategy =
        session.plan?.recommendedStrategy ?? "Try a different approach.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DungeonSpacing.lg),
      decoration: BoxDecoration(
        color: DungeonColors.surfaceElevated,
        borderRadius: BorderRadius.circular(DungeonRadius.md.x),
        border: Border.all(color: DungeonColors.agentDM.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: DungeonColors.agentDM),
              const SizedBox(width: DungeonSpacing.sm),
              Expanded(
                child: Text(
                  "YOUR DUNGEON MASTER OBSERVED:",
                  style: DungeonText.caption.copyWith(
                    color: DungeonColors.agentDM,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DungeonSpacing.md),
          Text(
            '"$dmReasoning"',
            style: DungeonText.bodyMedium.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: DungeonSpacing.md),
          Text(
            "Next time try:",
            style: DungeonText.caption.copyWith(
              color: DungeonColors.textSecondary,
            ),
          ),
          const SizedBox(height: DungeonSpacing.xs),
          Text(
            '"$recommendedStrategy"',
            style: DungeonText.bodyMedium.copyWith(
              color: DungeonColors.goldDim,
            ),
          ),
          const SizedBox(height: DungeonSpacing.md),
          Text(
            "Your next session has been adjusted.",
            style: DungeonText.caption.copyWith(color: DungeonColors.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.push('/traces/${widget.args.sessionId}');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: DungeonColors.textSecondary,
                  side: const BorderSide(color: DungeonColors.textDim),
                  padding: const EdgeInsets.symmetric(
                    vertical: DungeonSpacing.md,
                  ),
                ),
                child: const Text("VIEW AI DECISIONS"),
              ),
            ),
            if (widget.args.won) ...[
              const SizedBox(width: DungeonSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            "I cleared DungeonMind with a score of ${widget.args.score}!",
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Score copied to clipboard!"),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DungeonColors.sapphire,
                    side: const BorderSide(color: DungeonColors.sapphire),
                    padding: const EdgeInsets.symmetric(
                      vertical: DungeonSpacing.md,
                    ),
                  ),
                  child: const Text("SHARE"),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: DungeonSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/character-select');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DungeonColors.gold,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: DungeonSpacing.md),
            ),
            child: Text(
              widget.args.won ? "PLAY AGAIN" : "TRY AGAIN",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
