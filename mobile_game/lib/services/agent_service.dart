import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/action_result.dart';
import '../models/enemy_action.dart';
import '../models/level_schema.dart';
import '../models/narrative_response.dart';
import '../models/session_plan.dart';
import '../models/trace_entry.dart';

class AgentException implements Exception {
  final String message;
  AgentException(this.message);

  @override
  String toString() => 'AgentException: $message';
}

class AgentService {
  static String? _runtimeBaseUrl;

  static String get baseUrl {
    if (_runtimeBaseUrl != null) return _runtimeBaseUrl!;
    const configured = String.fromEnvironment('DUNGEONMIND_API_URL');
    if (configured.isNotEmpty) return configured;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 30);

  static List<String> get _candidateBaseUrls {
    const configured = String.fromEnvironment('DUNGEONMIND_API_URL');
    if (configured.isNotEmpty) return [_normalizeBaseUrl(configured)];
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return ['http://10.0.2.2:8000', 'http://127.0.0.1:8000'];
    }
    return ['http://localhost:8000'];
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Future<String> checkHealth() async {
    Object? lastError;
    for (final candidate in _candidateBaseUrls) {
      final url = Uri.parse('$candidate/health');
      try {
        final response = await _client
            .get(url)
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          _runtimeBaseUrl = candidate;
          debugPrint('Backend health check OK: $candidate');
          return candidate;
        }
        lastError = 'HTTP ${response.statusCode}: ${response.body}';
      } catch (e) {
        lastError = e;
      }
    }

