import time
from fastapi import APIRouter
from config import logger
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
    NarrativeResponse as NarrativeResponseModel,
    EnemySpec,
    ItemSpec,
    PlayerTacticsProfile
)

from agents.dungeon_master import DungeonMasterAgent, FALLBACK_SESSION_PLAN
from agents.level_generator import LevelGeneratorAgent
from agents.rival_agent import RivalAgent
from agents.narrative_agent import NarrativeAgent
from agents.referee_agent import RefereeAgent
from fallbacks.fallback_levels import FALLBACK_LEVELS

router = APIRouter(prefix="/agent")

@router.post("/dungeon-master", response_model=SessionPlanResponse)
async def get_dungeon_master_plan(request: DungeonMasterRequest):
    start = time.time()
    try:
        agent = DungeonMasterAgent(session_id="new_session")
        plan = await agent.run({
            "player_id": request.player_id,
            "player_class": request.player_class,
            "history": request.player_history
        })
        ms = int((time.time() - start) * 1000)
        return SessionPlanResponse(**plan.model_dump(), ai_used=True, fallback_used=False, processing_time_ms=ms)
    except Exception as e:
        logger.error(f"DungeonMaster route failed: {e}")
        ms = int((time.time() - start) * 1000)
        return SessionPlanResponse(**FALLBACK_SESSION_PLAN.model_dump(), ai_used=False, fallback_used=True, processing_time_ms=ms)

@router.post("/generate-level", response_model=LevelResponse)
async def generate_level(request: GenerateLevelRequest):
    start = time.time()
    try:
        agent = LevelGeneratorAgent(session_id=request.session_id, floor_number=request.floor_number)
        level = await agent.run({
            "session_id": request.session_id,
            "floor_number": request.floor_number,
            "difficulty_level": request.difficulty_level,
            "theme": request.theme,
            "player_class": request.player_class,
            "enemy_speed_multiplier": request.enemy_speed_multiplier,
            "item_drop_rate": request.item_drop_rate,
            "player_current_hp": request.player_current_hp
        })
        ms = int((time.time() - start) * 1000)
        return LevelResponse(**level.model_dump(), ai_used=True, fallback_used=False, cached=False, processing_time_ms=ms)
    except Exception as e:
        logger.error(f"LevelGenerator route failed: {e}")
        ms = int((time.time() - start) * 1000)
        fallback = FALLBACK_LEVELS.get(request.theme, FALLBACK_LEVELS["enchanted_forest"])
        return LevelResponse(**fallback.model_dump(), ai_used=False, fallback_used=True, cached=False, processing_time_ms=ms)

@router.post("/npc-decision", response_model=NPCDecisionResponse)
async def npc_decision(request: NPCDecisionRequest):
    start = time.time()
    try:
        agent = RivalAgent(session_id=request.session_id)
        action = await agent.run({
            "enemy_state": request.enemy_state,
            "player_state": request.player_state,
            "board_state": request.board_state,
            "player_last_5_moves": request.player_last_5_moves,
            "player_tactics_profile": request.player_tactics_profile
        })
        ms = int((time.time() - start) * 1000)
        return NPCDecisionResponse(**action.model_dump(), ai_used=True, fallback_used=False, cached=False, processing_time_ms=ms)
    except Exception as e:
        logger.error(f"Rival route failed: {e}")
        ms = int((time.time() - start) * 1000)
        enemy_id = request.enemy_state.get("id", "e_unknown")
        return NPCDecisionResponse(
            enemy_id=enemy_id, action_type="wait", direction=None, target_position=None, damage=None, 
            reasoning="Fallback wait", updated_tactics=None, ai_used=False, fallback_used=True, cached=False, processing_time_ms=ms
        )

@router.post("/validate-action", response_model=ActionResultResponse)
async def validate_action(request: ValidateActionRequest):
    start = time.time()
    try:
        agent = RefereeAgent(session_id=request.session_id)
        res = await agent.run({
            "action": request.action,
            "player_state": request.player_state,
            "board_state": request.board_state
        })
        ms = int((time.time() - start) * 1000)
        return ActionResultResponse(**res.model_dump(), ai_used=True, processing_time_ms=ms)
    except Exception as e:
        logger.error(f"Referee route failed: {e}")
        ms = int((time.time() - start) * 1000)
        return ActionResultResponse(
            action_valid=False, invalid_reason="Fallback", result_type="invalid", 
            new_player_position=None, damage_dealt=None, damage_taken=None, enemy_killed=False, 
            xp_gained=0, floor_cleared=False, session_over=False, result_narrative="Action failed.",
            ai_used=False, processing_time_ms=ms
        )

@router.post("/narrative", response_model=NarrativeResponseModel)
async def get_narrative(request: NarrativeRequest):
    start = time.time()
    try:
        # Some requests might not send session_id if it's general narrative, but request model has it.
        # Fallback to empty string if missing
        session_id = getattr(request, 'session_id', 'narrative_session')
        agent = NarrativeAgent(session_id=session_id)
        narr = await agent.run({
            "event_type": request.event_type,
            "player_class": request.player_class,
            "floor_number": request.floor_number,
            "theme": request.theme,
            "context": request.context
        })
        ms = int((time.time() - start) * 1000)
        return NarrativeResponseModel(**narr.model_dump(), ai_used=True, fallback_used=False, cached=False, processing_time_ms=ms)
    except Exception as e:
        logger.error(f"Narrative route failed: {e}")
        ms = int((time.time() - start) * 1000)
        return NarrativeResponseModel(
            event_type=request.event_type, text="The shadows shift around you.", display_duration=2000, 
            ai_used=False, fallback_used=True, cached=False, processing_time_ms=ms
        )
