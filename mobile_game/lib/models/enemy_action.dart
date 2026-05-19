class PlayerTacticsProfile {
  final String? dominantDirection;
  final bool prefersMelee;
  final bool prefersRanged;
  final bool retreatsWhenLowHp;
  final bool cornersPreference;
  final int turnsObserved;

  PlayerTacticsProfile({
    this.dominantDirection,
    required this.prefersMelee,
    required this.prefersRanged,
    required this.retreatsWhenLowHp,
    required this.cornersPreference,
    required this.turnsObserved,
  });

  factory PlayerTacticsProfile.fromJson(Map<String, dynamic> json) => PlayerTacticsProfile(
        dominantDirection: json['dominant_direction'],
        prefersMelee: json['prefers_melee'] ?? false,
        prefersRanged: json['prefers_ranged'] ?? false,
        retreatsWhenLowHp: json['retreats_when_low_hp'] ?? false,
        cornersPreference: json['corners_preference'] ?? false,
        turnsObserved: json['turns_observed'] ?? 0,
      );
}

class EnemyAction {
  final String enemyId;
  final String actionType;
  final String? direction;
  final List<int>? targetPosition;
  final int? damage;
  final String reasoning;
  final PlayerTacticsProfile updatedTactics;

  EnemyAction({
    required this.enemyId,
    required this.actionType,
    this.direction,
    this.targetPosition,
    this.damage,
    required this.reasoning,
    required this.updatedTactics,
  });

  factory EnemyAction.fromJson(Map<String, dynamic> json) => EnemyAction(
        enemyId: json['enemy_id'],
        actionType: json['action_type'],
        direction: json['direction'],
        targetPosition: json['target_position'] != null ? List<int>.from(json['target_position']) : null,
        damage: json['damage'],
        reasoning: json['reasoning'],
        updatedTactics: PlayerTacticsProfile.fromJson(json['updated_tactics']),
      );
}
