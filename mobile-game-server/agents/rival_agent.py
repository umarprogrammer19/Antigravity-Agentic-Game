import json
import hashlib
import google.generativeai as genai

from agents.base_agent import BaseAgent
from models.game_schemas import EnemyAction
from exceptions import AgentValidationError
from config import redis_client


def manhattan_distance(p1, p2):
    return abs(p1[0] - p2[0]) + abs(p1[1] - p2[1])


def move_toward(start, target, grid):
    r, c = start
    tr, tc = target
    moves = []
    if r < tr:
        moves.append(("down", [r + 1, c]))
    if r > tr:
        moves.append(("up", [r - 1, c]))
    if c < tc:
        moves.append(("right", [r, c + 1]))
    if c > tc:
        moves.append(("left", [r, c - 1]))

    for d, (nr, nc) in moves:
        if 0 <= nr < len(grid) and 0 <= nc < len(grid[0]):
            if grid[nr][nc] in (1, 3):
                return d
    return "wait"


def move_away(start, target, grid):
    r, c = start
    tr, tc = target
    moves = []
    if r < tr:
        moves.append(("up", [r - 1, c]))
    if r > tr:
        moves.append(("down", [r + 1, c]))
    if c < tc:
        moves.append(("left", [r, c - 1]))
    if c > tc:
        moves.append(("right", [r, c + 1]))

    for d, (nr, nc) in moves:
        if 0 <= nr < len(grid) and 0 <= nc < len(grid[0]):
            if grid[nr][nc] in (1, 3):
                return d
    return "wait"


