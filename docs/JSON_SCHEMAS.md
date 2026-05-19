# DungeonMind — JSON Schemas
### Complete Data Structure Definitions for All Game Objects
### Reference for: ALL agents — these are the contracts between frontend and backend
---

## HOW TO USE THIS DOCUMENT

Every JSON structure in DungeonMind is defined here exactly once.
Backend Pydantic models MUST match these schemas.
Flutter Dart models MUST match these schemas.
If they conflict, this document wins — fix the code.

---

## SCHEMA 1: SessionPlan
**Produced by:** DungeonMasterAgent
**Consumed by:** Flutter (game session start), LevelGeneratorAgent

```json
{
  "$schema": "SessionPlan",
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "player_id": "firebase_uid_string",
  "player_class": "warrior",
  "difficulty_level": 3,
  "theme": "enchanted_forest",
  "enemy_speed_multiplier": 0.8,
  "item_drop_rate": 1.5,
  "enemy_count_multiplier": 0.9,
  "boss_difficulty": 2,
  "narrative_intro": "The ancient forest closes around you. Something old stirs in the roots.",
  "dm_reasoning": "Player has 80% loss rate across 10 sessions. Applying easy mode. Enchanted forest selected as easiest theme. Item drop rate increased to provide more healing opportunities.",
  "recommended_strategy": "Engage enemies one at a time. Use items immediately when found.",
  "ai_used": true,
  "fallback_used": false,
  "agent_trace_id": "trace_550e8400",
  "processing_time_ms": 2340,
  "created_at": "2026-05-18T10:32:00Z"
}
```

**Field Constraints:**
```
session_id:              string, UUID v4 format, REQUIRED
player_id:               string, Firebase UID, REQUIRED
player_class:            enum ["warrior", "mage", "ranger"], REQUIRED
difficulty_level:        integer, 1-10 inclusive, REQUIRED
theme:                   enum ["cursed_library", "volcanic_caves", "enchanted_forest"], REQUIRED
enemy_speed_multiplier:  float, 0.6-1.5, REQUIRED
item_drop_rate:          float, 0.5-2.0, REQUIRED
enemy_count_multiplier:  float, 0.7-1.5, REQUIRED
boss_difficulty:         integer, 1-5, REQUIRED
narrative_intro:         string, max 300 chars, REQUIRED
dm_reasoning:            string, min 50 chars (must be specific), REQUIRED
recommended_strategy:    string, max 200 chars, REQUIRED
ai_used:                 boolean, REQUIRED
fallback_used:           boolean, REQUIRED
agent_trace_id:          string | null
processing_time_ms:      integer
created_at:              ISO 8601 datetime string
```

**Pydantic Model:**
```python
class SessionPlan(BaseModel):
    session_id: str = Field(default_factory=lambda: str(uuid4()))
    player_id: str
    player_class: Literal["warrior", "mage", "ranger"]
    difficulty_level: int = Field(ge=1, le=10)
    theme: Literal["cursed_library", "volcanic_caves", "enchanted_forest"]
    enemy_speed_multiplier: float = Field(ge=0.6, le=1.5)
    item_drop_rate: float = Field(ge=0.5, le=2.0)
    enemy_count_multiplier: float = Field(ge=0.7, le=1.5, default=1.0)
    boss_difficulty: int = Field(ge=1, le=5)
    narrative_intro: str = Field(max_length=300)
    dm_reasoning: str = Field(min_length=50)
    recommended_strategy: str = Field(max_length=200)
    ai_used: bool = True
    fallback_used: bool = False
    agent_trace_id: str | None = None
    processing_time_ms: int | None = None
    created_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
```

**Dart Model:**
```dart
class SessionPlan {
  final String sessionId;
  final String playerClass;
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

  factory SessionPlan.fromJson(Map<String, dynamic> json) => SessionPlan(
    sessionId: json['session_id'],
    playerClass: json['player_class'],
    difficultyLevel: json['difficulty_level'],
    theme: json['theme'],
    enemySpeedMultiplier: (json['enemy_speed_multiplier'] as num).toDouble(),
    itemDropRate: (json['item_drop_rate'] as num).toDouble(),
    enemyCountMultiplier: (json['enemy_count_multiplier'] as num).toDouble(),
    bossDifficulty: json['boss_difficulty'],
    narrativeIntro: json['narrative_intro'],
    dmReasoning: json['dm_reasoning'],
    recommendedStrategy: json['recommended_strategy'],
    aiUsed: json['ai_used'],
    fallbackUsed: json['fallback_used'],
  );
}
```

---

