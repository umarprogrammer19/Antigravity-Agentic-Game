# DungeonMind — Agent Trace Format Specification
### How AI Decision Traces Are Generated, Stored, and Displayed
### Reference for: AI Systems Engineer Agent, Flutter Architect Agent
---

## WHY TRACES MATTER

Agent traces are worth **30% of your hackathon score**.
They are NOT optional. They ARE the proof that AI is working.

Judges want to see:
1. That the AI PLANNED (not just generated)
2. That the AI REASONED (with specific data, not generic text)
3. That the AI ACTED (decision produced a concrete output)
4. That the decisions were NON-TRIVIAL (not just "difficulty set to 5")

A good trace reads like: *"I saw X → I computed Y → I decided Z because of W."*
A bad trace reads like: *"Agent ran. Result produced."*

---

## TRACE ENTRY STRUCTURE

Every trace entry captures ONE reasoning step from ONE agent.
Complex agents log multiple steps (4 for DM, 4 for LevelGenerator, etc.)

### Full Trace Entry Schema
```json
{
  "trace_id": "auto-firestore-id",
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "agent": "DungeonMasterAgent",
  "floor_number": 1,
  "turn_number": 0,
  "step": 2,
  "timestamp": "2026-05-18T10:32:01.234567Z",
  "reasoning": "Player has 80% loss rate (8 losses / 10 total sessions). This categorizes them as 'struggling'. Decision matrix requires difficulty 1-4 for >70% loss rate.",
  "tool_called": "compute_player_stats",
  "tool_input": {
    "wins": 2,
    "losses": 8,
    "total_sessions": 10,
    "last_5_sessions": [
      {"won": false, "floors_cleared": 2},
      {"won": false, "floors_cleared": 1},
      {"won": false, "floors_cleared": 3},
      {"won": true,  "floors_cleared": 5},
      {"won": false, "floors_cleared": 2}
    ]
  },
  "tool_output": {
    "loss_rate": 0.8,
    "category": "struggling",
    "recommended_difficulty_range": "1-4",
    "avg_floors_cleared_last_5": 2.6,
    "recent_win": true
  },
  "decision": "Setting difficulty to 3/10. enemy_speed_multiplier=0.8 (slower enemies). item_drop_rate=1.5 (more healing). Targeting average player experience between challenge and success.",
  "duration_ms": 1240,
  "model_used": "gemini-2.5-flash-thinking-exp",
  "tokens_used": 342,
  "fallback_used": false,
  "agent_version": "1.0.0"
}
```

### Field-by-Field Explanation

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `trace_id` | string | Unique ID (Firestore auto-gen) | "Kd7aB..." |
| `session_id` | string | Links trace to session | "550e8400..." |
| `agent` | string | Which agent generated this | "DungeonMasterAgent" |
| `floor_number` | int | Which floor this happened on | 1 |
| `turn_number` | int | Which game turn (0 = pre-game) | 0 |
| `step` | int | Step number within agent run | 2 |
| `timestamp` | ISO 8601 | When this step ran | "2026-05-18..." |
| `reasoning` | string | WHY the agent did this | "Loss rate 80% → easy mode" |
| `tool_called` | string | Which tool was used | "compute_player_stats" |
| `tool_input` | dict | Exact data passed to tool | {"wins": 2, ...} |
| `tool_output` | dict | Exact result from tool | {"loss_rate": 0.8} |
| `decision` | string | What was decided/changed | "Difficulty → 3, speed → 0.8x" |
| `duration_ms` | int | How long this step took | 1240 |
| `model_used` | string | Gemini model variant | "gemini-2.5-flash" |
| `tokens_used` | int | Token usage for this call | 342 |
| `fallback_used` | bool | Was AI used or fallback? | false |

---

## BASEAGENT IMPLEMENTATION

