from fastapi import APIRouter
from models.requests import (
    DungeonMasterRequest,
    GenerateLevelRequest,
    NPCDecisionRequest,
    ValidateActionRequest,
    NarrativeRequest
)
from models.responses import (
    SessionPlanResponse,
    LevelResponse,
    NPCDecisionResponse,
    ActionResultResponse,
    NarrativeResponse,
    EnemySpec,
    ItemSpec,
    PlayerTacticsProfile
)

router = APIRouter(prefix="/agent")

@router.post("/dungeon-master", response_model=SessionPlanResponse)
async def get_dungeon_master_plan(request: DungeonMasterRequest):
    """
    Called once at session start. DM analyzes player history and creates session plan.
    Mock implementation returning hardcoded response.
    """
    return SessionPlanResponse(
        session_id="550e8400-e29b-41d4-a716-446655440000",
        difficulty_level=3,
        theme="enchanted_forest",
        enemy_speed_multiplier=0.8,
        item_drop_rate=1.5,
        enemy_count_multiplier=0.9,
        boss_difficulty=2,
        narrative_intro="The ancient forest closes around you. Something old stirs in the roots.",
        dm_reasoning="Player has 80% loss rate across 10 sessions. Reducing difficulty to rebuild confidence.",
        recommended_strategy="Engage enemies one at a time. Use items immediately.",
        ai_used=True,
        fallback_used=False,
        processing_time_ms=2340
    )

@router.post("/generate-level", response_model=LevelResponse)
async def generate_level(request: GenerateLevelRequest):
    """
    Generate a complete dungeon floor as JSON. Called once per floor.
    Mock implementation returning hardcoded response.
    """
    grid = [
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
    ]
    return LevelResponse(
        level_id="550e8400-e29b-41d4-a716-446655440001",
        floor_number=request.floor_number,
        theme="enchanted_forest",
        grid=grid,
        grid_rows=10,
        grid_cols=10,
        player_start=[1, 1],
        exit_position=[8, 8],
        enemies=[
            EnemySpec(id="e1", type="goblin", position=[4, 5], hp=20, max_hp=20, attack=8, defense=3, behavior="rush_melee"),
            EnemySpec(id="e2", type="forest_witch", position=[7, 3], hp=35, max_hp=35, attack=14, defense=4, behavior="ranged_2tile")
        ],
        items=[
            ItemSpec(id="i1", type="health_potion", position=[3, 8])
        ],
        narrative_hook="Twisted roots crack the stone floor where ancient trees once stood.",
        difficulty_score=3.2,
        enemy_count=2,
        estimated_turns_to_clear=18,
        ai_used=True,
        fallback_used=False,
        cached=False,
        processing_time_ms=2870
    )

@router.post("/npc-decision", response_model=NPCDecisionResponse)
async def npc_decision(request: NPCDecisionRequest):
    """
    Get the next action for one enemy. Called per enemy per turn.
    Mock implementation returning hardcoded response.
    """
    return NPCDecisionResponse(
        enemy_id=request.enemy_id,
        action_type="attack",
        direction=None,
        target_position=[3, 5],
        damage=5,
        reasoning="Player adjacent. Direct attack. HP low but attacking is optimal.",
        updated_tactics=PlayerTacticsProfile(
            dominant_direction="right",
            prefers_melee=True,
            prefers_ranged=False,
            retreats_when_low_hp=False,
            corners_preference=False,
            turns_observed=5
        ),
        ai_used=True,
        fallback_used=False,
        cached=False,
        processing_time_ms=780
    )

@router.post("/validate-action", response_model=ActionResultResponse)
async def validate_action(request: ValidateActionRequest):
    """
    Validate a player action and return its result.
    Mock implementation returning hardcoded response.
    """
    return ActionResultResponse(
        action_valid=True,
        invalid_reason=None,
        result_type="moved",
        new_player_position=[2, 5],
        damage_dealt=None,
        damage_taken=None,
        enemy_killed=False,
        enemy_id_killed=None,
        xp_gained=0,
        floor_cleared=False,
        session_over=False,
        item_collected=None,
        result_narrative="You move north. The shadows shift.",
        ai_used=False,
        processing_time_ms=12
    )

@router.post("/narrative", response_model=NarrativeResponse)
async def get_narrative(request: NarrativeRequest):
    """
    Generate atmospheric story text for game events.
    Mock implementation returning hardcoded response.
    """
    return NarrativeResponse(
        event_type=request.event_type,
        text="Three fallen. The forest remembers. Floor 3 waits, darker than before.",
        display_duration=2500,
        ai_used=True,
        fallback_used=False,
        cached=True,
        processing_time_ms=340
    )
