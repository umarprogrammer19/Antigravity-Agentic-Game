# DungeonMind — API Contracts
### Complete Request/Response Specifications for All Backend Routes
### Reference for: Backend Architect Agent, Flutter Architect Agent
---

## BASE URL

```
Development:  http://10.0.2.2:8000       (Android emulator → localhost)
Production:   https://api.dungeonmind.app (deploy to Cloud Run)
```

## GLOBAL HEADERS

```
Content-Type: application/json
X-Player-ID: {firebase_uid}         (all authenticated routes)
X-Session-ID: {session_id}          (all in-session routes)
```

## ERROR RESPONSE FORMAT (All Routes)

```json
{
  "error": true,
  "error_code": "AGENT_TIMEOUT | VALIDATION_ERROR | NOT_FOUND | UNAUTHORIZED",
  "message": "Human readable error description",
  "fallback_used": true,
  "timestamp": "2026-05-18T10:32:00Z"
}
```

**CRITICAL:** Backend NEVER returns 500. All agent failures return 200 with `fallback_used: true`.

---

## ROUTE 1: Health Check

### `GET /health`

**Purpose:** Verify backend is running. Called by Flutter on app start.

**Auth:** None required

**Response 200:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "gemini_connected": true,
  "firebase_connected": true,
  "redis_connected": true,
  "timestamp": "2026-05-18T10:32:00Z"
}
```

---

## ROUTE 2: Start Session (Dungeon Master)

### `POST /agent/dungeon-master`

**Purpose:** Called once at session start. DM analyzes player history and creates session plan.

**Auth:** Required (X-Player-ID header)

**Request Body:**
```json
{
  "player_id": "firebase_uid_string",
  "player_class": "warrior",
  "force_new_session": false
}
```

**Field Rules:**
- `player_class`: must be `"warrior"` | `"mage"` | `"ranger"`
- `force_new_session`: if true, ignore any cached session for this player

**Response 200:**
```json
{
  "session_id": "uuid-v4-string",
  "difficulty_level": 3,
  "theme": "enchanted_forest",
  "enemy_speed_multiplier": 0.8,
  "item_drop_rate": 1.5,
  "enemy_count_multiplier": 0.9,
  "boss_difficulty": 2,
  "narrative_intro": "The ancient forest closes around you. Something old stirs in the roots.",
  "dm_reasoning": "Player has 80% loss rate across 10 sessions. Reducing difficulty to rebuild confidence. Selecting enchanted_forest as easiest theme. Item drop increased to provide more healing.",
  "recommended_strategy": "Engage enemies one at a time. Use items immediately.",
  "ai_used": true,
  "fallback_used": false,
  "agent_trace_id": "trace_uuid",
  "processing_time_ms": 2340
}
```

**Response 200 (Fallback — AI unavailable):**
```json
{
  "session_id": "uuid-v4-string",
  "difficulty_level": 3,
  "theme": "enchanted_forest",
  "enemy_speed_multiplier": 1.0,
  "item_drop_rate": 1.0,
  "enemy_count_multiplier": 1.0,
  "boss_difficulty": 2,
  "narrative_intro": "The dungeon awaits. Danger lurks in every shadow.",
  "dm_reasoning": "Default session (AI temporarily unavailable)",
  "recommended_strategy": "Explore carefully.",
  "ai_used": false,
  "fallback_used": true,
  "agent_trace_id": null,
  "processing_time_ms": 45
}
```

**Error Responses:**
- `400`: Missing player_id or invalid player_class
- `200 + fallback_used: true`: Gemini API failure (game continues with defaults)

---

## ROUTE 3: Generate Level

### `POST /agent/generate-level`

**Purpose:** Generate a complete dungeon floor as JSON. Called once per floor.

**Auth:** Required

**Request Body:**
```json
{
  "session_id": "uuid-v4-string",
  "floor_number": 1,
  "difficulty_level": 3,
  "theme": "enchanted_forest",
  "player_class": "warrior",
  "enemy_speed_multiplier": 0.8,
  "item_drop_rate": 1.5,
  "player_current_hp": 150
}
```

**Field Rules:**
- `floor_number`: 1-5
- `difficulty_level`: 1-10
- `theme`: `"cursed_library"` | `"volcanic_caves"` | `"enchanted_forest"`
- `player_current_hp`: Used to determine if extra healing items should spawn

**Response 200:**
```json
{
  "level_id": "uuid-v4-string",
  "floor_number": 1,
  "theme": "enchanted_forest",
  "grid": [
    [0,0,0,0,0,0,0,0,0,0],
    [0,1,1,1,0,1,1,1,1,0],
    [0,1,0,1,1,1,0,0,1,0],
    [0,1,0,0,0,1,0,0,1,0],
    [0,0,0,1,0,1,0,0,0,0],
    [0,1,1,1,0,1,1,1,1,0],
    [0,1,0,1,0,0,0,1,0,0],
    [0,1,0,1,1,1,1,1,0,0],
    [0,1,0,0,0,0,0,1,1,0],
    [0,0,0,0,0,0,0,0,0,0]
  ],
  "grid_rows": 10,
  "grid_cols": 10,
  "player_start": [1, 1],
  "exit_position": [8, 8],
  "enemies": [
    {
      "id": "e1",
      "type": "goblin",
      "position": [4, 5],
      "hp": 20,
      "max_hp": 20,
      "attack": 8,
      "defense": 3,
      "behavior": "rush_melee"
    },
    {
      "id": "e2",
      "type": "forest_witch",
      "position": [7, 3],
      "hp": 35,
      "max_hp": 35,
      "attack": 14,
      "defense": 4,
      "behavior": "ranged_2tile"
    }
  ],
  "items": [
    {
      "id": "i1",
      "type": "health_potion",
      "position": [3, 8]
    }
  ],
  "narrative_hook": "Twisted roots crack the stone floor where ancient trees once stood.",
  "difficulty_score": 3.2,
  "enemy_count": 2,
  "estimated_turns_to_clear": 18,
  "ai_used": true,
  "fallback_used": false,
  "cached": false,
  "agent_trace_id": "trace_uuid",
  "processing_time_ms": 2870
}
```

---

## ROUTE 4: NPC Decision (Enemy Turn)

### `POST /agent/npc-decision`

**Purpose:** Get the next action for one enemy. Called per enemy per turn.

**Auth:** Required

**Request Body:**
```json
{
  "session_id": "uuid-v4-string",
  "enemy_id": "e1",
  "enemy_state": {
    "id": "e1",
    "type": "goblin",
    "position": [4, 5],
    "hp": 15,
    "max_hp": 20,
    "attack": 8,
    "defense": 3,
    "base_behavior": "rush_melee"
  },
  "player_state": {
    "position": [3, 5],
    "hp": 85,
    "class": "warrior"
  },
  "board_state": {
    "grid": [[0,0,...],[...]],
    "all_enemy_positions": [[4,5],[7,3]],
    "items": [{"id":"i1","position":[3,8]}]
  },
  "player_last_5_moves": ["right", "right", "attack", "up", "right"]
}
```

**Response 200:**
```json
{
  "enemy_id": "e1",
  "action_type": "attack",
  "direction": null,
  "target_position": [3, 5],
  "damage": 5,
  "reasoning": "Player adjacent. Direct attack. HP low but attacking is optimal.",
  "updated_tactics": {
    "dominant_direction": "right",
    "prefers_melee": true,
    "prefers_ranged": false,
    "retreats_when_low_hp": false,
    "corners_preference": false,
    "turns_observed": 5
  },
  "ai_used": true,
  "fallback_used": false,
  "cached": false,
  "processing_time_ms": 780
}
```

---

## ROUTE 5: Validate Player Action

### `POST /agent/validate-action`

**Purpose:** Validate a player action and return its result. Standard actions use pure Python (fast). Edge cases use AI.

**Auth:** Required

**Request Body:**
```json
{
  "session_id": "uuid-v4-string",
  "player_state": {
    "class": "warrior",
    "position": [3, 5],
    "hp": 85,
    "max_hp": 150,
    "attack": 20,
    "defense": 8,
    "turn_count": 14,
    "special_used": false,
    "inventory": []
  },
  "action": {
    "type": "move",
    "direction": "up",
    "target": null
  },
  "board_state": {
    "grid": [[0,0,...],[...]],
    "enemies": [{"id":"e1","position":[4,5],"hp":15,"max_hp":20,"attack":8,"defense":3}],
    "exit_position": [8, 8],
    "items": []
  }
}
```

**Action Types and Fields:**
```json
Move:    {"type": "move", "direction": "up|down|left|right", "target": null}
Attack:  {"type": "attack", "direction": null, "target": [row, col]}
Special: {"type": "special", "direction": "up|down|left|right", "target": [row, col]}
Wait:    {"type": "wait", "direction": null, "target": null}
```

**Response 200:**
```json
{
  "action_valid": true,
  "invalid_reason": null,
  "result_type": "moved",
  "new_player_position": [2, 5],
  "damage_dealt": null,
  "damage_taken": null,
  "enemy_killed": false,
  "enemy_id_killed": null,
  "xp_gained": 0,
  "floor_cleared": false,
  "session_over": false,
  "item_collected": null,
  "result_narrative": "You move north. The shadows shift.",
  "ai_used": false,
  "processing_time_ms": 12
}
```

**Response 200 — Attack Result:**
```json
{
  "action_valid": true,
  "invalid_reason": null,
  "result_type": "killed_enemy",
  "new_player_position": null,
  "damage_dealt": 15,
  "damage_taken": null,
  "enemy_killed": true,
  "enemy_id_killed": "e1",
  "xp_gained": 4,
  "floor_cleared": false,
  "session_over": false,
  "item_collected": null,
  "result_narrative": "You strike the Goblin for 15 damage. It falls.",
  "ai_used": false,
  "processing_time_ms": 8
}
```

**Response 200 — Invalid Action:**
```json
{
  "action_valid": false,
  "invalid_reason": "Wall tile. Cannot move there.",
  "result_type": "invalid",
  "new_player_position": null,
  "damage_dealt": null,
  "damage_taken": null,
  "enemy_killed": false,
  "enemy_id_killed": null,
  "xp_gained": 0,
  "floor_cleared": false,
  "session_over": false,
  "item_collected": null,
  "result_narrative": "A wall blocks your path.",
  "ai_used": false,
  "processing_time_ms": 5
}
```

---

## ROUTE 6: Get Narrative Text

### `POST /agent/narrative`

**Purpose:** Generate atmospheric story text for game events.

**Auth:** Required

**Request Body:**
```json
{
  "session_id": "uuid-v4-string",
  "event_type": "floor_cleared",
  "player_class": "warrior",
  "floor_number": 2,
  "theme": "enchanted_forest",
  "context": {
    "enemies_killed": 3,
    "turns_taken": 22,
    "items_collected": 1
  }
}
```

**event_type values:** `"session_start"` | `"floor_cleared"` | `"item_found"` | `"boss_encounter"` | `"player_death"` | `"enemy_killed"`

**Response 200:**
```json
{
  "event_type": "floor_cleared",
  "text": "Three fallen. The forest remembers. Floor 3 waits, darker than before.",
  "display_duration": 2500,
  "ai_used": true,
  "fallback_used": false,
  "cached": true,
  "processing_time_ms": 340
}
```

---

## ROUTE 7: Save Session Result

### `POST /players/{player_id}/session`

**Purpose:** Save completed session to Firestore. Called on win or death.

**Auth:** Required

**Request Body:**
```json
{
  "session_id": "uuid-v4-string",
  "won": false,
  "score": 450,
  "floors_cleared": 2,
  "enemies_killed": 8,
  "death_cause": "shadow_mage",
  "death_floor": 3,
  "player_class": "warrior",
  "theme": "cursed_library",
  "difficulty_level": 3,
  "total_turns": 67,
  "session_duration_seconds": 420,
  "ai_decisions_made": 14
}
```

**Response 200:**
```json
{
  "saved": true,
  "session_id": "uuid-v4-string",
  "updated_stats": {
    "total_sessions": 11,
    "wins": 2,
    "losses": 9,
    "high_score": 1240,
    "leaderboard_rank": 15
  }
}
```

---

## ROUTE 8: Get Player History

### `GET /players/{player_id}/history`

**Purpose:** Retrieve player stats and session history. Used by DM agent.

**Auth:** Required

**Response 200:**
```json
{
  "player_id": "firebase_uid",
  "display_name": "Player",
  "player_class": "warrior",
  "total_sessions": 10,
  "wins": 2,
  "losses": 8,
  "high_score": 1240,
  "avg_floors_cleared": 2.3,
  "favorite_death_cause": "shadow_mage",
  "total_enemies_killed": 64,
  "last_5_sessions": [
    {
      "session_id": "uuid",
      "won": false,
      "floors_cleared": 2,
      "death_cause": "shadow_mage",
      "score": 450,
      "class_used": "warrior",
      "theme": "cursed_library",
      "played_at": "2026-05-18T10:00:00Z"
    }
  ]
}
```

---

## ROUTE 9: Get Agent Traces

### `GET /traces/{session_id}`

**Purpose:** Retrieve all agent trace logs for a session. Used by Trace Viewer screen.

**Auth:** Required

**Response 200:**
```json
{
  "session_id": "uuid-v4-string",
  "total_decisions": 14,
  "agents_used": ["DungeonMasterAgent", "LevelGeneratorAgent", "RivalAgent", "NarrativeAgent"],
  "traces": [
    {
      "trace_id": "uuid",
      "session_id": "uuid",
      "agent": "DungeonMasterAgent",
      "step": 1,
      "timestamp": "2026-05-18T10:32:01.234Z",
      "reasoning": "Player has 80% loss rate. Applying easy mode.",
      "tool_called": "compute_player_stats",
      "tool_input": {"wins": 2, "losses": 8},
      "tool_output": {"loss_rate": 0.8, "category": "struggling"},
      "decision": "Setting difficulty to 3/10. Reducing enemy speed to 0.8x.",
      "duration_ms": 1240
    },
    {
      "trace_id": "uuid",
      "session_id": "uuid",
      "agent": "LevelGeneratorAgent",
      "step": 1,
      "timestamp": "2026-05-18T10:32:04.100Z",
      "reasoning": "Generating 10x10 enchanted_forest level for difficulty 3.",
      "tool_called": "generate_grid",
      "tool_input": {"rows": 10, "cols": 10, "wall_density": 0.25},
      "tool_output": {"grid_generated": true, "floor_tiles": 58},
      "decision": "10x10 grid created with 58 walkable tiles.",
      "duration_ms": 2870
    }
  ]
}
```

---

## ROUTE 10: Get Leaderboard

### `GET /leaderboard`

**Purpose:** Fetch global top 20 scores.

**Auth:** None required

**Query Params:** `?limit=20&offset=0`

**Response 200:**
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "player_id": "uid_anonymized",
      "display_name": "DungeonMaster",
      "score": 4820,
      "floors_cleared": 5,
      "class_used": "mage",
      "achieved_at": "2026-05-18T08:00:00Z"
    }
  ],
  "total_entries": 156,
  "last_updated": "2026-05-18T10:30:00Z"
}
```

