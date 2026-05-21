from pydantic import BaseModel, Field, model_validator, ConfigDict
from typing import Literal, Any, List, Optional
from datetime import datetime
from uuid import uuid4
from collections import deque

class EnemySpec(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    id: str
    type: str
    position: List[int] = Field(min_length=2, max_length=2)
    hp: int = Field(gt=0)
    max_hp: int = Field(gt=0)
    attack: int = Field(ge=0)
    defense: int = Field(ge=0)
    behavior: str

    @model_validator(mode='after')
    def hp_lte_max_hp(self):
        if self.hp > self.max_hp:
            raise ValueError(f"hp ({self.hp}) must be <= max_hp ({self.max_hp})")
        return self

class ItemSpec(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    id: str
    type: Literal["health_potion", "damage_boost", "shield"]
    position: List[int] = Field(min_length=2, max_length=2)

class LevelSchema(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    level_id: str
    floor_number: int = Field(ge=1, le=5)
    theme: Literal["cursed_library", "volcanic_caves", "enchanted_forest"]
    grid: List[List[int]]
    grid_rows: int = Field(ge=10, le=20)
    grid_cols: int = Field(ge=10, le=20)
    player_start: List[int] = Field(min_length=2, max_length=2)
    exit_position: List[int] = Field(min_length=2, max_length=2)
    enemies: List[EnemySpec]
    items: List[ItemSpec]
    narrative_hook: str = Field(max_length=200)
    player_analysis: str = Field(default="No analysis available.", description="AI analysis of the player's past moves and tactics.")
    difficulty_score: float = Field(ge=1.0, le=10.0)
    enemy_count: int
    estimated_turns_to_clear: int = Field(ge=5, le=100)
    ai_used: bool = True
    fallback_used: bool = False
    cached: bool = False
    agent_trace_id: str | None = None
    processing_time_ms: int | None = None

    @model_validator(mode='after')
    def validate_grid_and_level(self):
        # Check grid dimensions
        if len(self.grid) != self.grid_rows:
            raise ValueError("Grid rows dimension does not match grid_rows field")
        if not all(len(row) == self.grid_cols for row in self.grid):
            raise ValueError("Grid cols dimension does not match grid_cols field")
        
        # Check enemy count
        if self.enemy_count != len(self.enemies):
            raise ValueError("enemy_count does not match the number of enemies in the list")
            
        # Check borders are walls (0)
        for c in range(self.grid_cols):
            if self.grid[0][c] != 0:
                raise ValueError("Top border must be wall (0)")
            if self.grid[self.grid_rows - 1][c] != 0:
                raise ValueError("Bottom border must be wall (0)")
        for r in range(self.grid_rows):
            if self.grid[r][0] != 0:
                raise ValueError("Left border must be wall (0)")
            if self.grid[r][self.grid_cols - 1] != 0:
                raise ValueError("Right border must be wall (0)")
                
        # Check player start is a floor tile (1)
        start_r, start_c = self.player_start[0], self.player_start[1]
        if self.grid[start_r][start_c] != 1:
            raise ValueError("player_start position must be a floor tile (grid value 1)")
            
        return self

class SessionPlan(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
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

class PlayerTacticsProfile(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    dominant_direction: str | None = None
    prefers_melee: bool = False
    prefers_ranged: bool = False
    retreats_when_low_hp: bool = False
    corners_preference: bool = False
    turns_observed: int = 0

class EnemyAction(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    enemy_id: str
    action_type: Literal["move", "attack", "ability", "wait"]
    direction: Literal["up", "down", "left", "right"] | None = None
    target_position: List[int] | None = None
    damage: int | None = None
    reasoning: str = Field(max_length=120)
    updated_tactics: PlayerTacticsProfile

    @model_validator(mode='after')
    def validate_action_fields(self):
        if self.action_type == "move":
            if self.direction is None:
                raise ValueError("If action_type is 'move', 'direction' is required.")
        if self.action_type == "attack":
            if self.target_position is None:
                raise ValueError("If action_type is 'attack', 'target_position' is required.")
            if self.damage is None or self.damage < 1:
                raise ValueError("If action_type is 'attack', 'damage' must be >= 1.")
        return self

class ActionResult(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    action_valid: bool
    invalid_reason: str | None = None
    result_type: Literal[
        "moved", "attacked", "killed_enemy", "took_damage",
        "item_collected", "floor_cleared", "session_won", "session_lost",
        "wait", "invalid"
    ]
    new_player_position: List[int] | None = None
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

class NarrativeResponse(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    event_type: Literal["session_start", "floor_cleared", "item_found", "boss_encounter", "player_death", "enemy_killed"]
    text: str
    display_duration: int
    ai_used: bool = True
    fallback_used: bool = False
    cached: bool = False
    processing_time_ms: int | None = None

class TraceEntry(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    trace_id: str | None = None
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

class PlayerState(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    player_id: str
    player_class: Literal["warrior", "mage", "ranger"]
    position: List[int]
    hp: int
    max_hp: int
    attack: int
    defense: int
    turn_count: int
    floors_cleared: int
    enemies_killed: int
    score: int
    special_used: bool
    inventory: List[str]
    active_buffs: dict[str, Any]

def validate_level_playable(level: LevelSchema) -> tuple[bool, str]:
    """Check if level has a valid path from player_start to exit."""
    grid = level.grid
    start = tuple(level.player_start)
    exit_pos = tuple(level.exit_position)

    # Basic validation first
    if not (0 <= start[0] < level.grid_rows and 0 <= start[1] < level.grid_cols):
        return False, f"player_start {start} out of bounds"
    if not (0 <= exit_pos[0] < level.grid_rows and 0 <= exit_pos[1] < level.grid_cols):
        return False, f"exit_position {exit_pos} out of bounds"
    if grid[start[0]][start[1]] == 0:
        return False, f"player_start {start} is on a wall tile"
    if grid[exit_pos[0]][exit_pos[1]] == 0:
        return False, f"exit_position {exit_pos} is on a wall tile"

    visited = {start}
    queue = deque([start])

    while queue:
        row, col = queue.popleft()
        if (row, col) == exit_pos:
            return True, "Path exists"
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = row + dr, col + dc
            if (0 <= nr < level.grid_rows and
                0 <= nc < level.grid_cols and
                grid[nr][nc] != 0 and
                (nr, nc) not in visited):
                visited.add((nr, nc))
                queue.append((nr, nc))

    return False, f"No path from {start} to {exit_pos}"
