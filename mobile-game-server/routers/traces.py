from fastapi import APIRouter

router = APIRouter()

@router.get("/traces/{session_id}")
async def get_traces(session_id: str):
    """
    Retrieve all agent trace logs for a session.
    Used by Trace Viewer screen.
    """
    return {
        "session_id": session_id,
        "total_decisions": 0,
        "agents_used": [],
        "traces": []
    }
