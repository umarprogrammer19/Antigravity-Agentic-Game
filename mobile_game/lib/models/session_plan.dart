class SessionPlan {
  final String sessionId;
  final String? playerId;
  final String? playerClass;
  final int difficultyLevel;
  final String theme;
  final double enemySpeedMultiplier;
  final double itemDropRate;
  final double enemyCountMultiplier;
  final int bossDifficulty;
  final String narrativeIntro;
  final String dmReasoning;
  final String recommendedStrategy;
  final bool aiUsed;
  final bool fallbackUsed;
  final String? agentTraceId;
  final int? processingTimeMs;
  final String? createdAt;

  SessionPlan({
    required this.sessionId,
    this.playerId,
    this.playerClass,
    required this.difficultyLevel,
    required this.theme,
    required this.enemySpeedMultiplier,
    required this.itemDropRate,
    required this.enemyCountMultiplier,
    required this.bossDifficulty,
    required this.narrativeIntro,
    required this.dmReasoning,
    required this.recommendedStrategy,
    required this.aiUsed,
    required this.fallbackUsed,
    this.agentTraceId,
    this.processingTimeMs,
    this.createdAt,
  });

  factory SessionPlan.fromJson(Map<String, dynamic> json) => SessionPlan(
        sessionId: json['session_id'],
        playerId: json['player_id'],
        playerClass: json['player_class'],
        difficultyLevel: json['difficulty_level'],
        theme: json['theme'],
        enemySpeedMultiplier: (json['enemy_speed_multiplier'] as num).toDouble(),
        itemDropRate: (json['item_drop_rate'] as num).toDouble(),
        enemyCountMultiplier: (json['enemy_count_multiplier'] as num?)?.toDouble() ?? 1.0,
        bossDifficulty: json['boss_difficulty'],
        narrativeIntro: json['narrative_intro'],
        dmReasoning: json['dm_reasoning'],
        recommendedStrategy: json['recommended_strategy'],
        aiUsed: json['ai_used'] ?? true,
        fallbackUsed: json['fallback_used'] ?? false,
        agentTraceId: json['agent_trace_id'],
        processingTimeMs: json['processing_time_ms'],
        createdAt: json['created_at'],
      );
}