    throw AgentException(
      'Cannot reach backend. Tried ${_candidateBaseUrls.join(', ')}. '
      'Last error: $lastError',
    );
  }

  Future<http.Response> _post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json', ...?headers},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      stopwatch.stop();
      debugPrint(
        'POST $url - ${response.statusCode} - ${stopwatch.elapsedMilliseconds}ms',
      );

      if (response.statusCode != 200) {
        throw AgentException('HTTP ${response.statusCode}: ${response.body}');
      }
      return response;
    } catch (e) {
      stopwatch.stop();
      debugPrint('POST $url - ERROR - ${stopwatch.elapsedMilliseconds}ms: $e');
      throw AgentException('Request failed: $e');
    }
  }

  Future<http.Response> _get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client
          .get(url, headers: {'Content-Type': 'application/json', ...?headers})
          .timeout(_timeout);

      stopwatch.stop();
      debugPrint(
        'GET $url - ${response.statusCode} - ${stopwatch.elapsedMilliseconds}ms',
      );

      if (response.statusCode != 200) {
        throw AgentException('HTTP ${response.statusCode}: ${response.body}');
      }
      return response;
    } catch (e) {
      stopwatch.stop();
      debugPrint('GET $url - ERROR - ${stopwatch.elapsedMilliseconds}ms: $e');

      // If we get a timeout and haven't found a working URL yet, try health check
      if (_runtimeBaseUrl == null && e.toString().contains('TimeoutException')) {
        debugPrint('⚠️ Connection timeout - attempting to find working backend URL...');
        try {
          await checkHealth();
          // Retry with the new URL
          return await _get(endpoint, headers: headers);
        } catch (healthError) {
          debugPrint('❌ Health check failed: $healthError');
        }
      }

      throw AgentException('Request failed: $e');
    }
  }

  Future<SessionPlan> startSession({
    required String playerId,
    required String playerClass,
  }) async {
    final response = await _post(
      '/agent/dungeon-master',
      {
        'player_id': playerId,
        'player_class': playerClass,
        'force_new_session': false,
      },
      headers: {'X-Player-ID': playerId},
    );

    return SessionPlan.fromJson(jsonDecode(response.body));
  }

  Future<LevelSchema> generateLevel({
    required String sessionId,
    required int floorNumber,
    required int difficultyLevel,
    required String theme,
    required String playerClass,
    required double enemySpeedMultiplier,
    required double itemDropRate,
    required int playerCurrentHp,
    List<Map<String, dynamic>> playerMoveHistory = const [],
  }) async {
    final response = await _post(
      '/agent/generate-level',
      {
        'session_id': sessionId,
        'floor_number': floorNumber,
        'difficulty_level': difficultyLevel,
        'theme': theme,
        'player_class': playerClass,
        'enemy_speed_multiplier': enemySpeedMultiplier,
        'item_drop_rate': itemDropRate,
        'player_current_hp': playerCurrentHp,
        'player_move_history': playerMoveHistory,
      },
      headers: {'X-Session-ID': sessionId},
    );

    return LevelSchema.fromJson(jsonDecode(response.body));
  }

  Future<EnemyAction> getNPCDecision({
    required String sessionId,
    required Map<String, dynamic> enemyState,
    required Map<String, dynamic> playerState,
    required Map<String, dynamic> boardState,
    required List<String> playerLastMoves,
  }) async {
    final response = await _post(
      '/agent/npc-decision',
      {
        'session_id': sessionId,
        'enemy_id': enemyState['id'],
        'enemy_state': enemyState,
        'player_state': playerState,
        'board_state': boardState,
        'player_last_5_moves': playerLastMoves,
      },
      headers: {'X-Session-ID': sessionId},
    );

    return EnemyAction.fromJson(jsonDecode(response.body));
  }

  Future<ActionResult> validateAction({
    required String sessionId,
    required Map<String, dynamic> playerState,
    required Map<String, dynamic> action,
    required Map<String, dynamic> boardState,
  }) async {
    final response = await _post(
      '/agent/validate-action',
      {
        'session_id': sessionId,
        'player_state': playerState,
        'action': action,
        'board_state': boardState,
      },
      headers: {'X-Session-ID': sessionId},
    );

    return ActionResult.fromJson(jsonDecode(response.body));
  }

  Future<NarrativeResponse> getNarrative({
    required String sessionId,
    required String eventType,
    required String playerClass,
    required int floorNumber,
    required String theme,
    required Map<String, dynamic> context,
  }) async {
    final response = await _post(
      '/agent/narrative',
      {
        'session_id': sessionId,
        'event_type': eventType,
        'player_class': playerClass,
        'floor_number': floorNumber,
        'theme': theme,
        'context': context,
      },
      headers: {'X-Session-ID': sessionId},
    );

    return NarrativeResponse.fromJson(jsonDecode(response.body));
  }

  Future<List<TraceEntry>> getTraces({required String sessionId}) async {
    final response = await _get(
      '/traces/$sessionId',
      headers: {'X-Session-ID': sessionId},
    );

    final data = jsonDecode(response.body);
    final List<dynamic> traces = data['traces'] ?? [];
    return traces.map((e) => TraceEntry.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> saveSession({
    required String playerId,
    required String sessionId,
    required bool won,
    required int score,
    required int floorsCleared,
    required int enemiesKilled,
    String? deathCause,
    int? deathFloor,
    required String playerClass,
    required String theme,
    required int difficultyLevel,
    required int totalTurns,
    required int sessionDurationSeconds,
    required int aiDecisionsMade,
    String? displayName,
  }) async {
    final response = await _post(
      '/players/$playerId/session',
      {
        'session_id': sessionId,
        'won': won,
        'score': score,
        'floors_cleared': floorsCleared,
        'enemies_killed': enemiesKilled,
        'death_cause': deathCause,
        'death_floor': deathFloor,
        'player_class': playerClass,
        'theme': theme,
        'difficulty_level': difficultyLevel,
        'total_turns': totalTurns,
        'session_duration_seconds': sessionDurationSeconds,
        'ai_decisions_made': aiDecisionsMade,
        'display_name': displayName,
      },
      headers: {'X-Player-ID': playerId},
    );

    return jsonDecode(response.body);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    final response = await _get('/leaderboard?limit=$limit');
    final data = jsonDecode(response.body);
    final entries = data['entries'] as List<dynamic>? ?? const [];
    return entries.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getPlayerHistory({required String playerId}) async {
    debugPrint('🔍 AgentService: Fetching history for player: $playerId');
    final response = await _get(
      '/players/$playerId/history',
      headers: {'X-Player-ID': playerId},
    );
    final data = jsonDecode(response.body);
    debugPrint('🔍 AgentService: History response: $data');
    return data;
  }
}
