# DungeonMind — Database Schema
### Firestore Collections + Redis Keys + Realtime DB Structure
### Reference for: Backend Architect Agent, Flutter Architect Agent
---

## DATABASE OVERVIEW

| Database | Purpose | Access Pattern |
|----------|---------|---------------|
| Firestore | Permanent player data, sessions, traces, leaderboard | Read/Write via Firebase Admin (backend) + Firebase SDK (Flutter) |
| Firebase Realtime DB | Live game state during active session | Real-time sync to Flutter |
| Redis | Agent working memory, level cache, rate limiting | Backend only (agents) |

---

## FIRESTORE SCHEMA

### Collection: `players`

**Path:** `players/{uid}`

**Document Fields:**
```json
{
  "uid": "firebase_uid_string",
  "display_name": "Player",
  "email": "player@example.com",
  "avatar_color": "#4F8EF7",
  "player_class": "warrior",
  "created_at": "Timestamp",
  "last_active": "Timestamp",
  "high_score": 0,
  "leaderboard_rank": null
}
```

**Subcollection:** `players/{uid}/stats`
**Document:** `players/{uid}/stats/all_time`
```json
{
  "total_sessions": 0,
  "wins": 0,
  "losses": 0,
  "total_floors_cleared": 0,
  "total_enemies_killed": 0,
  "total_turns_played": 0,
  "total_play_time_seconds": 0,
  "avg_floors_cleared": 0.0,
  "avg_session_duration_seconds": 0.0,
  "favorite_class": "warrior",
  "favorite_theme": null,
  "favorite_death_cause": null,
  "death_causes": {
    "goblin": 0,
    "shadow_mage": 0,
    "fire_elemental": 0,
    "rock_troll": 0,
    "forest_witch": 0,
    "lava_sprite": 0,
    "book_golem": 0,
    "librarian": 0,
    "druid": 0
  },
  "sessions_by_theme": {
    "cursed_library": 0,
    "volcanic_caves": 0,
    "enchanted_forest": 0
  },
  "wins_by_theme": {
    "cursed_library": 0,
    "volcanic_caves": 0,
    "enchanted_forest": 0
  },
  "last_updated": "Timestamp"
}
```

**Subcollection:** `players/{uid}/sessions`
**Document:** `players/{uid}/sessions/{session_id}`
```json
{
  "session_id": "uuid-v4",
  "player_id": "firebase_uid",
  "player_class": "warrior",
  "theme": "enchanted_forest",
  "difficulty_level": 3,
  "won": false,
  "score": 450,
  "floors_cleared": 2,
  "enemies_killed": 8,
  "death_cause": "shadow_mage",
  "death_floor": 3,
  "total_turns": 67,
  "session_duration_seconds": 420,
  "ai_decisions_made": 14,
  "dm_difficulty_applied": 3,
  "dm_theme_chosen": "enchanted_forest",
  "dm_reasoning_summary": "Player has 80% loss rate. Easy mode applied.",
  "started_at": "Timestamp",
  "ended_at": "Timestamp"
}
```

**Firestore Indexes Required:**
```
players/{uid}/sessions:
  - started_at DESC (for last_5_sessions query)

sessions collection (global):
  - player_id ASC + started_at DESC
```

---

### Collection: `sessions` (Global — for DM agent cross-reference)

**Path:** `sessions/{session_id}`

```json
{
  "session_id": "uuid-v4",
  "player_id": "firebase_uid",
  "player_class": "warrior",
  "theme": "enchanted_forest",
  "difficulty_level": 3,
  "status": "active",
  "current_floor": 1,
  "started_at": "Timestamp",
  "last_updated": "Timestamp"
}
```

**Status values:** `"active"` | `"won"` | `"lost"` | `"abandoned"`

---

### Collection: `traces`

**Path:** `traces/{session_id}`

**Document:**
```json
{
  "session_id": "uuid-v4",
  "player_id": "firebase_uid",
  "total_decisions": 0,
  "agents_used": [],
  "created_at": "Timestamp",
  "last_updated": "Timestamp"
}
```

**Subcollection:** `traces/{session_id}/entries`
**Document:** `traces/{session_id}/entries/{trace_id}` (auto-ID)

