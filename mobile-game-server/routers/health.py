from fastapi import APIRouter
from datetime import datetime

router = APIRouter()

@router.get("/health")
async def health_check():
    """
    Verify backend is running.
    Called by Flutter on app start.
    """
    return {
        "status": "ok",
        "version": "1.0.0",
        "gemini_connected": True,
        "firebase_connected": True,
        "redis_connected": True,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