## SCHEMA 2: LevelSchema
**Produced by:** LevelGeneratorAgent
**Consumed by:** Flutter Flame engine, RivalAgent, RefereeAgent

```json
{
  "$schema": "LevelSchema",
  "level_id": "550e8400-e29b-41d4-a716-446655440001",
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
  "agent_trace_id": "trace_550e8401",
  "processing_time_ms": 2870
}
```

**Tile Value Reference:**
```
0 = WALL         — Impassable. Dark gray/black.
1 = FLOOR        — Walkable. Brown/tan.
2 = (unused)     — Reserved for future use.
3 = LAVA         — Walkable, deals 5 damage per step. Orange/red. Volcanic theme only.
4 = TRAP         — Appears as floor. Deals 15 damage on first step. Revealed after trigger.
5 = (unused)     — Reserved. Items are tracked in items[] array, not grid value.
```

**Enemy Types by Theme:**
```
cursed_library:  shadow_mage | book_golem | librarian
volcanic_caves:  fire_elemental | rock_troll | lava_sprite
enchanted_forest: goblin | forest_witch | druid
```

**Behavior Types:**
```
rush_melee      — Moves toward player every turn, attacks if adjacent
ranged_2tile    — Stays 2 tiles away, attacks from distance
tank_melee      — Slow melee, very high HP/defense
flee_then_attack— Retreats if adjacent, attacks from 2 tiles
slow_tank       — Moves every 2 turns, high HP
hit_and_run     — Attack adjacent, then move away
swarm_melee     — Like rush_melee but spawns in groups
heals_nearby    — Moves to adjacent allies, heals 5 HP/turn
```

**Item Types:**
```
health_potion   — Restore 30 HP (capped at max_hp)
damage_boost    — +10 attack for remainder of floor
shield          — +5 defense for remainder of floor
```

**Pydantic Models:**
```python
class EnemySpec(BaseModel):
    id: str                                    # "e1", "e2", etc.
    type: str                                  # Enemy type string
    position: list[int] = Field(min_length=2, max_length=2)
    hp: int = Field(gt=0)
    max_hp: int = Field(gt=0)
    attack: int = Field(ge=0)
    defense: int = Field(ge=0)
    behavior: str

    @model_validator(mode='after')
    def hp_lte_max_hp(self):
        assert self.hp <= self.max_hp
        return self

class ItemSpec(BaseModel):
    id: str
    type: Literal["health_potion", "damage_boost", "shield"]
    position: list[int] = Field(min_length=2, max_length=2)

class LevelSchema(BaseModel):
    level_id: str
    floor_number: int = Field(ge=1, le=5)
    theme: Literal["cursed_library", "volcanic_caves", "enchanted_forest"]
    grid: list[list[int]]
    grid_rows: int = Field(ge=10, le=20)
    grid_cols: int = Field(ge=10, le=20)
    player_start: list[int] = Field(min_length=2, max_length=2)
    exit_position: list[int] = Field(min_length=2, max_length=2)
    enemies: list[EnemySpec]
    items: list[ItemSpec]
    narrative_hook: str = Field(max_length=200)
    difficulty_score: float = Field(ge=1.0, le=10.0)
    enemy_count: int
    estimated_turns_to_clear: int = Field(ge=5, le=100)
    ai_used: bool = True
    fallback_used: bool = False
    cached: bool = False
    agent_trace_id: str | None = None
    processing_time_ms: int | None = None

    @model_validator(mode='after')
    def validate_grid_dimensions(self):
        assert len(self.grid) == self.grid_rows
        assert all(len(row) == self.grid_cols for row in self.grid)
        assert self.enemy_count == len(self.enemies)
        # All border tiles must be walls
        assert all(self.grid[0][c] == 0 for c in range(self.grid_cols))
        assert all(self.grid[self.grid_rows-1][c] == 0 for c in range(self.grid_cols))
        assert all(self.grid[r][0] == 0 for r in range(self.grid_rows))
        assert all(self.grid[r][self.grid_cols-1] == 0 for r in range(self.grid_rows))
        return self
```

---

## SCHEMA 3: EnemyAction
**Produced by:** RivalAgent
**Consumed by:** Flutter Flame engine

```json
{
  "$schema": "EnemyAction",
  "enemy_id": "e1",
  "action_type": "move",
  "direction": "up",
  "target_position": null,
  "damage": null,
  "reasoning": "Player moved right again. Cutting off escape route.",
  "updated_tactics": {
    "dominant_direction": "right",
    "prefers_melee": true,
    "prefers_ranged": false,
    "retreats_when_low_hp": false,
    "corners_preference": false,
    "turns_observed": 5
  }
}
```

