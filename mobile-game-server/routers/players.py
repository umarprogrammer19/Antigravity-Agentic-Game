from fastapi import APIRouter
from pydantic import BaseModel
from services.firebase_service import firebase_service

router = APIRouter()

@router.get("/players/{player_id}/history")
async def get_player_history(player_id: str):
    """
    Retrieve player stats and session history.
    Used by DM agent.
    """
    from config import logger
    history = await firebase_service.get_player_history(player_id)
    logger.info(f"📊 Player {player_id} stats: Wins={history.get('wins', 0)}, Losses={history.get('losses', 0)}, High Score={history.get('high_score', 0)}")
    return {"player_id": player_id, **history}

@router.post("/players/{player_id}/session")
async def save_session(player_id: str, request_data: dict):
    """
    Save completed session to Firestore.
    Called on win or death.
    """
    session_data = {"player_id": player_id, **request_data}
    updated_stats = await firebase_service.save_session(session_data)
    return {
        "saved": True,
        "session_id": request_data.get("session_id", "mock-session-id"),
        "updated_stats": updated_stats or {
            "total_sessions": 1,
            "wins": 1 if request_data.get("won") else 0,
            "losses": 0 if request_data.get("won") else 1,
            "high_score": request_data.get("score", 0),
            "leaderboard_rank": None,
        },
    }

@router.get("/leaderboard")
async def get_leaderboard(limit: int = 20):
    entries = await firebase_service.get_leaderboard(limit)
    return {"entries": entries}
