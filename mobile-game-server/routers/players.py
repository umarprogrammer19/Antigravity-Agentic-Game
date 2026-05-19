from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

@router.get("/players/{player_id}/history")
async def get_player_history(player_id: str):
    """
    Retrieve player stats and session history.
    Used by DM agent.
    """
    return {
        "player_id": player_id,
        "display_name": "Player",
        "player_class": "warrior",
        "total_sessions": 0,
        "wins": 0,
        "losses": 0,
        "high_score": 0,
        "avg_floors_cleared": 0.0,
        "favorite_death_cause": None,
        "total_enemies_killed": 0,
        "last_5_sessions": []
    }

@router.post("/players/{player_id}/session")
async def save_session(player_id: str, request_data: dict):
    """
    Save completed session to Firestore.
    Called on win or death.
    """
    return {
        "saved": True,
        "session_id": request_data.get("session_id", "mock-session-id"),
        "updated_stats": {
            "total_sessions": 1,
            "wins": 1 if request_data.get("won") else 0,
            "losses": 0 if request_data.get("won") else 1,
            "high_score": request_data.get("score", 0),
            "leaderboard_rank": None
        }
    }