```python
# mobile-game-server/agents/base_agent.py

import time
from datetime import datetime, timezone
from abc import ABC, abstractmethod
from typing import Any
import google.generativeai as genai
from models.trace import TraceEntry


class BaseAgent(ABC):
    """
    Base class for all DungeonMind AI agents.
    Provides tracing, Gemini client, and error handling.
    """

    model_name: str = "gemini-2.5-flash"
    agent_version: str = "1.0.0"

    def __init__(self, session_id: str, floor_number: int = 1, turn_number: int = 0):
        self.session_id = session_id
        self.floor_number = floor_number
        self.turn_number = turn_number
        self._traces: list[TraceEntry] = []
        self._step_counter = 0

        # Initialize Gemini client
        self._model = genai.GenerativeModel(
            model_name=self.model_name,
            system_instruction=self._get_system_prompt()
        )

    @property
    def agent_name(self) -> str:
        return self.__class__.__name__

    def _get_system_prompt(self) -> str:
        """Override in subclass to return the system prompt."""
        raise NotImplementedError

    @abstractmethod
    async def run(self, context: dict) -> dict:
        """Execute the agent's main logic. Returns result dict."""
        pass

    def log_trace(
        self,
        reasoning: str,
        tool_called: str,
        tool_input: dict,
        tool_output: dict,
        decision: str,
        duration_ms: int = 0,
        fallback_used: bool = False,
        tokens_used: int = 0,
    ) -> TraceEntry:
        """
        Log one reasoning step. Call this after every meaningful action.
        This is what judges evaluate — be descriptive!
        """
        self._step_counter += 1

        entry = TraceEntry(
            session_id=self.session_id,
            agent=self.agent_name,
            floor_number=self.floor_number,
            turn_number=self.turn_number,
            step=self._step_counter,
            timestamp=datetime.now(timezone.utc).isoformat(),
            reasoning=reasoning,
            tool_called=tool_called,
            tool_input=tool_input,
            tool_output=tool_output,
            decision=decision,
            duration_ms=duration_ms,
            model_used=self.model_name,
            tokens_used=tokens_used,
            fallback_used=fallback_used,
            agent_version=self.agent_version,
        )

        self._traces.append(entry)
        return entry

    def get_traces(self) -> list[TraceEntry]:
        """Return all trace entries from this agent run."""
        return self._traces

    async def _call_gemini(
        self,
        user_prompt: str,
        generation_config: genai.GenerationConfig,
    ) -> tuple[str, int]:
        """
        Call Gemini API with timing and token tracking.
        Returns (response_text, tokens_used).
        """
        start = time.time()
        response = await self._model.generate_content_async(
            user_prompt,
            generation_config=generation_config
        )
        duration_ms = int((time.time() - start) * 1000)
        tokens = response.usage_metadata.total_token_count if response.usage_metadata else 0
        return response.text, tokens, duration_ms

    def _safe_parse_json(self, json_str: str, model_class: type) -> tuple[Any, str | None]:
        """
        Parse and validate JSON. Returns (parsed_object, error_message).
        error_message is None if successful.
        """
        import json
        from pydantic import ValidationError

        try:
            raw = json.loads(json_str)
            validated = model_class.model_validate(raw)
            return validated, None
        except json.JSONDecodeError as e:
            return None, f"JSON parse error: {e}"
        except ValidationError as e:
            return None, f"Schema validation error: {e.json()}"
```

---

## TRACE EXAMPLES BY AGENT

### DungeonMasterAgent — 4 Steps Per Session

**Step 1: Read and analyze player history**
```json
{
  "step": 1,
  "agent": "DungeonMasterAgent",
  "reasoning": "Reading player history from Firestore. Player has played 10 sessions with 2 wins and 8 losses. Computing key metrics.",
  "tool_called": "read_player_history",
  "tool_input": {"player_id": "uid_abc123"},
  "tool_output": {
    "total_sessions": 10,
    "wins": 2,
    "losses": 8,
    "avg_floors_cleared": 2.3,
    "favorite_death_cause": "shadow_mage",
    "last_5_won": [false, false, false, true, false]
  },
  "decision": "Player history loaded. Computing performance category."
}
```

