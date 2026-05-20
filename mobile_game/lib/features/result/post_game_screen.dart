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
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_card.dart';

class PostGameArgs {
  final bool won;
  final int score;
  final int floorsCleared;
  final int enemiesKilled;
  final int totalTurns;
  final String sessionId;
  final String? deathCause;
  final String theme;

  const PostGameArgs({
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

class _PostGameScreenState extends ConsumerState<PostGameScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  NarrativeResponse? _narrative;
  Map<String, dynamic>? _saveResult;

  // Score count-up animation
  late final AnimationController _scoreController;
  late final Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.args.score.toDouble(),
    ).animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPostGame();
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _processPostGame() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        setState(() => _isLoading = false);
        _scoreController.forward();
        return;
      }

      final player = ref.read(playerProvider).value;
      final session = ref.read(sessionProvider);
      final agentService = AgentService();

      final results = await Future.wait([
        agentService.getNarrative(
          sessionId: widget.args.sessionId,
          eventType: widget.args.won ? "floor_cleared" : "player_death",
          playerClass: player?.playerClass ?? "warrior",
          floorNumber: widget.args.floorsCleared,
          theme: widget.args.theme,
          context: {
            "enemies_killed": widget.args.enemiesKilled,
            "turns_taken": widget.args.totalTurns,
          },
        ),
        agentService.saveSession(
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
          sessionDurationSeconds: 120,
          aiDecisionsMade: 14,
        ),
      ]);

      if (mounted) {
        setState(() {
          _narrative = results[0] as NarrativeResponse;
          _saveResult = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
        _scoreController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        _scoreController.forward();
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
              ? LoadingOverlay(
                  key: const ValueKey('loading'),
                  message: 'Saving your session…',
                  subMessage: 'Consulting the Dungeon Master',
                  onTimeout: () {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                    });
                    _scoreController.forward();
                  },
                )
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      key: const ValueKey('content'),
      padding: const EdgeInsets.all(DungeonSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: DungeonSpacing.xl),
          if (widget.args.won) _buildWinHeader() else _buildDeathHeader(),
          const SizedBox(height: DungeonSpacing.xl),
          _buildScoreCard(),
          const SizedBox(height: DungeonSpacing.lg),

          if (_hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: DungeonSpacing.lg),
              child: ErrorCard(
                message:
                    "Could not save your session. Your score may not be recorded.",
                onRetry: _processPostGame,
                onDismiss: () => setState(() => _hasError = false),
              ),
            )
          else ...[
            if (widget.args.won) _buildWinFeedback() else _buildDeathFeedback(),
          ],

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
    return Text(
      "✦ DUNGEON CLEARED ✦",
      style: DungeonText.displayLarge.copyWith(color: DungeonColors.gold),
      textAlign: TextAlign.center,
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
        borderRadius: const BorderRadius.all(DungeonRadius.md),
        border: Border.all(color: DungeonColors.goldDim.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SCORE:", style: DungeonText.headingMedium),
              AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, _) {
                  return Text(
                    _formatScore(_scoreAnimation.value.round()),
                    style: DungeonText.headingMedium.copyWith(
                      color: DungeonColors.gold,
                    ),
                  );
                },
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: DungeonSpacing.sm),
            child: Divider(color: DungeonColors.textDim),
          ),
          _StatRow(
            label: "Floors Cleared",
            value: "${widget.args.floorsCleared}/5",
          ),
          const SizedBox(height: DungeonSpacing.xs),
          _StatRow(
            label: "Enemies Killed",
            value: "${widget.args.enemiesKilled}",
          ),
          const SizedBox(height: DungeonSpacing.xs),
          _StatRow(label: "Turns Taken", value: "${widget.args.totalTurns}"),
        ],
      ),
    );
  }

  String _formatScore(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
        buffer.write(s[i]);
      }
      return buffer.toString();
    }
    return n.toString();
  }

  Widget _buildWinFeedback() {
    final text =
        _narrative?.text ?? "Exceptional run. You adapted to each floor.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DungeonSpacing.lg),
      decoration: BoxDecoration(
        color: DungeonColors.surfaceElevated,
        borderRadius: const BorderRadius.all(DungeonRadius.md),
        border: Border.all(
          color: DungeonColors.agentNarrative.withValues(alpha: 0.5),
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
        borderRadius: const BorderRadius.all(DungeonRadius.md),
        border: Border.all(color: DungeonColors.agentDM.withValues(alpha: 0.5)),
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
              child: Semantics(
                button: true,
                label: "View AI decisions for this session",
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
            ),
            if (widget.args.won) ...[
              const SizedBox(width: DungeonSpacing.md),
              Expanded(
                child: Semantics(
                  button: true,
                  label: "Share your score",
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              "I cleared DungeonMind with a score of ${widget.args.score}! 🏆",
                        ),
                      );
                      ErrorCard.showSnackBarError(
                        context,
                        message: "Score copied to clipboard!",
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
              ),
            ],
          ],
        ),
        const SizedBox(height: DungeonSpacing.md),
        SizedBox(
          width: double.infinity,
          child: Semantics(
            button: true,
            label: widget.args.won ? "Play again" : "Try again",
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.go('/character-select');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DungeonColors.gold,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  vertical: DungeonSpacing.md,
                ),
              ),
              child: Text(
                widget.args.won ? "PLAY AGAIN" : "TRY AGAIN",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
}
