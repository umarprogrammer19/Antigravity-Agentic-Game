import 'level_schema.dart';

class ActionResult {
  final bool actionValid;
  final String? invalidReason;
  final String resultType;
  final List<int>? newPlayerPosition;
  final int? damageDealt;
  final int? damageTaken;
  final bool enemyKilled;
  final String? enemyIdKilled;
  final int xpGained;
  final bool floorCleared;
  final bool sessionOver;
  final ItemSpec? itemCollected;
  final String resultNarrative;
  final bool aiUsed;
  final int? processingTimeMs;

  ActionResult({
    required this.actionValid,
    this.invalidReason,
    required this.resultType,
    this.newPlayerPosition,
    this.damageDealt,
    this.damageTaken,
    required this.enemyKilled,
    this.enemyIdKilled,
    required this.xpGained,
    required this.floorCleared,
    required this.sessionOver,
    this.itemCollected,
    required this.resultNarrative,
    required this.aiUsed,
    this.processingTimeMs,
  });

  factory ActionResult.fromJson(Map<String, dynamic> json) => ActionResult(
        actionValid: json['action_valid'],
        invalidReason: json['invalid_reason'],
        resultType: json['result_type'],
        newPlayerPosition: json['new_player_position'] != null ? List<int>.from(json['new_player_position']) : null,
        damageDealt: json['damage_dealt'],
        damageTaken: json['damage_taken'],
        enemyKilled: json['enemy_killed'] ?? false,
        enemyIdKilled: json['enemy_id_killed'],
        xpGained: json['xp_gained'] ?? 0,
        floorCleared: json['floor_cleared'] ?? false,
        sessionOver: json['session_over'] ?? false,
        itemCollected: json['item_collected'] != null ? ItemSpec.fromJson(json['item_collected']) : null,
        resultNarrative: json['result_narrative'],
        aiUsed: json['ai_used'] ?? false,
        processingTimeMs: json['processing_time_ms'],
      );
}
