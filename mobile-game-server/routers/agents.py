import time
import json
from fastapi import APIRouter
from config import logger, redis_client
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
    NarrativeResponse as NarrativeResponseModel
)

from agents.dungeon_master import DungeonMasterAgent, FALLBACK_SESSION_PLAN
from agents.level_generator import LevelGeneratorAgent
from agents.rival_agent import RivalAgent
from agents.narrative_agent import NarrativeAgent
from agents.referee_agent import RefereeAgent
from fallbacks.fallback_levels import FALLBACK_LEVELS
from services.firebase_service import firebase_service

router = APIRouter(prefix="/agent")

@router.post("/dungeon-master", response_model=SessionPlanResponse)
async def get_dungeon_master_plan(request: DungeonMasterRequest):
    start = time.time()
    try:
        # Load player history from Firestore
        history = await firebase_service.get_player_history(request.player_id)
        
        agent = DungeonMasterAgent(session_id="new_session")
        plan = await agent.run({
            "player_id": request.player_id,
            "player_class": request.player_class,
            "history": history
        })
        
        # Save traces if they exist
        traces = agent.get_traces()
        if traces:
            await firebase_service.save_traces(plan.session_id, traces)
            
        ms = int((time.time() - start) * 1000)
        
        plan_dict = plan.model_dump()
        plan_dict.update({
            "ai_used": True,
            "fallback_used": False,
            "processing_time_ms": ms
        })
        return SessionPlanResponse(**plan_dict)
    except Exception as e:
        logger.error(f"DungeonMaster route failed: {e}")
        ms = int((time.time() - start) * 1000)
        
        fallback_dict = FALLBACK_SESSION_PLAN.model_dump()
        fallback_dict.update({
            "ai_used": False,
            "fallback_used": True,
            "processing_time_ms": ms
        })
        return SessionPlanResponse(**fallback_dict)

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
        
        # Save traces
        traces = agent.get_traces()
        if traces:
            await firebase_service.save_traces(request.session_id, traces)
            
        ms = int((time.time() - start) * 1000)
        
        level_dict = level.model_dump()
        level_dict.update({
            "ai_used": True,
            "fallback_used": False,
            "cached": False,
            "processing_time_ms": ms
        })
        return LevelResponse(**level_dict)
    except Exception as e:
        logger.error(f"LevelGenerator route failed: {e}")
        ms = int((time.time() - start) * 1000)
        fallback = FALLBACK_LEVELS.get(request.theme, FALLBACK_LEVELS["enchanted_forest"])
        
        fallback_dict = fallback.model_dump()
        fallback_dict.update({
            "ai_used": False,
            "fallback_used": True,
            "cached": False,
            "processing_time_ms": ms
        })
        return LevelResponse(**fallback_dict)

@router.post("/npc-decision", response_model=NPCDecisionResponse)
async def npc_decision(request: NPCDecisionRequest):
    start = time.time()
    try:
        # Load tactics profile from Redis if available
        tactics_profile = {}
        if redis_client:
            try:
                cached_tactics = await redis_client.get(f"session:{request.session_id}:player_tactics")
                if cached_tactics:
                    tactics_profile = json.loads(cached_tactics)
            except Exception as e:
                logger.error(f"Redis get tactics profile error: {e}")
                
        agent = RivalAgent(session_id=request.session_id)
        action = await agent.run({
            "enemy_state": request.enemy_state,
            "player_state": request.player_state,
            "board_state": request.board_state,
            "player_last_5_moves": request.player_last_5_moves,
            "player_tactics_profile": tactics_profile
        })
        
        # Save traces
        traces = agent.get_traces()
        if traces:
            await firebase_service.save_traces(request.session_id, traces)
            
        ms = int((time.time() - start) * 1000)
        
        action_dict = action.model_dump()
        action_dict.update({
            "ai_used": True,
            "fallback_used": False,
            "cached": False,
            "processing_time_ms": ms
        })
        return NPCDecisionResponse(**action_dict)
    except Exception as e:
        logger.error(f"Rival route failed: {e}")
        ms = int((time.time() - start) * 1000)
        enemy_id = request.enemy_state.get("id", "e_unknown")
        
        # Base tactics model
        empty_tactics = {
            "dominant_direction": None,
            "prefers_melee": False,
            "prefers_ranged": False,
            "retreats_when_low_hp": False,
            "corners_preference": False,
            "turns_observed": 0
        }
        
        return NPCDecisionResponse(
            enemy_id=enemy_id,
            action_type="wait",
            direction=None,
            target_position=None,
            damage=None,
            reasoning=f"Fallback wait: {str(e)[:40]}",
            updated_tactics=empty_tactics,
            ai_used=False,
            fallback_used=True,
            cached=False,
            processing_time_ms=ms
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
        
        # Save traces
        traces = agent.get_traces()
        if traces:
            await firebase_service.save_traces(request.session_id, traces)
            
        ms = int((time.time() - start) * 1000)
        
        res_dict = res.model_dump()
        res_dict.update({
            "ai_used": True,
            "processing_time_ms": ms
        })
        return ActionResultResponse(**res_dict)
    except Exception as e:
        logger.error(f"Referee route failed: {e}")
        ms = int((time.time() - start) * 1000)
        return ActionResultResponse(
            action_valid=False,
            invalid_reason=f"Fallback: {str(e)}",
            result_type="invalid",
            new_player_position=None,
            damage_dealt=None,
            damage_taken=None,
            enemy_killed=False,
            xp_gained=0,
            floor_cleared=False,
            session_over=False,
            result_narrative="Referee failed, action invalidated.",
            ai_used=False,
            processing_time_ms=ms
        )

@router.post("/narrative", response_model=NarrativeResponseModel)
async def get_narrative(request: NarrativeRequest):
    start = time.time()
    try:
        session_id = getattr(request, 'session_id', 'narrative_session')
        agent = NarrativeAgent(session_id=session_id)
        narr = await agent.run({
            "event_type": request.event_type,
            "player_class": request.player_class,
            "floor_number": request.floor_number,
            "theme": request.theme,
            "context": request.context
        })
        
        # Save traces
        traces = agent.get_traces()
        if traces:
            await firebase_service.save_traces(session_id, traces)
            
        ms = int((time.time() - start) * 1000)
        
        narr_dict = narr.model_dump()
        narr_dict.update({
            "ai_used": True,
            "fallback_used": False,
            "cached": False,
            "processing_time_ms": ms
        })
        return NarrativeResponseModel(**narr_dict)
    except Exception as e:
        logger.error(f"Narrative route failed: {e}")
        ms = int((time.time() - start) * 1000)
        return NarrativeResponseModel(
            event_type=request.event_type,
            text="The shadows shift around you.",
            display_duration=2000,
            ai_used=False,
            fallback_used=True,
            cached=False,
            processing_time_ms=ms
        )
