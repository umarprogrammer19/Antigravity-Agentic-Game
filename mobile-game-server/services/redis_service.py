import json
from typing import Optional

from config import redis_client, logger
from models.game_schemas import LevelSchema, EnemyAction, PlayerTacticsProfile, SessionPlan

class RedisService:

    async def get_player_history_cache(self, uid: str) -> Optional[dict]:
        if not redis_client: return None
        try:
            cached = await redis_client.get(f"player:{uid}:history")
            if cached:
                return json.loads(cached)
        except Exception as e:
            logger.error(f"Redis error getting player history: {e}")
        return None

    async def set_player_history_cache(self, uid: str, history: dict) -> None:
        if not redis_client: return
        try:
            await redis_client.setex(f"player:{uid}:history", 300, json.dumps(history))
        except Exception as e:
            logger.error(f"Redis error setting player history: {e}")

    async def invalidate_player_history(self, uid: str) -> None:
        if not redis_client: return
        try:
            await redis_client.delete(f"player:{uid}:history")
        except Exception as e:
            logger.error(f"Redis error invalidating player history: {e}")

    async def get_level_cache(self, level_hash: str) -> Optional[LevelSchema]:
        if not redis_client: return None
        try:
            cached = await redis_client.get(f"level:{level_hash}")
            if cached:
                return LevelSchema.model_validate_json(cached)
        except Exception as e:
            logger.error(f"Redis error getting level cache: {e}")
        return None

    async def set_level_cache(self, level_hash: str, level: LevelSchema) -> None:
        if not redis_client: return
        try:
            await redis_client.setex(f"level:{level_hash}", 86400, level.model_dump_json())
        except Exception as e:
            logger.error(f"Redis error setting level cache: {e}")

    async def get_npc_decision_cache(self, decision_hash: str) -> Optional[EnemyAction]:
        if not redis_client: return None
        try:
            cached = await redis_client.get(f"npc:{decision_hash}")
            if cached:
                return EnemyAction.model_validate_json(cached)
        except Exception as e:
            logger.error(f"Redis error getting npc decision: {e}")
        return None

    async def set_npc_decision_cache(self, decision_hash: str, action: EnemyAction) -> None:
        if not redis_client: return
        try:
            await redis_client.setex(f"npc:{decision_hash}", 30, action.model_dump_json())
        except Exception as e:
            logger.error(f"Redis error setting npc decision: {e}")

    async def get_player_tactics(self, session_id: str) -> Optional[PlayerTacticsProfile]:
        if not redis_client: return None
        try:
            cached = await redis_client.get(f"session:{session_id}:player_tactics")
            if cached:
                return PlayerTacticsProfile.model_validate_json(cached)
        except Exception as e:
            logger.error(f"Redis error getting player tactics: {e}")
        return None

    async def set_player_tactics(self, session_id: str, tactics: PlayerTacticsProfile) -> None:
        if not redis_client: return
        try:
            await redis_client.setex(f"session:{session_id}:player_tactics", 3600, tactics.model_dump_json())
        except Exception as e:
            logger.error(f"Redis error setting player tactics: {e}")

    async def get_session_dm_plan(self, session_id: str) -> Optional[SessionPlan]:
        if not redis_client: return None
        try:
            cached = await redis_client.get(f"session:{session_id}:dm_plan")
            if cached:
                return SessionPlan.model_validate_json(cached)
        except Exception as e:
            logger.error(f"Redis error getting dm plan: {e}")
        return None

    async def set_session_dm_plan(self, session_id: str, plan: SessionPlan) -> None:
        if not redis_client: return
        try:
            await redis_client.setex(f"session:{session_id}:dm_plan", 3600, plan.model_dump_json())
        except Exception as e:
            logger.error(f"Redis error setting dm plan: {e}")

    async def check_rate_limit(self, uid: str, limit: int = 60) -> bool:
        if not redis_client: return True # Default to allowed if Redis is down
        key = f"ratelimit:{uid}:agent_calls"
        try:
            current = await redis_client.incr(key)
            if current == 1:
                await redis_client.expire(key, 60)
            return current <= limit
        except Exception as e:
            logger.error(f"Redis error in rate limit check: {e}")
            return True # Fail open

    async def health_check(self) -> bool:
        if not redis_client: return False
        try:
            res = await redis_client.ping() # type: ignore
            return res
        except Exception:
            return False

redis_service = RedisService()
