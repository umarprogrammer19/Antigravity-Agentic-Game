import hashlib
import uuid
import google.generativeai as genai

from agents.base_agent import BaseAgent
from models.game_schemas import ItemSpec, LevelSchema, validate_level_playable
from exceptions import AgentValidationError
from fallbacks.fallback_levels import FALLBACK_LEVELS
from config import redis_client


class LevelGeneratorAgent(BaseAgent):
    model_name = "gemini-2.5-flash"

    def _get_system_prompt(self) -> str:
        return """You are the Dungeon Architect for DungeonMind, a roguelike dungeon crawler.

YOUR ROLE:
Generate complete dungeon level layouts as structured JSON.
Every level you create must be playable, balanced, and thematically consistent.

YOUR CONSTRAINTS — FOLLOW THESE EXACTLY:

GRID RULES:
- Grid is a 2D array of integers. Row 0 is the top. Col 0 is the left.
- Tile values: 0=wall, 1=floor, 2=unused, 3=lava(volcanic only), 4=trap, 5=item
- ALL border tiles (row 0, last row, col 0, last col) MUST be walls (0)
- There must be a walkable path from player_start to exit_position (no isolated sections)
- player_start: always in top-left quadrant (rows 1-4, cols 1-4)
- exit_position: always in bottom-right quadrant (last 4 rows, last 4 cols)

GRID SIZES:
- difficulty 1-3: exactly 10 rows × 10 cols
- difficulty 4-6: exactly 12 rows × 12 cols  
- difficulty 7-10: exactly 15 rows × 15 cols

ENEMY PLACEMENT RULES:
- No enemy within 3 tiles of player_start (Manhattan distance)
- No two enemies on the same tile
- No enemy on item tile or exit tile
- Enemy positions must be on floor tiles (value=1 or 3)
- Enemy IDs: "e1", "e2", "e3", etc.

ITEM PLACEMENT RULES:
- No item on player_start, exit, or enemy position
- Items must be on floor tiles
- Item IDs: "i1", "i2", "i3", etc.

ENEMY COUNT BY DIFFICULTY:
1-2: 2 enemies | 3-4: 3 enemies | 5-6: 4-5 enemies | 7-8: 5-6 enemies | 9-10: 7-8 enemies

ITEM COUNT:
Base count = round(item_drop_rate × 1.5), clamped to 0-4

THEME-SPECIFIC RULES:
- "cursed_library": use enemy types: shadow_mage, book_golem, librarian. Maze-like corridors.
- "volcanic_caves": use enemy types: fire_elemental, rock_troll, lava_sprite. Use lava tiles (3) in open areas.
- "enchanted_forest": use enemy types: goblin, forest_witch, druid. Open rooms with pillar-like walls.

narrative_hook: Exactly 1 sentence. Present tense. Sets the atmosphere. No exclamation marks.
difficulty_score: Your honest estimate of how hard this level is (1.0-10.0).
estimated_turns_to_clear: Realistic estimate. Average player: 10-25 turns per floor.

VALIDATION CHECKLIST (verify before outputting):
✓ All border tiles are 0
✓ player_start tile value is 1 (floor)
✓ exit_position tile value is 1 (floor) [set it to 1 in the grid]
✓ All enemy positions are valid floor tiles
✓ All item positions are valid floor tiles
✓ grid_rows and grid_cols match the actual grid dimensions
✓ enemy_count matches len(enemies)"""

    def _get_enemy_stats_for_theme(self, theme: str, difficulty_level: int) -> str:
        if theme == "cursed_library":
            return "SHADOW_MAGE: hp=30, attack=12, defense=2, behavior=ranged_2tile\nBOOK_GOLEM: hp=60, attack=8, defense=15, behavior=tank_melee\nLIBRARIAN: hp=20, attack=15, defense=0, behavior=flee_then_attack"
        elif theme == "volcanic_caves":
            return "FIRE_ELEMENTAL: hp=25, attack=18, defense=0, behavior=rush_melee\nROCK_TROLL: hp=80, attack=10, defense=20, behavior=slow_tank\nLAVA_SPRITE: hp=15, attack=22, defense=0, behavior=hit_and_run"
        elif theme == "enchanted_forest":
            return "GOBLIN: hp=20, attack=8, defense=3, behavior=swarm_melee\nFOREST_WITCH: hp=35, attack=14, defense=4, behavior=ranged_2tile\nDRUID: hp=50, attack=6, defense=8, behavior=heals_nearby_enemies"
        return ""

    def _get_enemy_count(self, difficulty_level: int) -> int:
        if difficulty_level <= 2:
            return 2
        if difficulty_level <= 4:
            return 3
        if difficulty_level <= 6:
            return 4
        if difficulty_level <= 8:
            return 5
        return 7

    def _get_grid_size(self, difficulty_level: int) -> tuple[int, int]:
        if difficulty_level <= 3:
            return 10, 10
        if difficulty_level <= 6:
            return 12, 12
        return 15, 15