```json
{
  "trace_id": "auto-generated-id",
  "session_id": "uuid-v4",
  "agent": "DungeonMasterAgent",
  "floor_number": 1,
  "turn_number": 0,
  "step": 1,
  "timestamp": "Timestamp",
  "reasoning": "Player has 80% loss rate. Applying easy mode.",
  "tool_called": "compute_player_stats",
  "tool_input": {
    "wins": 2,
    "losses": 8,
    "total_sessions": 10
  },
  "tool_output": {
    "loss_rate": 0.8,
    "category": "struggling"
  },
  "decision": "Setting difficulty to 3/10. Reducing enemy speed to 0.8x.",
  "duration_ms": 1240,
  "model_used": "gemini-3.1-flash-lite-thinking-exp",
  "fallback_used": false
}
```

**Firestore Rule:** Traces are read-only from Flutter (player can VIEW but not modify).

---

### Collection: `levels` (Cache for Generated Levels)

**Path:** `levels/{level_hash}`

**Document:**
```json
{
  "level_hash": "md5_of_difficulty_theme_class",
  "theme": "enchanted_forest",
  "difficulty_level": 3,
  "player_class": "warrior",
  "floor_number": 1,
  "level_data": {
    "level_id": "uuid",
    "grid": [[...]],
    "player_start": [1,1],
    "exit_position": [8,8],
    "enemies": [...],
    "items": [...],
    "narrative_hook": "...",
    "difficulty_score": 3.2,
    "enemy_count": 2,
    "estimated_turns_to_clear": 18
  },
  "generated_at": "Timestamp",
  "used_count": 1,
  "last_used": "Timestamp"
}
```

**Cache Logic:**
- Hash = `md5(f"{difficulty_level}_{theme}_{player_class}_{floor_number}")`
- If document exists AND less than 24 hours old: return cached level
- Otherwise: generate new level, save to this collection

---

### Collection: `leaderboard`

**Path:** `leaderboard/{uid}`

```json
{
  "uid": "firebase_uid",
  "display_name": "Player",
  "score": 4820,
  "floors_cleared": 5,
  "class_used": "mage",
  "theme": "cursed_library",
  "achieved_at": "Timestamp",
  "session_id": "uuid-v4"
}
```

**Update Logic:** Only write if `score > current leaderboard score` for this UID.
**Query:** `leaderboard orderBy("score", "desc") limit(20)`

---

## FIREBASE REALTIME DATABASE SCHEMA

**Used for:** Live game state sync during active session (low latency).

**Path:** `/sessions/{session_id}/live_state`

```json
{
  "sessions": {
    "{session_id}": {
      "live_state": {
        "player": {
          "position": [3, 5],
          "hp": 85,
          "max_hp": 150,
          "turn_count": 14,
          "score": 180,
          "enemies_killed": 4,
          "floors_cleared": 1
        },
        "current_floor": {
          "floor_number": 2,
          "enemies_alive": 2,
          "items_remaining": 1
        },
        "ai_status": {
          "is_thinking": false,
          "last_agent": "RivalAgent",
          "last_decision_summary": "Goblin flanked right — detected rush pattern",
          "last_updated": 1716000000000
        },
        "session_status": "active",
        "last_updated": 1716000000000
      }
    }
  }
}
```

**Flutter listener:**
```dart
// Listen to ai_status for real-time AI panel updates
FirebaseDatabase.instance
  .ref('/sessions/$sessionId/live_state/ai_status')
  .onValue
  .listen((event) {
    final data = event.snapshot.value as Map;
    ref.read(gameStateProvider.notifier).updateAiStatus(data);
  });
```

**Backend write (after every agent call):**
```python
rtdb.reference(f"/sessions/{session_id}/live_state/ai_status").set({
    "is_thinking": False,
    "last_agent": "RivalAgent",
    "last_decision_summary": trace.decision[:80],
    "last_updated": {".sv": "timestamp"}
})
```

---

## REDIS SCHEMA

### Session Working Memory

**Key:** `session:{session_id}:dm_plan`
**Type:** String (JSON)
**TTL:** 3600 seconds (1 hour)
```json
{
  "difficulty_level": 3,
  "theme": "enchanted_forest",
  "enemy_speed_multiplier": 0.8,
  "item_drop_rate": 1.5,
  "boss_difficulty": 2,
  "created_at": 1716000000
}
```