**Step 2: Compute difficulty**
```json
{
  "step": 2,
  "reasoning": "loss_rate = 8/10 = 0.80. This exceeds the 70% threshold for 'struggling' category. Decision matrix requires: difficulty 1-4, item_drop_rate 1.5, enemy_speed 0.8. Player's avg_floors_cleared is 2.3, so difficulty 3 is appropriate (achievable but slightly above average).",
  "tool_called": "compute_difficulty_params",
  "tool_input": {"loss_rate": 0.8, "avg_floors_cleared": 2.3},
  "tool_output": {
    "difficulty_level": 3,
    "category": "struggling",
    "enemy_speed_multiplier": 0.8,
    "item_drop_rate": 1.5,
    "boss_difficulty": 2
  },
  "decision": "Difficulty set to 3/10. Enemy speed reduced 20%. Item drop increased 50%. Target: let player experience 3-4 floors successfully."
}
```

**Step 3: Select theme**
```json
{
  "step": 3,
  "reasoning": "Checking player's theme history. Lost 3 times in cursed_library, 2 times in volcanic_caves, won once in enchanted_forest. For struggling players, select easiest theme. enchanted_forest has widest corridors and lowest enemy aggression.",
  "tool_called": "select_theme",
  "tool_input": {"history_by_theme": {"cursed_library": 3, "volcanic_caves": 2, "enchanted_forest": 1}},
  "tool_output": {"selected_theme": "enchanted_forest", "reason": "easiest theme, player had their only win here"},
  "decision": "Theme: enchanted_forest. Provides most navigable layout and least aggressive enemies."
}
```

**Step 4: Finalize and package session plan**
```json
{
  "step": 4,
  "reasoning": "All parameters computed. Generating session plan with narrative intro that matches enchanted_forest theme. Strategy hint focuses on isolating enemies (player died to multi-enemy engagements).",
  "tool_called": "finalize_session_plan",
  "tool_input": {"all_params": "..."},
  "tool_output": {"session_plan": "..."},
  "decision": "Session plan complete. Player will face difficulty 3/10 in enchanted_forest. Increased healing availability (1.5x items). Slower enemies (0.8x speed). Narrative: forest theme, ominous but navigable."
}
```

---

### LevelGeneratorAgent — 4 Steps Per Floor

**Step 1: Analyze parameters and decide structure**
```json
{
  "step": 1,
  "reasoning": "Floor 1, difficulty 3, theme enchanted_forest. Difficulty 3 maps to 10x10 grid. Enemy count for difficulty 3: 3 enemies. Item count: round(1.5 * 1.5) = 2 items. Player HP is 150 (full health), no emergency healing needed.",
  "tool_called": "analyze_level_params",
  "tool_input": {"floor": 1, "difficulty": 3, "theme": "enchanted_forest", "player_hp": 150},
  "tool_output": {"grid_size": "10x10", "enemy_count": 3, "item_count": 2, "has_lava": false}
}
```

**Step 2: Generate grid layout**
```json
{
  "step": 2,
  "reasoning": "Generating 10x10 grid for enchanted_forest. Style: open rooms connected by corridors. Wall density: 25%. Ensuring border tiles are all walls (0). Creating multiple paths to exit for navigability.",
  "tool_called": "generate_grid",
  "tool_input": {"rows": 10, "cols": 10, "wall_density": 0.25, "style": "open_rooms"},
  "tool_output": {"grid_generated": true, "floor_tiles": 58, "wall_tiles": 42}
}
```

**Step 3: Place entities**
```json
{
  "step": 3,
  "reasoning": "Placing 3 enemies minimum 3 tiles from player_start [1,1]. Enchanted_forest enemies: goblin (rush_melee), forest_witch (ranged_2tile), druid (heals_nearby). Placing 2 items: health_potion at mid-map, damage_boost near exit to reward exploration.",
  "tool_called": "place_entities",
  "tool_input": {"player_start": [1,1], "exit": [8,8]},
  "tool_output": {
    "enemies_placed": [{"type":"goblin","pos":[4,5]},{"type":"forest_witch","pos":[7,3]},{"type":"druid","pos":[5,8]}],
    "items_placed": [{"type":"health_potion","pos":[3,8]},{"type":"damage_boost","pos":[7,7]}]
  }
}
```