---

## FLUTTER API CLIENT PATTERN

```dart
// lib/services/agent_service.dart

class AgentService {
  static const String _baseUrl = 'http://10.0.2.2:8000';
  final http.Client _client;

  Future<SessionPlan> startSession({
    required String playerId,
    required String playerClass,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/agent/dungeon-master'),
      headers: {
        'Content-Type': 'application/json',
        'X-Player-ID': playerId,
      },
      body: jsonEncode({
        'player_id': playerId,
        'player_class': playerClass,
        'force_new_session': false,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return SessionPlan.fromJson(jsonDecode(response.body));
    }
    throw AgentException('Failed to start session: ${response.statusCode}');
  }

  // All other methods follow same pattern
}
```

## FASTAPI ROUTE PATTERN

```python
# mobile-game-server/routers/agents.py

@router.post("/dungeon-master", response_model=SessionPlanResponse)
async def get_dungeon_master_plan(
    request: DungeonMasterRequest,
    background_tasks: BackgroundTasks,
) -> SessionPlanResponse:
    """
    Called once at session start. DM analyzes player history
    and creates personalized session plan.
    """
    start_time = time.time()
    
    try:
        # Get player history
        history = await firebase_service.get_player_history(request.player_id)
        
        # Run DM agent
        agent = DungeonMasterAgent()
        plan = await agent.run({
            "player_id": request.player_id,
            "player_class": request.player_class,
            "history": history
        })
        
        # Save traces in background
        background_tasks.add_task(
            firebase_service.save_traces,
            plan.session_id,
            agent.get_traces()
        )
        
        return SessionPlanResponse(
            **plan.model_dump(),
            ai_used=True,
            fallback_used=False,
            processing_time_ms=int((time.time() - start_time) * 1000)
        )
        
    except Exception as e:
        logger.error(f"DungeonMasterAgent failed: {e}")
        return SessionPlanResponse(
            **FALLBACK_SESSION_PLAN.model_dump(),
            ai_used=False,
            fallback_used=True,
            processing_time_ms=int((time.time() - start_time) * 1000)
        )
```

---

## RESPONSE TIME TARGETS

| Route | Target | Maximum | Action if Exceeded |
|-------|--------|---------|-------------------|
| `/agent/dungeon-master` | 3s | 8s | Return fallback |
| `/agent/generate-level` | 3s | 8s | Return cached/fallback level |
| `/agent/npc-decision` | 800ms | 1500ms | Return base_behavior fallback |
| `/agent/validate-action` | 50ms | 200ms | Pure Python always (no timeout) |
| `/agent/narrative` | 1.5s | 3s | Return hardcoded fallback |
| `/traces/{id}` | 200ms | 1s | Firebase read |
| `/health` | 50ms | 500ms | Always instant |

---

*All routes must be implemented exactly as documented here.*
*Changing field names breaks the Flutter client. Coordinate any changes here first.*