**Action Type Rules:**
```
"move":    direction REQUIRED, target_position NULL, damage NULL
"attack":  direction NULL, target_position REQUIRED [row,col], damage REQUIRED (int >= 1)
"ability": direction NULL, target_position REQUIRED, damage REQUIRED or NULL
"wait":    direction NULL, target_position NULL, damage NULL
```

**Pydantic Model:**
```python
class PlayerTacticsProfile(BaseModel):
    dominant_direction: str | None = None
    prefers_melee: bool = False
    prefers_ranged: bool = False
    retreats_when_low_hp: bool = False
    corners_preference: bool = False
    turns_observed: int = 0

class EnemyAction(BaseModel):
    enemy_id: str
    action_type: Literal["move", "attack", "ability", "wait"]
    direction: Literal["up", "down", "left", "right"] | None = None
    target_position: list[int] | None = None
    damage: int | None = None
    reasoning: str = Field(max_length=120)
    updated_tactics: PlayerTacticsProfile

    @model_validator(mode='after')
    def validate_action_fields(self):
        if self.action_type == "move":
            assert self.direction is not None, "Move requires direction"
        if self.action_type == "attack":
            assert self.target_position is not None, "Attack requires target"
            assert self.damage is not None and self.damage >= 1
        return self
```

---

## SCHEMA 4: ActionResult
**Produced by:** RefereeAgent
**Consumed by:** Flutter game engine

```json
{
  "$schema": "ActionResult",
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

**Result Type Values:**
```
"moved"          — Player moved to new tile
"attacked"       — Player attacked enemy (enemy survived)
"killed_enemy"   — Player killed an enemy
"took_damage"    — Player was hit (only used for enemy attacks, not player actions)
"item_collected" — Player stepped on item tile
"floor_cleared"  — Player stepped on exit tile
"session_won"    — Player cleared floor 5
"session_lost"   — Player HP reached 0
"invalid"        — Action was not legal
```

**Pydantic Model:**
```python
class ActionResult(BaseModel):
    action_valid: bool
    invalid_reason: str | None = None
    result_type: Literal[
        "moved", "attacked", "killed_enemy", "took_damage",
        "item_collected", "floor_cleared", "session_won", "session_lost", "invalid"
    ]
    new_player_position: list[int] | None = None
    damage_dealt: int | None = None
    damage_taken: int | None = None
    enemy_killed: bool = False
    enemy_id_killed: str | None = None
    xp_gained: int = 0
    floor_cleared: bool = False
    session_over: bool = False
    item_collected: ItemSpec | None = None
    result_narrative: str = Field(max_length=150)
    ai_used: bool = False
    processing_time_ms: int | None = None
```

---

## SCHEMA 5: NarrativeResponse
**Produced by:** NarrativeAgent
**Consumed by:** Flutter (text overlay)

```json
{
  "$schema": "NarrativeResponse",
  "event_type": "floor_cleared",
  "text": "Three fallen. The forest remembers. Floor 3 waits, darker than before.",
  "display_duration": 2500,
  "ai_used": true,
  "fallback_used": false,
  "cached": true,
  "processing_time_ms": 340
}
```

**Display Duration by Event:**
```
session_start:    3000ms
floor_cleared:    2500ms
item_found:       1500ms
boss_encounter:   3000ms
player_death:     3000ms
enemy_killed:     1000ms
```

---

## SCHEMA 6: TraceEntry
**Produced by:** All agents via BaseAgent.log_trace()
**Consumed by:** Flutter Trace Viewer screen, judges' evaluation

```json
{
  "$schema": "TraceEntry",
  "trace_id": "auto-generated-firestore-id",
  "session_id": "uuid-v4",
  "agent": "DungeonMasterAgent",
  "floor_number": 1,
  "turn_number": 0,
  "step": 1,
  "timestamp": "2026-05-18T10:32:01.234Z",
  "reasoning": "Player has 80% loss rate across 10 sessions. Applying easy mode.",
  "tool_called": "compute_player_stats",
  "tool_input": {
    "wins": 2,
    "losses": 8,
    "total_sessions": 10
  },
  "tool_output": {
    "loss_rate": 0.8,
    "category": "struggling",
    "recommended_difficulty_range": "1-4"
  },
  "decision": "Setting difficulty to 3/10. Reducing enemy speed to 0.8x. Increasing item drop to 1.5x.",
  "duration_ms": 1240,
  "model_used": "gemini-2.0-flash-thinking-exp",
  "fallback_used": false
}
```

**Agent Name Values (exact strings):**
```
"DungeonMasterAgent"
"LevelGeneratorAgent"
"RivalAgent"
"NarrativeAgent"
"RefereeAgent"
```

**Pydantic Model:**
```python
class TraceEntry(BaseModel):
    trace_id: str | None = None       # Set by Firestore on save
    session_id: str
    agent: str
    floor_number: int
    turn_number: int = 0
    step: int
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    reasoning: str
    tool_called: str
    tool_input: dict
    tool_output: dict
    decision: str
    duration_ms: int = 0
    model_used: str
    fallback_used: bool = False
