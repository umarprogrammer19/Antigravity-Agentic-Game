import json
from datetime import datetime, timezone
try:
    from firebase_admin import firestore
except ImportError:
    firestore = None

from config import fs, rtdb, redis_client, logger

class FirebaseService:

    async def get_player_history(self, player_id: str) -> dict:
        """Get player stats and last 5 sessions. Checks Redis first."""
        cache_key = f"player:{player_id}:history"
        
        try:
            if redis_client:
                cached = await redis_client.get(cache_key)
                if cached:
                    return json.loads(cached)
        except Exception as e:
            logger.error(f"Redis get error in get_player_history: {e}")

        history = {
            "total_sessions": 0,
            "wins": 0,
            "losses": 0,
            "avg_floors_cleared": 0.0,
            "total_enemies_killed": 0,
            "favorite_death_cause": None,
            "last_5_sessions": []
        }

        if not fs:
            return history

        try:
            # Read stats
            stats_ref = fs.collection("players").document(player_id).collection("stats").document("all_time")
            stats_doc = stats_ref.get()

            if stats_doc.exists:
                data = stats_doc.to_dict()
                history["total_sessions"] = data.get("total_sessions", 0)
                history["wins"] = data.get("wins", 0)
                history["losses"] = data.get("losses", 0)
                history["avg_floors_cleared"] = data.get("avg_floors_cleared", 0.0)
                history["total_enemies_killed"] = data.get("total_enemies_killed", 0)
                history["favorite_death_cause"] = data.get("favorite_death_cause")
                history["wins_by_theme"] = data.get("wins_by_theme", {})

            # Read sessions
            sessions_query = fs.collection("players").document(player_id).collection("sessions")\
                .order_by("started_at", direction=firestore.Query.DESCENDING).limit(5)
            sessions_docs = sessions_query.stream()
            
            for doc in sessions_docs:
                history["last_5_sessions"].append(doc.to_dict())

            # Read high score from leaderboard
            leaderboard_doc = fs.collection("leaderboard").document(player_id).get()
            if leaderboard_doc.exists:
                history["high_score"] = leaderboard_doc.get("score")
            else:
                history["high_score"] = 0

            # Cache
            try:
                if redis_client:
                    await redis_client.setex(cache_key, 300, json.dumps(history))
            except Exception as e:
                logger.error(f"Redis set error in get_player_history: {e}")

        except Exception as e:
            logger.error(f"Firestore error in get_player_history: {e}")
            
        return history

    async def save_session(self, session_data: dict) -> dict:
        """Save completed session and update stats."""
        uid = session_data.get("player_id")
        session_id = session_data.get("session_id")
        
        if not fs or not uid or not session_id:
            return {}

        try:
            # Write session document
            fs.collection("players").document(uid).collection("sessions").document(session_id).set(session_data)

            # Update stats atomically
            stats_ref = fs.collection("players").document(uid).collection("stats").document("all_time")
            
            won = 1 if session_data.get("won", False) else 0
            loss = 1 if not won else 0
            
            updates = {
                "total_sessions": firestore.Increment(1),
                "wins": firestore.Increment(won),
                "losses": firestore.Increment(loss),
                "total_floors_cleared": firestore.Increment(session_data.get("floors_cleared", 0)),
                "total_enemies_killed": firestore.Increment(session_data.get("enemies_killed", 0)),
                "last_updated": firestore.SERVER_TIMESTAMP
            }
            
            theme = session_data.get("theme")
            if theme:
                updates[f"sessions_by_theme.{theme}"] = firestore.Increment(1)
                if won:
                    updates[f"wins_by_theme.{theme}"] = firestore.Increment(1)

            # Check if doc exists to update or set
            doc_snap = stats_ref.get()
            if not doc_snap.exists:
                # Need to set initial
                init_data = {
                    "total_sessions": 1,
                    "wins": won,
                    "losses": loss,
                    "total_floors_cleared": session_data.get("floors_cleared", 0),
                    "total_enemies_killed": session_data.get("enemies_killed", 0),
                    "avg_floors_cleared": float(session_data.get("floors_cleared", 0)),
                    "last_updated": firestore.SERVER_TIMESTAMP,
                    "sessions_by_theme": {theme: 1} if theme else {},
                    "wins_by_theme": {theme: won} if theme else {}
                }
                stats_ref.set(init_data)
            else:
                stats_ref.update(updates)

                # Recalculate avg_floors_cleared after update
                updated_doc = stats_ref.get()
                if updated_doc.exists:
                    data = updated_doc.to_dict()
                    total_sessions_new = data.get("total_sessions", 1)
                    total_floors_new = data.get("total_floors_cleared", 0)
                    avg_floors = total_floors_new / max(1, total_sessions_new)
                    stats_ref.update({"avg_floors_cleared": avg_floors})

            # Update leaderboard
            score = session_data.get("score", 0)
            if score > 0:
                leaderboard_ref = fs.collection("leaderboard").document(uid)
                current = leaderboard_ref.get()
                if not current.exists or current.get("score", 0) < score:
                    leaderboard_ref.set({
                        "uid": uid,
                        "display_name": session_data.get("display_name", "Player"),
                        "score": score,
                        "floors_cleared": session_data.get("floors_cleared", 0),
                        "class_used": session_data.get("player_class", "unknown"),
                        "theme": theme,
                        "achieved_at": firestore.SERVER_TIMESTAMP,
                        "session_id": session_id
                    })

            # Invalidate Redis
            try:
                if redis_client:
                    await redis_client.delete(f"player:{uid}:history")
            except Exception as e:
                logger.error(f"Redis delete error in save_session: {e}")

            # Return updated stats (best effort)
            updated_snap = stats_ref.get()
            return updated_snap.to_dict() if updated_snap.exists else {}
            
        except Exception as e:
            logger.error(f"Firestore error in save_session: {e}")
            return {}

    async def save_traces(self, session_id: str, traces: list) -> None:
        """Save agent trace entries to Firestore and Realtime DB."""
        if not fs or not session_id:
            return

        try:
            batch = fs.batch()
            parent_ref = fs.collection("traces").document(session_id)
            
            # Create or update parent
            batch.set(parent_ref, {
                "session_id": session_id,
                "total_decisions": firestore.Increment(len(traces)),
                "last_updated": firestore.SERVER_TIMESTAMP
            }, merge=True)
            
            for trace in traces:
                trace_dict = trace.model_dump() if hasattr(trace, "model_dump") else trace
                ref = parent_ref.collection("entries").document()
                batch.set(ref, {
                    **trace_dict,
                    "timestamp": firestore.SERVER_TIMESTAMP
                })
            batch.commit()
            
            # Update RTDB
            if rtdb and traces:
                try:
                    last_trace = traces[-1]
                    trace_dict = last_trace.model_dump() if hasattr(last_trace, "model_dump") else last_trace
                    
                    rtdb_ref = rtdb.reference(f"/sessions/{session_id}/live_state/ai_status")
                    rtdb_ref.set({
                        "is_thinking": False,
                        "last_agent": trace_dict.get("agent", "Unknown"),
                        "last_decision_summary": trace_dict.get("decision", "")[:80],
                        "last_updated": {".sv": "timestamp"}
                    })
                except Exception as e:
                    logger.error(f"RTDB error in save_traces: {e}")
                    
        except Exception as e:
            logger.error(f"Firestore error in save_traces: {e}")

    async def get_traces(self, session_id: str) -> dict:
        """Read traces for a session."""
        result = {
            "session_id": session_id,
            "total_decisions": 0,
            "created_at": None,
            "entries": []
        }
        
        if not fs:
            return result
            
        try:
            parent_doc = fs.collection("traces").document(session_id).get()
            if parent_doc.exists:
                data = parent_doc.to_dict()
                result["total_decisions"] = data.get("total_decisions", 0)
                result["created_at"] = data.get("created_at")
                
            entries_docs = fs.collection("traces").document(session_id).collection("entries")\
                .order_by("timestamp").stream()
                
            for doc in entries_docs:
                result["entries"].append(doc.to_dict())
                
        except Exception as e:
            logger.error(f"Firestore error in get_traces: {e}")
            
        return result

    async def get_leaderboard(self, limit: int = 20) -> list:
        """Get global leaderboard."""
        board = []
        if not fs:
            return board
            
        try:
            docs = fs.collection("leaderboard").order_by("score", direction=firestore.Query.DESCENDING).limit(limit).stream()
            for doc in docs:
                board.append(doc.to_dict())
        except Exception as e:
            logger.error(f"Firestore error in get_leaderboard: {e}")
            
        return board

    async def update_live_state(self, session_id: str, update: dict) -> None:
        """Update live game state in RTDB."""
        if not rtdb or not session_id:
            return
            
        try:
            ref = rtdb.reference(f"/sessions/{session_id}/live_state")
            ref.update(update)
        except Exception as e:
            logger.error(f"RTDB error in update_live_state: {e}")

firebase_service = FirebaseService()