**Step 4: Validate level balance**
```json
{
  "step": 4,
  "reasoning": "Running path validation: BFS from [1,1] to [8,8] — path exists. Checking enemy placement distances — all >3 tiles from player start. Estimating turns to clear: 3 enemies × 4 turns each + navigation ≈ 20 turns. Difficulty score: 3.2/10.",
  "tool_called": "validate_level",
  "tool_input": {"grid": "...", "player_start": [1,1], "exit": [8,8]},
  "tool_output": {"path_valid": true, "min_distance_to_closest_enemy": 4, "estimated_turns": 20, "difficulty_score": 3.2}
}
```

---

### RivalAgent — 1-2 Steps Per Enemy Turn

```json
{
  "step": 1,
  "agent": "RivalAgent",
  "floor_number": 2,
  "turn_number": 14,
  "reasoning": "Enemy e1 (Goblin, hp=15/20) at [4,5]. Player at [3,5] — adjacent (distance=1). Player last 5 moves: right,right,attack,up,right. Pattern: player prefers moving right and attacking immediately. tactics profile shows prefers_melee=true, dominant_direction=right. Goblin is at 75% HP — still combat effective. Optimal: direct attack. Player is adjacent so no movement needed.",
  "tool_called": "decide_enemy_action",
  "tool_input": {
    "enemy_pos": [4,5],
    "player_pos": [3,5],
    "distance": 1,
    "enemy_hp_percent": 0.75,
    "tactic_override": "attack_adjacent_player"
  },
  "tool_output": {
    "action": "attack",
    "target": [3,5],
    "damage": 5,
    "counter_detected": false
  },
  "decision": "Goblin attacks player directly (adjacent). 8 attack - 3 effective defense = 5 damage. No tactic counter needed yet (only 14 turns observed)."
}
```

---

### NarrativeAgent — 1 Step Per Event

```json
{
  "step": 1,
  "agent": "NarrativeAgent",
  "reasoning": "Event: floor_cleared. Floor 2 cleared. Player killed 3 enemies in 22 turns. Theme: enchanted_forest. Player class: warrior. Generating transition text that acknowledges their combat efficiency and creates anticipation for floor 3.",
  "tool_called": "generate_narrative",
  "tool_input": {"event": "floor_cleared", "enemies_killed": 3, "turns": 22, "theme": "enchanted_forest"},
  "tool_output": {"text": "Three fallen. The forest remembers. Floor 3 waits, darker than before."},
  "decision": "Generated floor_cleared narrative for enchanted_forest. 7 words, dark tone, forward momentum. Cached for similar floor transitions."
}
```

---

### RefereeAgent — 1 Step Per Player Action

```json
{
  "step": 1,
  "agent": "RefereeAgent",
  "turn_number": 14,
  "reasoning": "Player (warrior, attack=20, defense=8, pos=[3,5]) attacked enemy e1 (goblin, hp=15, defense=3) at [4,5]. Using standard damage formula: max(1, 20-3) = 17 damage. Enemy HP: 15-17=-2 → enemy dies. XP = floor(20/5) = 4.",
  "tool_called": "validate_attack_action",
  "tool_input": {"player_attack": 20, "enemy_defense": 3, "enemy_hp": 15},
  "tool_output": {"damage": 17, "enemy_survives": false, "xp_granted": 4},
  "decision": "Attack valid. 17 damage dealt. Goblin e1 eliminated. +4 XP awarded. Standard formula applied — no AI call needed.",
  "model_used": "none (pure_python)",
  "tokens_used": 0
}
```

---

## TRACE STORAGE PATTERN

