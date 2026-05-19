import os
import logging
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

# Load .env
load_dotenv()

class Settings(BaseSettings):
    """Global configuration settings for the backend application."""
    GEMINI_API_KEY: str = ""
    FIREBASE_CREDENTIALS_PATH: str = "serviceAccountKey.json"
    REDIS_URL: str = "redis://localhost:6379"
    APP_ENV: str = "development"

    class Config:
        env_file = ".env"

settings = Settings()

# Setup logging
logging.basicConfig(level=logging.INFO)
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

# Initialize Firebase
fs = None
rtdb = None
if firebase_admin:
    try:
        if os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred, {
                'databaseURL': 'https://your-project.firebaseio.com' # Placeholder, replace in real env
            })
            fs = firestore.client()
            rtdb = db
            logger.info("Firebase initialized.")
        else:
            logger.warning(f"Firebase credentials not found at {settings.FIREBASE_CREDENTIALS_PATH}. Mocking Firebase.")
    except Exception as e:
        logger.warning(f"Failed to initialize Firebase: {e}. Mocking Firebase.")

# Initialize Redis
redis_client = None
if redis:
    try:
        redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)
        logger.info("Redis initialized.")
    except Exception as e:
        logger.warning(f"Failed to initialize Redis: {e}. Mocking Redis.")

# Initialize Gemini
gemini = None
if genai and settings.GEMINI_API_KEY:
    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        gemini = genai
        logger.info("Gemini initialized.")
    except Exception as e:
        logger.warning(f"Failed to initialize Gemini: {e}.")
