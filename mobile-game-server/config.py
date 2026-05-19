import os
import logging

from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict

# Load environment variables from .env
load_dotenv()


class Settings(BaseSettings):
    """Global configuration settings for the backend application."""

    GEMINI_API_KEY: str = ""
    FIREBASE_CREDENTIALS_PATH: str = "serviceAccountKey.json"
    FIREBASE_DATABASE_URL: str = ""
    REDIS_URL: str = "redis://localhost:6379"
    APP_ENV: str = "development"
    LOG_LEVEL: str = "INFO"

    # Pydantic v2 config
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


# Initialize settings
settings = Settings()

# Setup logging
logging.basicConfig(level=settings.LOG_LEVEL)
logger = logging.getLogger("DungeonMind")

# Optional imports handled gracefully
try:
    import firebase_admin
    from firebase_admin import credentials, firestore, db
except ImportError:
    firebase_admin = None

try:
    import redis.asyncio as redis
except ImportError:
    redis = None

try:
    import google.generativeai as genai
except ImportError:
    genai = None


# =========================
# Firebase Initialization
# =========================

fs = None
rtdb = None

if firebase_admin:
    try:
        if os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):

            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)

            firebase_admin.initialize_app(
                cred, {"databaseURL": settings.FIREBASE_DATABASE_URL}
            )

            fs = firestore.client()
            rtdb = db

            logger.info("Firebase initialized successfully.")

        else:
            logger.warning(
                f"Firebase credentials not found at "
                f"{settings.FIREBASE_CREDENTIALS_PATH}"
            )

    except Exception as e:
        logger.warning(f"Failed to initialize Firebase: {e}")


# =========================
# Redis Initialization
# =========================

redis_client = None

if redis:
    try:
        redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)

        logger.info("Redis initialized successfully.")

    except Exception as e:
        logger.warning(f"Failed to initialize Redis: {e}")


# =========================
# Gemini Initialization
# =========================

gemini = None

if genai and settings.GEMINI_API_KEY:
    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)

        gemini = genai

        logger.info("Gemini initialized successfully.")

    except Exception as e:
        logger.warning(f"Failed to initialize Gemini: {e}")