```

---

## SCHEMA 7: PlayerState (In-Game)
**Used by:** Flutter game engine, RefereeAgent, RivalAgent

```json
{
  "$schema": "PlayerState",
  "player_id": "firebase_uid",
  "player_class": "warrior",
  "position": [3, 5],
  "hp": 85,
  "max_hp": 150,
  "attack": 20,
  "defense": 8,
  "turn_count": 14,
  "floors_cleared": 1,
  "enemies_killed": 4,
  "score": 580,
  "special_used": false,
  "inventory": ["damage_boost"],
  "active_buffs": {
    "attack_bonus": 10,
    "defense_bonus": 0,
    "buff_expires_floor": 1
  }
}
```

---

## SCHEMA 8: GameState (Flutter State)
**Used by:** Flutter Riverpod state management

```json
{
  "$schema": "GameState",
  "status": "playing",
  "session_id": "uuid-v4",
  "session_plan": { "...SessionPlan..." },
  "current_level": { "...LevelSchema..." },
  "player": { "...PlayerState..." },
  "enemies": [
    {
      "id": "e1",
      "type": "goblin",
      "position": [4, 5],
      "hp": 15,
      "max_hp": 20,
      "attack": 8,
      "defense": 3,
      "behavior": "rush_melee",
      "is_alive": true
    }
  ],
  "items_on_board": [
    {
      "id": "i1",
      "type": "health_potion",
      "position": [3, 8],
      "collected": false
    }
  ],
  "turn_phase": "player_turn",
  "last_action_result": { "...ActionResult or null..." },
  "last_narrative": "You move north. The shadows shift.",
  "ai_is_thinking": false,
  "ai_last_decision": "Goblin flanked right — detected rush pattern",
  "session_traces": []
}
```

**Status Values:**
```
"loading"        — Session starting, AI generating level
"playing"        — Active gameplay
"enemy_turn"     — AI processing enemy moves
"floor_cleared"  — Transition between floors
"game_over_win"  — Session won (cleared floor 5)
"game_over_lose" — Player died
"paused"         — Game paused (menu open)
```

**Turn Phase Values:**
```
"player_turn"     — Waiting for player input
"processing"      — Validating player action
"enemy_turn"      — AI deciding enemy moves
"animating"       — Playing combat/movement animation
"transition"      — Between floors
```

---

## SCHEMA 9: LeaderboardEntry

```json
{
  "$schema": "LeaderboardEntry",
  "rank": 1,
  "player_id": "anonymized_uid",
  "display_name": "DungeonMaster",
  "score": 4820,
  "floors_cleared": 5,
  "class_used": "mage",
  "theme": "cursed_library",
  "achieved_at": "2026-05-18T08:00:00Z"
}
```

---

## SCHEMA VALIDATION UTILITY

```python
# mobile-game-server/utils/validators.py

def validate_level_playable(level: LevelSchema) -> tuple[bool, str]:
    """Check if level has a valid path from player_start to exit."""
    from collections import deque

    grid = level.grid
    start = tuple(level.player_start)
    exit_pos = tuple(level.exit_position)

    visited = {start}
    queue = deque([start])

    while queue:
        row, col = queue.popleft()
        if (row, col) == exit_pos:
            return True, "Path exists"
        for dr, dc in [(-1,0),(1,0),(0,-1),(0,1)]:
            nr, nc = row+dr, col+dc
            if (0 <= nr < level.grid_rows and
                0 <= nc < level.grid_cols and
                grid[nr][nc] != 0 and
                (nr,nc) not in visited):
                visited.add((nr,nc))
                queue.append((nr,nc))

    return False, f"No path from {start} to {exit_pos}"


def validate_no_enemy_on_start(level: LevelSchema) -> tuple[bool, str]:
    start = level.player_start
    for enemy in level.enemies:
        dist = abs(enemy.position[0]-start[0]) + abs(enemy.position[1]-start[1])
        if dist < 3:
            return False, f"Enemy {enemy.id} too close to player start (distance={dist}, min=3)"
    return True, "All enemies safe distance from start"
```

---

*These schemas are contracts. Both sides (Flutter and FastAPI) must implement them exactly.*
*Run schema validation tests before integrating any new agent output.*
