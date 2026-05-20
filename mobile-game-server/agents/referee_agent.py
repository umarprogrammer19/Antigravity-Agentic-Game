import json
import google.generativeai as genai
import math

from agents.base_agent import BaseAgent
from models.game_schemas import ActionResult


class RefereeAgent(BaseAgent):
    model_name = "gemini-2.5-flash"

    def _get_system_prompt(self) -> str:
        return """You are the referee for DungeonMind, a turn-based dungeon crawler.

YOUR ROLE:
Evaluate unusual or ambiguous player actions that standard rule validation
cannot handle. Determine if the action is valid and what its result is.

YOU ARE CALLED ONLY FOR EDGE CASES such as:
- Player attempts an action not in the standard action schema
- Simultaneous collision between player and enemy
- Special ability interaction not covered by static rules
- Any situation where the outcome is genuinely ambiguous

YOUR CONSTRAINTS:
- Be CONSISTENT. Same input = same output always.
- If in doubt: allow the action but reduce its effectiveness
- Never make the game unwinnable (don't trap the player)
- Output valid JSON matching ActionResult schema exactly
- result_narrative must be under 100 characters

DAMAGE FORMULA (always use this):
damage = max(1, attacker_attack - defender_defense)
XP for kill = floor(enemy.max_hp / 5)"""

    def _validate_move(
        self, action: dict, player_state: dict, board_state: dict
    ) -> ActionResult:
        p_pos = player_state.get("position", [0, 0])
        grid = board_state.get("grid", [])
        direction = action.get("direction", "wait")

        r, c = p_pos
        if direction == "up":
            r -= 1
        elif direction == "down":
            r += 1
        elif direction == "left":
            c -= 1
        elif direction == "right":
            c += 1

        new_pos = [r, c]

        if not grid or not (0 <= r < len(grid) and 0 <= c < len(grid[0])):
            return ActionResult(
                action_valid=False,
                invalid_reason="Out of bounds",
                result_type="invalid",
                result_narrative="You bump into a wall.",
                xp_gained=0,
                enemy_killed=False,
                floor_cleared=False,
                session_over=False,
            )

        if grid[r][c] == 0:
            return ActionResult(
                action_valid=False,
                invalid_reason="Wall",
                result_type="invalid",
                result_narrative="You bump into a wall.",
                xp_gained=0,
                enemy_killed=False,
                floor_cleared=False,
                session_over=False,
            )

        if grid[r][c] == 2:
            return ActionResult(
                action_valid=True,
                invalid_reason=None,
                result_type="floor_cleared",
                new_player_position=new_pos,
                damage_dealt=0,
                damage_taken=0,
                enemy_killed=False,
                xp_gained=0,
                floor_cleared=True,
                session_over=False,
                result_narrative="You reach the exit!",
            )

        all_enemies = board_state.get("all_enemy_positions", [])
        if new_pos in all_enemies:
            # We don't have full enemy details here, so we will fall back to Gemini OR if we assume it's just a move fail
            return ActionResult(
                action_valid=False,
                invalid_reason="Enemy collision during move (should be attack)",
                result_type="invalid",
                result_narrative="An enemy is there.",
                xp_gained=0,
                enemy_killed=False,
                floor_cleared=False,
                session_over=False,
            )

        return ActionResult(
            action_valid=True,
            invalid_reason=None,
            result_type="moved",
            new_player_position=new_pos,
            damage_dealt=0,
            damage_taken=0,
            enemy_killed=False,
            xp_gained=0,
            floor_cleared=False,
            session_over=False,
            result_narrative="You move forward.",
        )

    def _validate_attack(
        self, action: dict, player_state: dict, board_state: dict
    ) -> ActionResult:
        p_attack = player_state.get("attack", 0)
        target = action.get("target")

        # In a real game we'd have the target's stats in board_state. For simple logic we fallback to Gemini if complex.
        return (
            None  # Let Gemini handle if we don't have exact enemy stats in pure python
        )

    def _validate_special(
        self, action: dict, player_state: dict, board_state: dict
    ) -> ActionResult:
        return None  # Let Gemini handle special actions

    def _validate_wait(
        self, action: dict, player_state: dict, board_state: dict
    ) -> ActionResult:
        return ActionResult(
            action_valid=True,
            invalid_reason=None,
            result_type="wait",
            new_player_position=player_state.get("position"),
            damage_dealt=0,
            damage_taken=0,
            enemy_killed=False,
            xp_gained=0,
            floor_cleared=False,
            session_over=False,
            result_narrative="You wait.",
        )

    async def run(self, context: dict) -> ActionResult:
        action = context.get("action", {})
        player_state = context.get("player_state", {})
        board_state = context.get("board_state", {})

        a_type = action.get("type", "wait")

        # Pure Python Validation
        res = None
        if a_type == "move":
            res = self._validate_move(action, player_state, board_state)
        elif a_type == "attack":
            res = self._validate_attack(action, player_state, board_state)
        elif a_type == "wait":
            res = self._validate_wait(action, player_state, board_state)
        elif a_type == "special":
            res = self._validate_special(action, player_state, board_state)

        if res is not None and getattr(res, "action_valid", False):
            self.log_trace(
                reasoning=f"Player action '{a_type}' validated via rules",
                tool_called="validate_action",
                tool_input=action,
                tool_output=res.model_dump(),
                decision="Pure Python validation",
            )
            return res

        # EDGE CASE -> Call Gemini
        user_prompt = f"""Evaluate this unusual game situation:

PLAYER STATE: {json.dumps(player_state)}
ACTION ATTEMPTED: {json.dumps(action)}
BOARD STATE SUMMARY: {json.dumps(board_state)}
REASON STANDARD RULES FAILED: Complex action type '{a_type}' requiring AI evaluation.

Determine:
1. Is this action valid? (action_valid: true/false)
2. What is the result? (result_type)
3. Apply the damage formula if combat is involved: damage = max(1, attack - defense)
4. Write result_narrative (under 100 chars, present tense, specific)

Output the ActionResult JSON now."""

        generation_config = genai.GenerationConfig(
            temperature=0.1,
            top_p=0.9,
            max_output_tokens=600,
            response_mime_type="application/json",
            response_schema=ActionResult.model_json_schema(),
        )

        try:
            self.log_trace(
                reasoning="Evaluating complex action",
                tool_called="gemini_eval",
                tool_input={"action": action},
                tool_output={},
                decision="Calling Gemini",
            )
            response_text, tokens, duration = await self._call_gemini(
                user_prompt, generation_config
            )
            res, err = self._safe_parse_json(response_text, ActionResult)
            if err:
                raise Exception(err)
            return res
        except Exception:
            fallback = ActionResult(
                action_valid=False,
                invalid_reason="Action validation failed",
                result_type="invalid",
                result_narrative="The action fails.",
                xp_gained=0,
                enemy_killed=False,
                floor_cleared=False,
                session_over=False,
            )
            self.log_trace(
                reasoning="AI validation failed",
                tool_called="fallback_eval",
                tool_input={},
                tool_output={},
                decision="Returning invalid action",
            )
            return fallback
