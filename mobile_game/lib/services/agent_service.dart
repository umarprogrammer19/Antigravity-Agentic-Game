import 'dart:convert';
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
  static const String baseUrl = 'http://10.0.2.2:8000';
  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 10);

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body),
      ).timeout(_timeout);
      
      stopwatch.stop();
      print('POST $url - ${response.statusCode} - ${stopwatch.elapsedMilliseconds}ms');
      
      if (response.statusCode != 200) {
        throw AgentException('HTTP ${response.statusCode}: ${response.body}');
      }
      return response;
    } catch (e) {
      stopwatch.stop();
      print('POST $url - ERROR - ${stopwatch.elapsedMilliseconds}ms: $e');
      throw AgentException('Request failed: $e');
    }
  }

  Future<http.Response> _get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      ).timeout(_timeout);
      
      stopwatch.stop();
      print('GET $url - ${response.statusCode} - ${stopwatch.elapsedMilliseconds}ms');
      
      if (response.statusCode != 200) {
        throw AgentException('HTTP ${response.statusCode}: ${response.body}');
      }
      return response;
    } catch (e) {
      stopwatch.stop();
      print('GET $url - ERROR - ${stopwatch.elapsedMilliseconds}ms: $e');
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
      headers: {
        'X-Player-ID': playerId,
      },
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
      },
      headers: {
        'X-Session-ID': sessionId,
      },
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
      headers: {
        'X-Session-ID': sessionId,
      },
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
      headers: {
        'X-Session-ID': sessionId,
      },
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
      headers: {
        'X-Session-ID': sessionId,
      },
    );
    
    return NarrativeResponse.fromJson(jsonDecode(response.body));
  }

  Future<List<TraceEntry>> getTraces({
    required String sessionId,
  }) async {
    final response = await _get(
      '/traces/$sessionId',
      headers: {
        'X-Session-ID': sessionId,
      },
    );
    
    final data = jsonDecode(response.body);
    final List<dynamic> traces = data['traces'] ?? [];
    return traces.map((e) => TraceEntry.fromJson(e)).toList();
  }
}
