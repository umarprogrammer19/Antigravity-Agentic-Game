class EnemySpec {
  final String id;
  final String type;
  final List<int> position;
  final int hp;
  final int maxHp;
  final int attack;
  final int defense;
  final String behavior;

  EnemySpec({
    required this.id,
    required this.type,
    required this.position,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.behavior,
  });

  factory EnemySpec.fromJson(Map<String, dynamic> json) => EnemySpec(
    id: json['id'],
    type: json['type'],
    position: List<int>.from(json['position']),
    hp: json['hp'],
    maxHp: json['max_hp'],
    attack: json['attack'],
    defense: json['defense'],
    behavior: json['behavior'],
  );
}

class ItemSpec {
  final String id;
  final String type;
  final List<int> position;

  ItemSpec({required this.id, required this.type, required this.position});

  factory ItemSpec.fromJson(Map<String, dynamic> json) => ItemSpec(
    id: json['id'],
    type: json['type'],
    position: List<int>.from(json['position']),
  );
}

class LevelSchema {
  final String levelId;
  final int floorNumber;
  final String theme;
  final List<List<int>> grid;
  final int gridRows;
  final int gridCols;
  final List<int> playerStart;
  final List<int> exitPosition;
  final List<EnemySpec> enemies;
  final List<ItemSpec> items;
  final String narrativeHook;
  final double difficultyScore;
  final int enemyCount;
  final int estimatedTurnsToClear;
  final bool aiUsed;
  final bool fallbackUsed;
  final bool cached;
  final String? agentTraceId;
  final int? processingTimeMs;
  final String playerAnalysis;

  LevelSchema({
    required this.levelId,
    required this.floorNumber,
    required this.theme,
    required this.grid,
    required this.gridRows,
    required this.gridCols,
    required this.playerStart,
    required this.exitPosition,
    required this.enemies,
    required this.items,
    required this.narrativeHook,
    required this.difficultyScore,
    required this.enemyCount,
    required this.estimatedTurnsToClear,
    required this.aiUsed,
    required this.fallbackUsed,
    required this.cached,
    this.agentTraceId,
    this.processingTimeMs,
    this.playerAnalysis = "No analysis available.",
  });

  factory LevelSchema.fromJson(Map<String, dynamic> json) => LevelSchema(
    levelId: json['level_id'],
    floorNumber: json['floor_number'],
    theme: json['theme'],
    grid: List<List<int>>.from(json['grid'].map((x) => List<int>.from(x))),
    gridRows: json['grid_rows'],
    gridCols: json['grid_cols'],
    playerStart: List<int>.from(json['player_start']),
    exitPosition: List<int>.from(json['exit_position']),
    enemies: List<EnemySpec>.from(
      json['enemies'].map((x) => EnemySpec.fromJson(x)),
    ),
    items: List<ItemSpec>.from(json['items'].map((x) => ItemSpec.fromJson(x))),
    narrativeHook: json['narrative_hook'],
    difficultyScore: (json['difficulty_score'] as num).toDouble(),
    enemyCount: json['enemy_count'],
    estimatedTurnsToClear: json['estimated_turns_to_clear'],
    aiUsed: json['ai_used'] ?? true,
    fallbackUsed: json['fallback_used'] ?? false,
    cached: json['cached'] ?? false,
    agentTraceId: json['agent_trace_id'],
    processingTimeMs: json['processing_time_ms'],
    playerAnalysis: json['player_analysis'] ?? "No analysis available.",
  );
}
