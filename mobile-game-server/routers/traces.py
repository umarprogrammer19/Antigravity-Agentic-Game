from fastapi import APIRouter
from services.firebase_service import firebase_service

router = APIRouter()

@router.get("/traces/{session_id}")
async def get_traces(session_id: str):
    """
    Retrieve all agent trace logs for a session from Firestore.
    Used by Trace Viewer screen.
    """
    try:
        result = await firebase_service.get_traces(session_id)
        # Flatten entries into traces list for Flutter
        return {
            "session_id": session_id,
            "total_decisions": result.get("total_decisions", 0),
            "agents_used": list({e.get("agent") for e in result.get("entries", []) if e.get("agent")}),
            "traces": result.get("entries", [])
        }
    except Exception as e:
        return {
            "session_id": session_id,
            "total_decisions": 0,
            "agents_used": [],
            "traces": [],
            "error": str(e)
        }