```python
# After every agent.run() completes:

async def save_agent_traces(
    session_id: str,
    traces: list[TraceEntry],
    background_tasks: BackgroundTasks
) -> None:
    """Save traces to Firestore in background (non-blocking)."""
    background_tasks.add_task(_write_traces_to_firestore, session_id, traces)

async def _write_traces_to_firestore(session_id: str, traces: list[TraceEntry]) -> None:
    batch = fs.batch()

    # Update parent doc (increment count, add agent to list)
    parent_ref = fs.collection("traces").document(session_id)
    batch.set(parent_ref, {
        "session_id": session_id,
        "total_decisions": Increment(len(traces)),
        "agents_used": ArrayUnion([t.agent for t in traces]),
        "last_updated": SERVER_TIMESTAMP
    }, merge=True)

    # Write each trace entry
    for trace in traces:
        entry_ref = parent_ref.collection("entries").document()
        batch.set(entry_ref, trace.model_dump())

    batch.commit()

    # Also update Firebase Realtime DB for live UI
    for trace in traces[-1:]:  # Only latest trace for live panel
        rtdb.reference(f"/sessions/{session_id}/live_state/ai_status").update({
            "last_agent": trace.agent,
            "last_decision_summary": trace.decision[:80],
            "last_updated": {".sv": "timestamp"},
            "is_thinking": False
        })
```

---

## TRACE DISPLAY IN FLUTTER

```dart
// lib/features/traces/widgets/trace_entry_card.dart

class TraceEntryCard extends StatefulWidget {
  final TraceEntry trace;

  // Agent color + abbreviation
  Color get agentColor => {
    'DungeonMasterAgent': const Color(0xFFD4AF37),   // Gold
    'LevelGeneratorAgent': const Color(0xFF059669),  // Emerald
    'RivalAgent': const Color(0xFFEF4444),           // Crimson
    'NarrativeAgent': const Color(0xFF7C3AED),       // Violet
    'RefereeAgent': const Color(0xFF2563EB),         // Sapphire
  }[trace.agent] ?? Colors.grey;

  String get agentAbbrev => {
    'DungeonMasterAgent': 'DM',
    'LevelGeneratorAgent': 'LG',
    'RivalAgent': 'NPC',
    'NarrativeAgent': 'NAR',
    'RefereeAgent': 'REF',
  }[trace.agent] ?? '?';
}

// Collapsed view (default):
//   [●DM] DungeonMasterAgent · Step 2 · 10:32:01
//   "Player has 80% loss rate. Applying easy mode."
//   ✓ Setting difficulty to 3/10                    1240ms

// Expanded view (tap to expand):
//   [●DM] DungeonMasterAgent · Step 2 · 10:32:01
//   ─────────────────────────────────────────────
//   📋 REASONING
//   "Player has 80% loss rate across 10 sessions..."
//
//   🔧 TOOL: compute_player_stats
//   INPUT:  { "wins": 2, "losses": 8 }
//   OUTPUT: { "loss_rate": 0.8, "category": "struggling" }
//
//   ✓ DECISION
//   "Setting difficulty to 3/10. enemy_speed → 0.8x"
//
//   gemini-2.5-flash-thinking-exp · 342 tokens · 1240ms
```

---

## WHAT MAKES A GREAT TRACE (Judges' Perspective)

### ✅ Strong Traces Look Like
```
reasoning: "Player has 80% loss rate (8/10 sessions). 
            This exceeds the 70% threshold. 
            Per decision matrix: difficulty must be 1-4. 
            Avg floors cleared is 2.3, so difficulty 3 is right 
            (challenging but achievable for their level)."

decision: "difficulty_level=3, enemy_speed=0.8x (20% slower), 
           item_drop=1.5x (50% more healing). 
           Target: player clears floors 3-4 this session."
```

### ❌ Weak Traces Look Like
```
reasoning: "Setting difficulty based on player performance."
decision: "Difficulty set."
```

### Key Characteristics of Strong Traces
1. **Specific numbers** — Not "high loss rate" but "80% loss rate (8/10 sessions)"
2. **Explicit logic** — Not "reduced difficulty" but "loss_rate > 70% → difficulty 1-4 per matrix"
3. **Tool input/output are real data** — Not empty dicts `{}`
4. **Decision states concrete changes** — Not "adjusted" but "speed 1.0→0.8x, items 1.0→1.5x"
5. **Reasoning is connected** — Each step explains why based on the previous step

---

*The trace system is your judge interface.*
*Every line of reasoning is an argument that Antigravity + Gemini created a real AI system.*
*Make every trace entry worth reading.*