**Key:** `session:{session_id}:player_tactics`
**Type:** String (JSON)
**TTL:** 3600 seconds
```json
{
  "dominant_direction": "right",
  "prefers_melee": true,
  "prefers_ranged": false,
  "retreats_when_low_hp": false,
  "corners_preference": false,
  "turns_observed": 14,
  "move_history": ["right","right","attack","up","right","attack","right","down"],
  "last_updated": 1716000100
}
```

**Key:** `session:{session_id}:npc_memory:{enemy_id}`
**Type:** String (JSON)
**TTL:** 3600 seconds
```json
{
  "enemy_id": "e1",
  "turns_taken": 5,
  "current_strategy": "ranged_because_player_melee",
  "last_action": "move",
  "last_position": [4, 6],
  "player_killed": false
}
```

### Level Cache

**Key:** `level:{hash}`
**Type:** String (JSON)
**TTL:** 86400 seconds (24 hours)
```json
{
  "level_id": "uuid",
  "grid": [[...]],
  "player_start": [1,1],
  "exit_position": [8,8],
  "enemies": [...],
  "items": [...],
  "cached_at": 1716000000
}
```

**Hash computation:**
```python
import hashlib, json
params = f"{difficulty_level}_{theme}_{player_class}_{floor_number}"
level_hash = hashlib.md5(params.encode()).hexdigest()[:16]
```

### Player History Cache

**Key:** `player:{uid}:history`
**Type:** String (JSON)
**TTL:** 300 seconds (5 minutes — refresh after each session)
```json
{
  "total_sessions": 10,
  "wins": 2,
  "losses": 8,
  "avg_floors_cleared": 2.3,
  "last_5_sessions": [...],
  "favorite_death_cause": "shadow_mage",
  "total_enemies_killed": 64,
  "cached_at": 1716000000
}
```

### NPC Decision Cache

**Key:** `npc:{hash_of_enemy_and_board_state}`
**Type:** String (JSON)
**TTL:** 30 seconds
```json
{
  "action_type": "attack",
  "direction": null,
  "target_position": [3, 5],
  "damage": 5,
  "reasoning": "Player adjacent. Direct attack.",
  "cached_at": 1716000000
}
```

**Hash computation:**
```python
state_str = json.dumps({
    "enemy_pos": enemy_state["position"],
    "enemy_hp_bucket": enemy_state["hp"] // 10,  # Bucket HP to increase cache hits
    "player_pos": player_state["position"],
    "last_2_moves": player_last_5_moves[-2:]
})
decision_hash = hashlib.md5(state_str.encode()).hexdigest()[:12]
```

### Rate Limiting

**Key:** `ratelimit:{uid}:agent_calls`
**Type:** Integer (counter)
**TTL:** 60 seconds
```
Limit: 60 agent calls per minute per player
If counter > 60: return 429 (Too Many Requests)
Increment on every /agent/* call
```

---

## FIRESTORE SECURITY RULES

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Players can read/write their own document only
    match /players/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;

      match /stats/{document} {
        allow read: if request.auth != null && request.auth.uid == uid;
        allow write: if false; // Backend only
      }

      match /sessions/{sessionId} {
        allow read: if request.auth != null && request.auth.uid == uid;
        allow write: if false; // Backend only
      }
    }

    // Traces are read-only from client
    match /traces/{sessionId} {
      allow read: if request.auth != null;
      allow write: if false; // Backend only
    }

    // Leaderboard is public read
    match /leaderboard/{uid} {
      allow read: if true;
      allow write: if false; // Backend only
    }

    // Levels cache — backend only
    match /levels/{levelHash} {
      allow read, write: if false; // Backend only
    }
  }
}
```

---

## REALTIME DATABASE SECURITY RULES

```json
{
  "rules": {
    "sessions": {
      "$session_id": {
        "live_state": {
          ".read": "auth != null",
          ".write": false
        }
      }
    }
  }
}
```

---

## FIRESTORE OPERATIONS (Python — Backend)

```python
# firebase_service.py

