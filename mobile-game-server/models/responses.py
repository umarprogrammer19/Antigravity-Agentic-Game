from pydantic import BaseModel, Field
from typing import Literal, Any

# --- Sub Models ---
class EnemySpec(BaseModel):
    """Specification for an enemy inside a level."""
    id: str
    type: str
    position: list[int] = Field(min_length=2, max_length=2)
    hp: int = Field(gt=0)
    max_hp: int = Field(gt=0)
    attack: int = Field(ge=0)
    defense: int = Field(ge=0)
    behavior: str

class ItemSpec(BaseModel):
    """Specification for an item inside a level."""
    id: str
    type: Literal["health_potion", "damage_boost", "shield"]
    position: list[int] = Field(min_length=2, max_length=2)

class PlayerTacticsProfile(BaseModel):
    """Profile of the player's observed tactics, used by AI."""
    dominant_direction: str | None = None
    prefers_melee: bool = False
    prefers_ranged: bool = False
    retreats_when_low_hp: bool = False
    corners_preference: bool = False
    turns_observed: int = 0

# --- Response Models ---
class SessionPlanResponse(BaseModel):
    """Response from the Dungeon Master Agent containing the session parameters."""
    session_id: str
    difficulty_level: int
    theme: Literal["cursed_library", "volcanic_caves", "enchanted_forest"]
    enemy_speed_multiplier: float
    item_drop_rate: float
    enemy_count_multiplier: float
    boss_difficulty: int
    narrative_intro: str
    dm_reasoning: str
    recommended_strategy: str
    ai_used: bool
    fallback_used: bool
    agent_trace_id: str | None = None
    processing_time_ms: int | None = None

class LevelResponse(BaseModel):
    """Response from the Level Generator Agent containing a playable floor."""
    level_id: str
    floor_number: int
    theme: Literal["cursed_library", "volcanic_caves", "enchanted_forest"]
    grid: list[list[int]]
    grid_rows: int
    grid_cols: int
    player_start: list[int]
    exit_position: list[int]
    enemies: list[EnemySpec]
    items: list[ItemSpec]
    narrative_hook: str
    difficulty_score: float
    enemy_count: int
    estimated_turns_to_clear: int
    ai_used: bool
    fallback_used: bool
    cached: bool
    agent_trace_id: str | None = None
    processing_time_ms: int | None = None

class NPCDecisionResponse(BaseModel):
    """Response from the Rival Agent containing an enemy action."""
    enemy_id: str
    action_type: Literal["move", "attack", "ability", "wait"]
    direction: Literal["up", "down", "left", "right"] | None = None
    target_position: list[int] | None = None
    damage: int | None = None
    reasoning: str
    updated_tactics: PlayerTacticsProfile
    ai_used: bool = True
    fallback_used: bool = False
    cached: bool = False
    processing_time_ms: int | None = None

class ActionResultResponse(BaseModel):
    """Response from the Referee Agent detailing the outcome of a player action."""
    action_valid: bool
    invalid_reason: str | None = None
    result_type: Literal[
        "moved", "attacked", "killed_enemy", "took_damage",
        "item_collected", "floor_cleared", "session_won", "session_lost",
        "wait", "invalid"
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
    result_narrative: str
    ai_used: bool = False
    processing_time_ms: int | None = None

class NarrativeResponse(BaseModel):
    """Response from the Narrative Agent containing atmospheric text."""
    event_type: Literal["session_start", "floor_cleared", "item_found", "boss_encounter", "player_death", "enemy_killed"]
    text: str
    display_duration: int
    ai_used: bool = True
    fallback_used: bool = False
    cached: bool = False
    processing_time_ms: int | None = None
