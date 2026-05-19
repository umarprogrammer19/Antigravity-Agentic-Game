import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

import '../../widgets/empty_state_card.dart';
import '../../widgets/error_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // TODO: Replace with actual leaderboard API once available
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _entries = [
            {
              "rank": 1,
              "name": "DungeonMaster",
              "score": 4820,
              "subtitle": "Mage · 5 floors",
              "isCurrentPlayer": false,
            },
            {
              "rank": 2,
              "name": "ShadowSlayer",
              "score": 3640,
              "subtitle": "Warrior · 5 floors",
              "isCurrentPlayer": false,
            },
            {
              "rank": 15,
              "name": "YOU",
              "score": 1240,
              "subtitle": "Warrior · 2 floors",
              "isCurrentPlayer": true,
            },
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LEADERBOARD", style: DungeonText.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back",
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DungeonColors.gold),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DungeonSpacing.lg),
          child: ErrorCard(
            message:
                "Failed to load the leaderboard. Check your internet connection.",
            onRetry: _loadLeaderboard,
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return EmptyStateCard(
        icon: Icons.emoji_events,
        title: "No scores yet",
        description:
            "Be the first to reach the top! Complete a dungeon run to appear here.",
        buttonText: "PLAY NOW",
        onButtonPressed: () => context.go('/character-select'),
      );
    }

    // Separate top 3 and current player divider
    final top3 = _entries.where((e) => (e['rank'] as int) <= 3).toList();
    final rest = _entries.where((e) => (e['rank'] as int) > 3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DungeonSpacing.md),
      child: Column(
        children: [
          for (int i = 0; i < top3.length; i++) ...[
            _StaggeredLeaderboardEntry(index: i, entry: top3[i]),
            if (i < top3.length - 1) const SizedBox(height: DungeonSpacing.sm),
          ],
          if (rest.isNotEmpty) ...[
            const SizedBox(height: DungeonSpacing.sm),
            const Divider(color: DungeonColors.textDim),
            const SizedBox(height: DungeonSpacing.sm),
            for (int i = 0; i < rest.length; i++) ...[
              _StaggeredLeaderboardEntry(
                index: top3.length + i,
                entry: rest[i],
              ),
              if (i < rest.length - 1)
                const SizedBox(height: DungeonSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

/// Animates each leaderboard entry sliding in from the left with a stagger.
class _StaggeredLeaderboardEntry extends StatefulWidget {
  final int index;
  final Map<String, dynamic> entry;

  const _StaggeredLeaderboardEntry({required this.index, required this.entry});

  @override
  State<_StaggeredLeaderboardEntry> createState() =>
      _StaggeredLeaderboardEntryState();
}

class _StaggeredLeaderboardEntryState extends State<_StaggeredLeaderboardEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Stagger the entrance
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final rank = e['rank'] as int;
    final name = e['name'] as String;
    final score = e['score'] as int;
    final subtitle = e['subtitle'] as String;
    final isCurrentPlayer = e['isCurrentPlayer'] as bool;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _LeaderboardEntryCard(
          rank: rank,
          name: name,
          score: score,
          subtitle: subtitle,
          isCurrentPlayer: isCurrentPlayer,
        ),
      ),
    );
  }
}

class _LeaderboardEntryCard extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final String subtitle;
  final bool isCurrentPlayer;

  const _LeaderboardEntryCard({
    required this.rank,
    required this.name,
    required this.score,
    required this.subtitle,
    this.isCurrentPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;

    return Container(
      padding: const EdgeInsets.all(DungeonSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? DungeonColors.surfaceElevated
            : DungeonColors.surface,
        borderRadius: const BorderRadius.all(DungeonRadius.md),
        border: Border.all(
          color: isCurrentPlayer
              ? DungeonColors.gold
              : isTop3
              ? DungeonColors.goldDim.withValues(alpha: 0.5)
              : Colors.transparent,
          width: isCurrentPlayer ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "#$rank",
              style: DungeonText.headingMedium.copyWith(
                color: isCurrentPlayer || isTop3
                    ? DungeonColors.gold
                    : DungeonColors.textSecondary,
              ),
            ),
          ),
          if (isTop3) ...[
            Icon(Icons.star, color: DungeonColors.gold, size: 16),
            const SizedBox(width: DungeonSpacing.xs),
          ],
          if (isCurrentPlayer && !isTop3) ...[
            const Icon(Icons.person, color: DungeonColors.gold, size: 16),
            const SizedBox(width: DungeonSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DungeonText.headingMedium),
                Text(subtitle, style: DungeonText.caption),
              ],
            ),
          ),
          Text(
            _formatScore(score),
            style: DungeonText.headingMedium.copyWith(
              color: DungeonColors.gold,
            ),
          ),
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
}
