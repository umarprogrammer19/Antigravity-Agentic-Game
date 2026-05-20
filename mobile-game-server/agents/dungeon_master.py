import json
import uuid

import google.generativeai as genai

from agents.base_agent import BaseAgent
from models.game_schemas import SessionPlan
from exceptions import AgentValidationError

FALLBACK_SESSION_PLAN = SessionPlan(
    session_id=str(uuid.uuid4()),
    player_id="fallback_player",
    player_class="warrior",
    difficulty_level=3,
    theme="enchanted_forest",
    enemy_speed_multiplier=1.0,
    item_drop_rate=1.0,
    enemy_count_multiplier=1.0,
    boss_difficulty=2,
    narrative_intro="The ancient dungeon awaits. Danger lurks in every shadow.",
    dm_reasoning="Default fallback session created because AI service was unavailable. Using balanced settings.",
    recommended_strategy="Explore carefully. Heal often.",
)


class DungeonMasterAgent(BaseAgent):
    model_name = "gemini-2.5-flash"

    def _get_system_prompt(self) -> str:
        return """You are the Dungeon Master for DungeonMind, an AI-powered roguelike mobile game.

YOUR ROLE:
You analyze a player's game history and create a personalized session plan.
Your goal is to keep players engaged: challenged but not frustrated.

YOUR CONSTRAINTS:
- You MUST output valid JSON matching the SessionPlan schema exactly.
- You MUST explain your reasoning in the dm_reasoning field.
- You MUST follow the difficulty rules provided — do not deviate.
- difficulty_level must be an integer from 1 to 10.
- enemy_speed_multiplier must be between 0.6 and 1.5.
- item_drop_rate must be between 0.5 and 2.0.
- theme must be exactly one of: "cursed_library", "volcanic_caves", "enchanted_forest"
- narrative_intro must be exactly 1-2 sentences. Dark fantasy tone. No exclamation marks.
- dm_reasoning must explain EXACTLY why you chose each parameter. Be specific.

YOUR DECISION FRAMEWORK:
1. Compute loss_rate = losses / max(1, total_sessions)
2. Categorize: >70% loss = struggling, 50-70% = below average, 30-50% = average, <30% = excelling
3. Set difficulty based on category using the rules in your decision matrix
4. Select theme based on player history (variety is better than familiarity)
5. Generate narrative_intro that matches the theme and feels personal to this player's journey

IMPORTANT: Your output will be shown to judges evaluating AI reasoning quality.
Make your dm_reasoning detailed, specific, and traceable. Show your work."""

    def _compute_difficulty(self, history: dict) -> dict:
        total_sessions = history.get("total_sessions", 0)
        losses = history.get("losses", 0)
        avg_floors = history.get("avg_floors_cleared", 0.0)

        loss_rate = losses / max(1, total_sessions)

        def clamp(val, min_val, max_val):
            return max(min_val, min(val, max_val))

        if loss_rate > 0.70:
            return {
                "difficulty_level": clamp(int(avg_floors + 1), 1, 4),
                "enemy_speed_multiplier": 0.8,
                "item_drop_rate": 1.5,
                "enemy_count_multiplier": 0.8,
                "boss_difficulty": 1,
                "category": "struggling",
                "loss_rate": loss_rate,
            }
        elif loss_rate > 0.50:
            return {
                "difficulty_level": clamp(int(avg_floors + 2), 2, 6),
                "enemy_speed_multiplier": 1.0,
                "item_drop_rate": 1.0,
                "enemy_count_multiplier": 1.0,
                "boss_difficulty": 2,
                "category": "below average",
                "loss_rate": loss_rate,
            }
        elif loss_rate < 0.30:
            return {
                "difficulty_level": clamp(int(avg_floors + 3), 5, 10),
                "enemy_speed_multiplier": 1.3,
                "item_drop_rate": 0.8,
                "enemy_count_multiplier": 1.2,
                "boss_difficulty": 4,
                "category": "excelling",
                "loss_rate": loss_rate,
            }
        else:
            return {
                "difficulty_level": 5,
                "enemy_speed_multiplier": 1.0,
                "item_drop_rate": 1.0,
                "enemy_count_multiplier": 1.0,
                "boss_difficulty": 3,
                "category": "average",
                "loss_rate": loss_rate,
            }

    def _select_theme(self, history: dict) -> str:
        total_sessions = history.get("total_sessions", 0)
        if total_sessions == 0:
            return "enchanted_forest"

        last_5 = history.get("last_5_sessions", [])

        if last_5 and last_5[0].get("won", False):
            last_theme = last_5[0].get("theme")
            themes = ["enchanted_forest", "volcanic_caves", "cursed_library"]
            if last_theme in themes:
                themes.remove(last_theme)
            import random

            return random.choice(themes)

        consecutive_losses = 0
        for s in last_5:
            if not s.get("won", False):
                consecutive_losses += 1
            else:
                break
        if consecutive_losses >= 3:
            return "enchanted_forest"

        wins_by_theme = history.get("wins_by_theme", {})
        themes = ["enchanted_forest", "volcanic_caves", "cursed_library"]
        least_won_theme = "enchanted_forest"
        min_wins = float("inf")
        for t in themes:
            w = wins_by_theme.get(t, 0)
            if w < min_wins:
                min_wins = w
                least_won_theme = t

        return least_won_theme

    async def run(self, context: dict) -> SessionPlan:
        player_id = context.get("player_id", "unknown")
        player_class = context.get("player_class", "warrior")
        history = context.get(
            "history",
            {
                "total_sessions": 0,
                "wins": 0,
                "losses": 0,
                "avg_floors_cleared": 0.0,
                "total_enemies_killed": 0,
                "last_5_sessions": [],
            },
        )

        total_sessions = history.get("total_sessions", 0)
        wins = history.get("wins", 0)
        losses = history.get("losses", 0)
        loss_rate = losses / max(1, total_sessions)

        diff_params = self._compute_difficulty(history)

        # Step 1: Log the player history analysis
        self.log_trace(
            reasoning=f"Player has {wins} wins and {losses} losses. Loss rate: {loss_rate:.0%}",
            tool_called="compute_player_stats",
            tool_input={
                "wins": wins,
                "losses": losses,
                "total_sessions": total_sessions,
            },
            tool_output={"loss_rate": loss_rate, "category": diff_params["category"]},
            decision="Analyzing player performance category",
        )

        # Step 2: Compute and log difficulty decision
        difficulty_level = diff_params["difficulty_level"]
        enemy_speed = diff_params["enemy_speed_multiplier"]
        item_drop = diff_params["item_drop_rate"]

        mode = "easy" if loss_rate > 0.7 else "hard" if loss_rate < 0.3 else "normal"
        self.log_trace(
            reasoning=f"loss_rate = {losses}/{max(1, total_sessions)} = {loss_rate:.2f}. "
            f"{'Exceeds 70% threshold' if loss_rate > 0.7 else 'Below 30% threshold' if loss_rate < 0.3 else 'In average range'} "
            f"→ applying {mode} mode",
            tool_called="set_difficulty_params",
            tool_input={
                "loss_rate": loss_rate,
                "avg_floors_cleared": history.get("avg_floors_cleared", 0),
            },
            tool_output=diff_params,
            decision=f"Setting difficulty to {difficulty_level}/10",
        )

        # Step 3: Log theme selection with reason
        theme = self._select_theme(history)
        self.log_trace(
            reasoning=f"Selected {theme} based on player history",
            tool_called="select_theme",
            tool_input={
                "last_5_sessions": history.get("last_5_sessions", []),
                "wins_by_theme": history.get("wins_by_theme", {}),
            },
            tool_output={"theme": theme},
            decision=f"Theme: {theme}",
        )

        # Step 4: Call Gemini with EXACT system prompt and user prompt
        user_prompt = f"""Analyze this player and create a session plan.

PLAYER PROFILE:
- Player ID: {player_id}
- Class chosen for this session: {player_class}
- Total sessions played: {history.get('total_sessions', 0)}
- Total wins: {history.get('wins', 0)}
- Total losses: {history.get('losses', 0)}
- Average floors cleared: {history.get('avg_floors_cleared', 0.0):.1f}
- Most common death cause: {history.get('favorite_death_cause', 'Unknown')}
- Total enemies killed across all sessions: {history.get('total_enemies_killed', 0)}

LAST 5 SESSIONS:
{json.dumps(history.get('last_5_sessions', []), indent=2)}

DIFFICULTY DECISION MATRIX (follow this exactly):
- loss_rate > 70%: difficulty 1-4, item_drop_rate 1.5, enemy_speed 0.8
- loss_rate 50-70%: difficulty 3-6, item_drop_rate 1.0, enemy_speed 1.0
- loss_rate 30-50%: difficulty 5-7, item_drop_rate 1.0, enemy_speed 1.0
- loss_rate < 30%: difficulty 7-10, item_drop_rate 0.8, enemy_speed 1.3

THEME RULES:
- If this is their first session: pick "enchanted_forest"
- If they won last session: pick a DIFFERENT theme than last time
- If they've lost 3+ in a row: pick "enchanted_forest" (easiest)
- Otherwise: pick the theme they've won least on (variety)

Output a complete SessionPlan JSON now. Be specific in dm_reasoning.
Computed loss_rate = {history.get('losses', 0)} / {max(1, history.get('total_sessions', 0))} = {loss_rate:.2f}
"""

        generation_config = genai.GenerationConfig(
            temperature=0.7,
            top_p=0.95,
            max_output_tokens=1500,
            response_mime_type="application/json",
            response_schema=SessionPlan.model_json_schema(),
        )

        plan_obj = None
        validation_error = None
        duration = 0
        tokens = 0

        try:
            response_text, tokens, duration = await self._call_gemini(
                user_prompt, generation_config
            )
            plan_obj, validation_error = self._safe_parse_json(
                response_text, SessionPlan
            )

            # Step 6: On failure -> retry once
            if validation_error:
                retry_suffix = f"""

CRITICAL: Your previous response failed JSON validation with this error:
{validation_error}

You MUST output ONLY a valid JSON object. No explanation text. No markdown.
The JSON must exactly match this schema:
{SessionPlan.model_json_schema()}

Try again. Output the JSON object directly.
"""
                response_text, tokens2, duration2 = await self._call_gemini(
                    user_prompt + retry_suffix, generation_config
                )
                tokens += tokens2
                duration += duration2
                plan_obj, validation_error = self._safe_parse_json(
                    response_text, SessionPlan
                )

                if validation_error:
                    raise AgentValidationError("Retry failed validation.")

        except Exception as e:
            # Step 7: On retry failure -> return FALLBACK_SESSION_PLAN
            plan_obj = FALLBACK_SESSION_PLAN.model_copy(deep=True)
            plan_obj.session_id = str(uuid.uuid4())
            self.log_trace(
                reasoning=f"AI generation failed ({str(e)}). Using fallback.",
                tool_called="use_fallback",
                tool_input={"history": history},
                tool_output={"session_id": plan_obj.session_id},
                decision="Used fallback session plan",
                fallback_used=True,
            )
            return plan_obj

        # Generate a new session_id if AI forgot or didn't provide a valid one
        if not getattr(plan_obj, "session_id", None) or len(plan_obj.session_id) < 10:
            plan_obj.session_id = str(uuid.uuid4())

        # Step 8: Log final decision
        self.log_trace(
            reasoning="Session plan finalized",
            tool_called="finalize_session_plan",
            tool_input={},
            tool_output=plan_obj.model_dump(),
            decision=f"Session plan ready. Player will face difficulty level {plan_obj.difficulty_level}.",
            duration_ms=duration,
            tokens_used=tokens,
        )

        return plan_obj