from exceptions import AgentValidationError
from fallbacks.fallback_levels import FALLBACK_LEVELS
from config import redis_client


class LevelGeneratorAgent(BaseAgent):
    model_name = "gemini-2.5-flash"

    def _get_system_prompt(self) -> str:
        return """You are the Dungeon Architect for DungeonMind, a roguelike dungeon crawler.

YOUR ROLE:
Generate complete dungeon level layouts as structured JSON.
Every level you create must be playable, balanced, and thematically consistent.

YOUR CONSTRAINTS — FOLLOW THESE EXACTLY:

GRID RULES:
- Grid is a 2D array of integers. Row 0 is the top. Col 0 is the left.
- Tile values: 0=wall, 1=floor, 2=unused, 3=lava(volcanic only), 4=trap, 5=item
- ALL border tiles (row 0, last row, col 0, last col) MUST be walls (0)
- There must be a walkable path from player_start to exit_position (no isolated sections)
- player_start: always in top-left quadrant (rows 1-4, cols 1-4)
- exit_position: always in bottom-right quadrant (last 4 rows, last 4 cols)

GRID SIZES:
- difficulty 1-3: exactly 10 rows × 10 cols
- difficulty 4-6: exactly 12 rows × 12 cols  
- difficulty 7-10: exactly 15 rows × 15 cols

ENEMY PLACEMENT RULES:
- No enemy within 3 tiles of player_start (Manhattan distance)
- No two enemies on the same tile
- No enemy on item tile or exit tile
- Enemy positions must be on floor tiles (value=1 or 3)
- Enemy IDs: "e1", "e2", "e3", etc.

ITEM PLACEMENT RULES:
- No item on player_start, exit, or enemy position
- Items must be on floor tiles
- Item IDs: "i1", "i2", "i3", etc.

ENEMY COUNT BY DIFFICULTY:
1-2: 2 enemies | 3-4: 3 enemies | 5-6: 4-5 enemies | 7-8: 5-6 enemies | 9-10: 7-8 enemies

ITEM COUNT:
Base count = round(item_drop_rate × 1.5), clamped to 0-4

THEME-SPECIFIC RULES:
- "cursed_library": use enemy types: shadow_mage, book_golem, librarian. Maze-like corridors.
- "volcanic_caves": use enemy types: fire_elemental, rock_troll, lava_sprite. Use lava tiles (3) in open areas.
- "enchanted_forest": use enemy types: goblin, forest_witch, druid. Open rooms with pillar-like walls.

narrative_hook: Exactly 1 sentence. Present tense. Sets the atmosphere. No exclamation marks.
difficulty_score: Your honest estimate of how hard this level is (1.0-10.0).
estimated_turns_to_clear: Realistic estimate. Average player: 10-25 turns per floor.

VALIDATION CHECKLIST (verify before outputting):
✓ All border tiles are 0
✓ player_start tile value is 1 (floor)
✓ exit_position tile value is 1 (floor) [set it to 1 in the grid]
✓ All enemy positions are valid floor tiles
✓ All item positions are valid floor tiles
✓ grid_rows and grid_cols match the actual grid dimensions
✓ enemy_count matches len(enemies)"""

    def _get_enemy_stats_for_theme(self, theme: str, difficulty_level: int) -> str:
        if theme == "cursed_library":
            return "SHADOW_MAGE: hp=30, attack=12, defense=2, behavior=ranged_2tile\nBOOK_GOLEM: hp=60, attack=8, defense=15, behavior=tank_melee\nLIBRARIAN: hp=20, attack=15, defense=0, behavior=flee_then_attack"
        elif theme == "volcanic_caves":
            return "FIRE_ELEMENTAL: hp=25, attack=18, defense=0, behavior=rush_melee\nROCK_TROLL: hp=80, attack=10, defense=20, behavior=slow_tank\nLAVA_SPRITE: hp=15, attack=22, defense=0, behavior=hit_and_run"
        elif theme == "enchanted_forest":
            return "GOBLIN: hp=20, attack=8, defense=3, behavior=swarm_melee\nFOREST_WITCH: hp=35, attack=14, defense=4, behavior=ranged_2tile\nDRUID: hp=50, attack=6, defense=8, behavior=heals_nearby_enemies"
        return ""

    def _get_enemy_count(self, difficulty_level: int) -> int:
        if difficulty_level <= 2:
            return 2
        if difficulty_level <= 4:
            return 3
        if difficulty_level <= 6:
            return 4
        if difficulty_level <= 8:
            return 5
        return 7

    def _get_grid_size(self, difficulty_level: int) -> tuple[int, int]:
        if difficulty_level <= 3:
            return 10, 10
        if difficulty_level <= 6:
            return 12, 12
        return 15, 15

    def _build_user_prompt(self, context: dict) -> str:
        floor_number = context.get("floor_number", 1)
        theme = context.get("theme", "enchanted_forest")
        difficulty_level = context.get("difficulty_level", 1)
        enemy_speed_multiplier = context.get("enemy_speed_multiplier", 1.0)
        item_drop_rate = context.get("item_drop_rate", 1.0)
        player_class = context.get("player_class", "warrior")
        player_current_hp = context.get("player_current_hp", 150)
        player_move_history = context.get("player_move_history", [])

        grid_str = (
            "10x10"
            if difficulty_level <= 3
            else "12x12" if difficulty_level <= 6 else "15x15"
        )
        enemy_count = self._get_enemy_count(difficulty_level)
        item_count = max(0, min(4, round(item_drop_rate * 1.5)))
        boss_floor = (
            "YES - include one boss enemy with 3x hp" if floor_number == 5 else "No"
        )

        return f"""Generate a dungeon level with these specifications:

SESSION CONTEXT:
- Floor number: {floor_number} of 5
- Theme: {theme}
- Difficulty level: {difficulty_level}/10
- Enemy speed multiplier: {enemy_speed_multiplier}
- Item drop rate: {item_drop_rate}
- Player class: {player_class}
- Player current HP: {player_current_hp} (if low, consider adding a health_potion item)

CLASS ADAPTATION:
- warrior: favor melee enemies and wider corridors for close combat.
- mage: avoid too many tank enemies, add sight lines, and include a health potion when possible.
- ranger: favor alternate routes and mobile enemies over dead-end mazes.

PLAYER MOVE HISTORY (Last floor):
{player_move_history if player_move_history else "No history available (first floor)."}

ENEMY STATS FOR THIS THEME AND DIFFICULTY:
{self._get_enemy_stats_for_theme(theme, difficulty_level)}

Calculate:
- Grid size: {grid_str}
- Enemy count: {enemy_count}
- Item count: {item_count} (clamped to 0-4)
- Is this a boss floor? {boss_floor}

Generate the complete LevelSchema JSON now.
Remember: ALL border tiles must be 0. Verify path exists from player_start to exit.
narrative_hook should reference the {theme} atmosphere specifically.
player_analysis MUST contain your tactical analysis of the player_move_history provided above, and how this new level counters or complements their playstyle."""

    def _get_level_hash(self, context: dict) -> str:
        data = f"{context.get('difficulty_level', 1)}-{context.get('theme', 'enchanted_forest')}-{context.get('player_class', 'warrior')}-{context.get('floor_number', 1)}"
        return hashlib.md5(data.encode()).hexdigest()

    def _get_fallback_level(
        self, theme: str, floor_number: int, player_class: str = "warrior"
    ) -> LevelSchema:
        fallback = FALLBACK_LEVELS.get(theme, FALLBACK_LEVELS["enchanted_forest"])
        fallback_copy = fallback.model_copy(deep=True)
        fallback_copy.floor_number = floor_number
        fallback_copy.level_id = f"fallback_{uuid.uuid4().hex[:8]}"
        fallback_copy.narrative_hook = (
            f"{fallback_copy.narrative_hook} The layout shifts for a {player_class}."
        )
        if player_class == "mage":
            fallback_copy.items = [
                *fallback_copy.items,
                ItemSpec(id="i_mage", type="health_potion", position=[5, 5]),
            ]
        elif player_class == "ranger":
            fallback_copy.grid[4][2] = 1
            fallback_copy.grid[6][4] = 1
        elif player_class == "warrior":
            for enemy in fallback_copy.enemies:
                enemy.behavior = "rush_melee"
        return fallback_copy

    async def run(self, context: dict) -> LevelSchema:
        floor_number = context.get("floor_number", 1)
        difficulty_level = context.get("difficulty_level", 1)
        theme = context.get("theme", "enchanted_forest")
        player_class = context.get("player_class", "warrior")

        # Step 8: Check Redis cache
        level_hash = self._get_level_hash(context)
        cache_key = f"level:{level_hash}"
        try:
            if redis_client:
                cached = await redis_client.get(cache_key)
                if cached:
                    level_obj, _ = self._safe_parse_json(cached, LevelSchema)
                    if level_obj:
                        self.log_trace(
                            reasoning=f"Found cached level for Floor {floor_number}, difficulty {difficulty_level}, theme {theme}",
                            tool_called="check_cache",
                            tool_input={"cache_key": cache_key},
                            tool_output={"cache_hit": True},
                            decision="Using cached level layout",
                        )
                        # ensure the floor number and an unique level id is set for this session instance
                        level_obj.floor_number = floor_number
                        level_obj.level_id = str(uuid.uuid4())
                        return level_obj
        except Exception:
            pass  # ignore redis errors

        # Step 1: Analyze parameters (log trace)
        self.log_trace(
            reasoning=f"Floor {floor_number}, difficulty {difficulty_level}, theme {theme}",
            tool_called="analyze_parameters",
            tool_input=context,
            tool_output={
                "grid_size": self._get_grid_size(difficulty_level),
                "enemy_count": self._get_enemy_count(difficulty_level),
            },
            decision="Generating new level",
        )

        # Step 2: Build user prompt
        user_prompt = self._build_user_prompt(context)
        generation_config = genai.GenerationConfig(
            temperature=0.7,
            top_p=0.95,
            max_output_tokens=2000,
            response_mime_type="application/json",
            response_schema=LevelSchema.model_json_schema(),
        )

        level_obj = None
        validation_error = None

        try:
            # Step 3 & 4: Call Gemini and parse
            response_text, tokens, duration = await self._call_gemini(
                user_prompt, generation_config
            )
            level_obj, validation_error = self._safe_parse_json(
                response_text, LevelSchema
            )

            # Step 5: If validation fails (or pathfinding fails) -> retry once
            if validation_error or (
                level_obj and not validate_level_playable(level_obj)
            ):
                if not validation_error:
                    validation_error = "validate_level_playable failed: No valid path from player_start to exit_position."

                rows, cols = self._get_grid_size(difficulty_level)
                expected_enemy_count = self._get_enemy_count(difficulty_level)
                retry_suffix = f"\n\nVALIDATION FAILED: {validation_error}\n\nCommon fixes:\n- Make sure all border tiles are 0 (first/last row, first/last col)\n- Make sure grid_rows={rows} and grid_cols={cols} match actual array size\n- Make sure enemy positions [row, col] are within grid bounds and on floor tiles (1)\n- Make sure player_start and exit_position are on floor tiles\n- Check that enemy_count = {expected_enemy_count} matches len(enemies)\n\nOutput the corrected JSON now. Only the JSON. No explanation."

                response_text, tokens2, duration2 = await self._call_gemini(
                    user_prompt + retry_suffix, generation_config
                )
                tokens += tokens2
                duration += duration2
                level_obj, validation_error = self._safe_parse_json(
                    response_text, LevelSchema
                )

                # Step 7: Validate path exists
                if validation_error or (
                    level_obj and not validate_level_playable(level_obj)
                ):
                    raise AgentValidationError("Retry failed validation.")

            # Step 9: Log final trace
            self.log_trace(
                reasoning=f"Generating {level_obj.grid_rows}x{level_obj.grid_cols} grid",
                tool_called="generate_grid",
                tool_input={},
                tool_output={"grid_generated": True},
                decision="Grid generated and validated",
                duration_ms=duration,
                tokens_used=tokens,
            )

        except Exception as e:
            # Step 6: If retry fails -> return FALLBACK_LEVEL
            level_obj = self._get_fallback_level(theme, floor_number, player_class)
            self.log_trace(
                reasoning=f"AI generation failed ({str(e)}). Using fallback.",
                tool_called="use_fallback",
                tool_input={"theme": theme, "floor": floor_number},
                tool_output={"level_id": level_obj.level_id},
                decision="Used fallback level",
                fallback_used=True,
            )
            return level_obj

        # Step 8: Cache to Redis with TTL=86400
        level_obj.level_id = str(uuid.uuid4())
        try:
            if redis_client:
                await redis_client.setex(cache_key, 86400, level_obj.model_dump_json())
        except Exception:
            pass

        # Step 10: Return validated LevelSchema
        return level_obj