class FirebaseService:

    async def get_player_history(self, uid: str) -> dict:
        """Get player stats and last 5 sessions. Checks Redis first."""
        # Check cache
        cached = redis.get(f"player:{uid}:history")
        if cached:
            return json.loads(cached)

        # Firestore read
        stats_doc = fs.collection("players").document(uid) \
                      .collection("stats").document("all_time").get()

        sessions = fs.collection("players").document(uid) \
                     .collection("sessions") \
                     .order_by("started_at", direction=Query.DESCENDING) \
                     .limit(5).get()

        history = {
            "total_sessions": stats_doc.get("total_sessions") or 0,
            "wins": stats_doc.get("wins") or 0,
            "losses": stats_doc.get("losses") or 0,
            "avg_floors_cleared": stats_doc.get("avg_floors_cleared") or 0.0,
            "total_enemies_killed": stats_doc.get("total_enemies_killed") or 0,
            "favorite_death_cause": stats_doc.get("favorite_death_cause"),
            "last_5_sessions": [s.to_dict() for s in sessions]
        }

        # Cache result
        redis.setex(f"player:{uid}:history", 300, json.dumps(history))
        return history

    async def save_session(self, session_data: dict) -> None:
        """Save completed session. Updates stats atomically."""
        uid = session_data["player_id"]
        session_id = session_data["session_id"]

        # Write session document
        fs.collection("players").document(uid) \
          .collection("sessions").document(session_id).set(session_data)

        # Update stats atomically
        stats_ref = fs.collection("players").document(uid) \
                      .collection("stats").document("all_time")
        
        stats_ref.update({
            "total_sessions": Increment(1),
            "wins": Increment(1 if session_data["won"] else 0),
            "losses": Increment(0 if session_data["won"] else 1),
            "total_floors_cleared": Increment(session_data["floors_cleared"]),
            "total_enemies_killed": Increment(session_data["enemies_killed"]),
            "last_updated": SERVER_TIMESTAMP
        })

        # Update leaderboard if new high score
        leaderboard_ref = fs.collection("leaderboard").document(uid)
        current = leaderboard_ref.get()
        if not current.exists or current.get("score") < session_data["score"]:
            leaderboard_ref.set({
                "uid": uid,
                "display_name": session_data.get("display_name", "Player"),
                "score": session_data["score"],
                "floors_cleared": session_data["floors_cleared"],
                "class_used": session_data["player_class"],
                "theme": session_data["theme"],
                "achieved_at": SERVER_TIMESTAMP,
                "session_id": session_id
            })

        # Invalidate cache
        redis.delete(f"player:{uid}:history")

    async def save_traces(self, session_id: str, traces: list[dict]) -> None:
        """Save agent trace entries to Firestore."""
        batch = fs.batch()
        for trace in traces:
            ref = fs.collection("traces").document(session_id) \
                    .collection("entries").document()
            batch.set(ref, {**trace, "timestamp": SERVER_TIMESTAMP})
        batch.commit()
```

---

## DATA FLOW EXAMPLES

### New Player First Run
```
1. Firebase Auth creates user → UID: "abc123"
2. Flutter calls POST /agent/dungeon-master {"player_id": "abc123", "player_class": "warrior"}
3. Backend: get_player_history("abc123")
   → Firestore: players/abc123/stats/all_time → MISSING (new player)
   → Return empty history: {total_sessions: 0, wins: 0, losses: 0}
4. DungeonMasterAgent sees empty history → picks difficulty 3 + enchanted_forest
5. Session saved to: sessions/{session_id}
6. Traces saved to: traces/{session_id}/entries/*
```

### Returning Player (8 Losses)
```
1. Auth: UID "abc123" already exists
2. POST /agent/dungeon-master
3. Backend: get_player_history("abc123")
   → Redis cache hit: returns cached history
   → history.losses = 8, history.wins = 2, loss_rate = 0.8
4. DungeonMasterAgent: loss_rate > 70% → easy mode (difficulty 2, items+)
5. DM reasoning: "80% loss rate. Easy mode. Enchanted forest (easiest)."
6. Trace logged to Firestore: step 1-4 reasoning
```

---

*Redis is the performance layer. Firestore is the truth layer.*
*Always read from Redis first. Always write truth to Firestore.*
*Never let a database failure crash the game — all DB operations have try/except.*