class RivalAgent(BaseAgent):
    model_name = "gemini-2.5-flash"

    def _get_system_prompt(self) -> str:
        return """You are the tactical AI controlling enemies in DungeonMind dungeon crawler.

YOUR ROLE:
Choose the optimal action for one enemy based on the current board state
and what you've learned about the player's tactics.

YOUR CONSTRAINTS:
- Output ONLY valid JSON matching EnemyAction schema
- action_type must be exactly: "move", "attack", "ability", or "wait"
- direction (for move) must be exactly: "up", "down", "left", or "right"
- target_position must be a valid [row, col] within the grid
- reasoning must be SHORT (max 80 chars) — it displays in the game's AI panel
- You must update updated_tactics based on what you observed this turn

TACTICAL PRINCIPLES:
1. SURVIVAL: If enemy HP < 20% of max, consider retreating unless it's a tank type
2. COUNTER-TACTICS: Use player_tactics_profile to counter their patterns
3. BASE BEHAVIOR: Fall back to the enemy's natural behavior type

COUNTER-TACTIC EXAMPLES:
- Player prefers_melee=true AND this enemy has ranged capability → keep 2 tile distance
- Player prefers_ranged=true → rush close (they can't hit you)
- Player dominant_direction="right" → position yourself to the right to cut them off
- Player retreats_when_low_hp=true → block their retreat path
- Player corners_preference=true → spread away from corners

FORBIDDEN ACTIONS:
- Do not move into wall tiles (grid value = 0)
- Do not move outside grid bounds
- Do not attack your own allied enemies
- Do not move into lava tiles if enemy type is NOT fire_elemental or lava_sprite

Always update updated_tactics with what you observed this turn.
Increment turns_observed by 1.
Refine the player profile based on their last move."""

    def _base_behavior_fallback(
        self, enemy_state: dict, player_state: dict, board_state: dict
    ) -> EnemyAction:
        behavior = enemy_state.get("base_behavior", "rush_melee")
        e_pos = enemy_state.get("position", [0, 0])
        p_pos = player_state.get("position", [0, 0])
        dist = manhattan_distance(e_pos, p_pos)
        grid = board_state.get("grid", [])

        enemy_id = enemy_state.get("id", "e_unknown")

        if behavior in ("rush_melee", "tank_melee", "swarm_melee", "slow_tank"):
            if dist == 1:
                return EnemyAction(
                    enemy_id=enemy_id,
                    action_type="attack",
                    direction=None,
                    target_position=p_pos,
                    damage=max(1, enemy_state.get("attack", 0) - 0),
                    reasoning="Attacking adjacent player",
                    updated_tactics={},
                )
            else:
                direction = move_toward(e_pos, p_pos, grid)
                if direction != "wait":
                    return EnemyAction(
                        enemy_id=enemy_id,
                        action_type="move",
                        direction=direction,
                        target_position=None,
                        damage=None,
                        reasoning="Moving toward player",
                        updated_tactics={},
                    )

        elif behavior in ("ranged_2tile", "flee_then_attack"):
            if dist <= 2:
                if dist == 1 and behavior == "flee_then_attack":
                    direction = move_away(e_pos, p_pos, grid)
                    if direction != "wait":
                        return EnemyAction(
                            enemy_id=enemy_id,
                            action_type="move",
                            direction=direction,
                            target_position=None,
                            damage=None,
                            reasoning="Fleeing from player",
                            updated_tactics={},
                        )
                return EnemyAction(
                    enemy_id=enemy_id,
                    action_type="attack",
                    direction=None,
                    target_position=p_pos,
                    damage=max(1, enemy_state.get("attack", 0) - 0),
                    reasoning="Ranged attack on player",
                    updated_tactics={},
                )
            else:
                direction = move_toward(e_pos, p_pos, grid)
                if direction != "wait":
                    return EnemyAction(
                        enemy_id=enemy_id,
                        action_type="move",
                        direction=direction,
                        target_position=None,
                        damage=None,
                        reasoning="Moving to range",
                        updated_tactics={},
                    )

        elif behavior == "hit_and_run":
            if dist == 1:
                return EnemyAction(
                    enemy_id=enemy_id,
                    action_type="attack",
                    direction=None,
                    target_position=p_pos,
                    damage=max(1, enemy_state.get("attack", 0) - 0),
                    reasoning="Hit and run attack",
                    updated_tactics={},
                )
            else:
                direction = move_toward(e_pos, p_pos, grid)
                if direction != "wait":
                    return EnemyAction(
                        enemy_id=enemy_id,
                        action_type="move",
                        direction=direction,
                        target_position=None,
                        damage=None,
                        reasoning="Closing in",
                        updated_tactics={},
                    )

        elif behavior == "heals_nearby_enemies":
            direction = move_toward(e_pos, p_pos, grid)
            if direction != "wait":
                return EnemyAction(
                    enemy_id=enemy_id,
                    action_type="move",
                    direction=direction,
                    target_position=None,
                    damage=None,
                    reasoning="Moving",
                    updated_tactics={},
                )

        return EnemyAction(
            enemy_id=enemy_id,
            action_type="wait",
            direction=None,
            target_position=None,
            damage=None,
            reasoning="Waiting",
            updated_tactics={},
        )

    async def run(self, context: dict) -> EnemyAction:
        enemy_state = context.get("enemy_state", {})
        player_state = context.get("player_state", {})
        board_state = context.get("board_state", {})
        player_last_5_moves = context.get("player_last_5_moves", [])
        player_tactics_profile = context.get("player_tactics_profile", {})

        state_str = json.dumps(
            {
                "enemy_pos": enemy_state.get("position"),
                "enemy_hp_bucket": enemy_state.get("hp", 0) // 10,
                "player_pos": player_state.get("position"),
                "last_2_moves": player_last_5_moves[-2:],
            }
        )
        decision_hash = hashlib.md5(state_str.encode()).hexdigest()[:12]
        cache_key = f"npc:{decision_hash}"

        try:
            if redis_client:
                cached = await redis_client.get(cache_key)
                if cached:
                    action, _ = self._safe_parse_json(cached, EnemyAction)
                    if action:
                        self.log_trace(
                            "Cache hit",
                            "check_cache",
                            {"key": cache_key},
                            {"hit": True},
                            "Using cached action",
                        )
                        return action
        except Exception:
            pass

        grid = board_state.get("grid", [])
        rows = len(grid) if grid else 0
        cols = len(grid[0]) if grid and grid[0] else 0

        def get_adjacent_walls(pos, grid):
            if not grid:
                return 0
            w = 0
            r, c = pos
            for nr, nc in [(r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)]:
                if 0 <= nr < len(grid) and 0 <= nc < len(grid[0]) and grid[nr][nc] == 0:
                    w += 1
            return w

        def get_valid_moves(pos, board_state):
            grid = board_state.get("grid", [])
            if not grid:
                return []
            r, c = pos
            moves = []
            if r > 0 and grid[r - 1][c] in (1, 3):
                moves.append("up")
            if r < len(grid) - 1 and grid[r + 1][c] in (1, 3):
                moves.append("down")
            if c > 0 and grid[r][c - 1] in (1, 3):
                moves.append("left")
            if c < len(grid[0]) - 1 and grid[r][c + 1] in (1, 3):
                moves.append("right")
            return moves

        user_prompt = f"""Choose the action for this enemy on its turn.

ENEMY STATE:
- ID: {enemy_state.get('id')}
- Type: {enemy_state.get('type')}
- Position: {enemy_state.get('position')} [row, col]
- HP: {enemy_state.get('hp')}/{enemy_state.get('max_hp')}
- Attack: {enemy_state.get('attack')}, Defense: {enemy_state.get('defense')}
- Natural behavior: {enemy_state.get('base_behavior')}

PLAYER STATE:
- Position: {player_state.get('position')} [row, col]
- HP: {player_state.get('hp')}
- Class: {player_state.get('class')}
- Distance from this enemy: {manhattan_distance(enemy_state.get('position', [0,0]), player_state.get('position', [0,0]))} tiles

PLAYER'S LAST 5 MOVES:
{player_last_5_moves}

PLAYER TACTICS PROFILE (learned so far):
{json.dumps(player_tactics_profile, indent=2)}

BOARD STATE (simplified):
- Grid size: {rows}x{cols}
- Other enemy positions: {board_state.get('all_enemy_positions', [])}
- Walls adjacent to this enemy: {get_adjacent_walls(enemy_state.get('position', [0,0]), board_state.get('grid', []))}

Available moves from {enemy_state.get('position', [0,0])}:
{get_valid_moves(enemy_state.get('position', [0,0]), board_state)}

Choose the best action. Update updated_tactics to reflect what you observed.
Keep reasoning under 80 characters — it shows in the game's live AI panel."""

        generation_config = genai.GenerationConfig(
            temperature=0.4,
            top_p=0.9,
            max_output_tokens=600,
            response_mime_type="application/json",
            response_schema=EnemyAction.model_json_schema(),
        )

        try:
            self.log_trace(
                reasoning=f"Enemy {enemy_state.get('id')} at {enemy_state.get('position')} evaluating action",
                tool_called="decide_enemy_action",
                tool_input={
                    "enemy_pos": enemy_state.get("position"),
                    "player_pos": player_state.get("position"),
                },
                tool_output={},
                decision="Calling Gemini for tactical decision",
            )

            response_text, tokens, duration = await self._call_gemini(
                user_prompt, generation_config
            )
            action, err = self._safe_parse_json(response_text, EnemyAction)

            if err:
                action = self._base_behavior_fallback(
                    enemy_state, player_state, board_state
                )
            else:
                action.enemy_id = enemy_state.get("id", "e_unknown")
        except Exception:
            action = self._base_behavior_fallback(
                enemy_state, player_state, board_state
            )

        try:
            if redis_client:
                tactics_key = f"session:{self.session_id}:player_tactics"
                if action.updated_tactics:
                    await redis_client.setex(
                        tactics_key, 3600, json.dumps(action.updated_tactics)
                    )

                await redis_client.setex(cache_key, 30, action.model_dump_json())
        except Exception:
            pass

        return action
