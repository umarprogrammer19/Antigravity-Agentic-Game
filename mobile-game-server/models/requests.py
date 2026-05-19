from pydantic import BaseModel, Field
from typing import Literal, Any

class DungeonMasterRequest(BaseModel):
    """Request for the Dungeon Master Agent to generate a session plan."""
    player_id: str
    player_class: Literal["warrior", "mage", "ranger"]
    force_new_session: bool = False

class GenerateLevelRequest(BaseModel):
    """Request for the Level Generator Agent to create a floor."""
    session_id: str
    floor_number: int = Field(ge=1, le=5)
    difficulty_level: int = Field(ge=1, le=10)
    theme: Literal["cursed_library", "volcanic_caves", "enchanted_forest"]
    player_class: Literal["warrior", "mage", "ranger"]
    enemy_speed_multiplier: float
    item_drop_rate: float
    player_current_hp: int

class NPCDecisionRequest(BaseModel):
    """Request for the Rival Agent to make a move for an NPC."""
    session_id: str
    enemy_id: str
    enemy_state: dict[str, Any]
    player_state: dict[str, Any]
    board_state: dict[str, Any]
    player_last_5_moves: list[str]

class ValidateActionRequest(BaseModel):
    """Request for the Referee Agent to validate a player action."""
    session_id: str
    player_state: dict[str, Any]
    action: dict[str, Any]
    board_state: dict[str, Any]

class NarrativeRequest(BaseModel):
    """Request for the Narrative Agent to generate atmospheric text."""
    session_id: str
    event_type: Literal["session_start", "floor_cleared", "item_found", "boss_encounter", "player_death", "enemy_killed"]
    player_class: Literal["warrior", "mage", "ranger"]
    floor_number: int
    theme: Literal["cursed_library", "volcanic_caves", "enchanted_forest"]
    context: dict[str, Any]

class SaveSessionRequest(BaseModel):
    """Request to save the results of a completed session."""
    session_id: str
    won: bool
    score: int
    floors_cleared: int
    enemies_killed: int
    death_cause: str | None = None
    death_floor: int | None = None
    player_class: Literal["warrior", "mage", "ranger"]
    theme: Literal["cursed_library", "volcanic_caves", "enchanted_forest"]
    difficulty_level: int
    total_turns: int
    session_duration_seconds: int
    ai_decisions_made: int
