import time
import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from routers import health, agents, traces, players

# Setup logging for the app
logger = logging.getLogger("DungeonMind")

app = FastAPI(title="DungeonMind API")

# CORS middleware (allow all origins for hackathon)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router)
app.include_router(agents.router)
app.include_router(traces.router)
app.include_router(players.router)

@app.on_event("startup")
async def startup_event():
    """Startup event to log initialization."""
    logger.info("DungeonMind API started")

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler returning generic error format, never 500."""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=200,
        content={"error": True, "message": str(exc), "fallback_used": True}
    )

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Request logging middleware."""
    start_time = time.time()
    response = await call_next(request)
    process_time = (time.time() - start_time) * 1000
    
    logger.info(
        f"Method: {request.method} Path: {request.url.path} "
        f"Status: {response.status_code} Duration: {process_time:.2f}ms"
    )
    return response
