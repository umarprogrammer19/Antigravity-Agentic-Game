import hashlib
import uuid
import google.generativeai as genai

from agents.base_agent import BaseAgent
from models.game_schemas import ItemSpec, LevelSchema, validate_level_playable
from exceptions import AgentValidationError
from fallbacks.fallback_levels import FALLBACK_LEVELS
from config import redis_client
from utils.schema_converter import convert_pydantic_schema_for_gemini


class LevelGeneratorAgent(BaseAgent):
    model_name = "gemini-3.1-flash-lite"

    def _get_system_prompt(self) -> str:
        return """You are the Dungeon Architect for DungeonMind, a roguelike dungeon crawler.

YOUR ROLE:
Generate complete dungeon level layouts as structured JSON.
Every level you create must be playable, balanced, and thematically consistent.

YOUR CONSTRAINTS — FOLLOW THESE EXACTLY:

GRID RULES (CRITICAL):
- Grid is a 2D array of integers. Row 0 is the top. Col 0 is the left.
- Tile values: 0=wall, 1=floor, 2=unused, 3=lava(volcanic only), 4=trap, 5=item
- ALL border tiles (row 0, last row, col 0, last col) MUST be walls (0)
- **CRITICAL**: There MUST be a continuous walkable path of floor tiles (1) from player_start to exit_position
- SIMPLE LAYOUTS WORK BEST: Use large open rooms connected by corridors. Avoid complex mazes.
- player_start: always in top-left quadrant (rows 1-4, cols 1-4) on a floor tile (1)
- exit_position: always in bottom-right quadrant (last 4 rows, last 4 cols) on a floor tile (1)

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
- **CRITICAL**: Item type MUST be one of: "health_potion", "damage_boost", "shield" ONLY
- DO NOT use: mana_potion, speed_boost, or any other types

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
✓ ALL item types are ONLY: "health_potion", "damage_boost", or "shield"
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
    model_name = "gemini-3.1-flash-lite"

    def _get_system_prompt(self) -> str:
        return """
            You are the Dungeon Architect for DungeonMind, a roguelike dungeon crawler.
            
            YOUR ROLE:
            Generate complete dungeon level layouts as structured JSON.
            Every level you create must be playable, balanced, and thematically consistent.

            YOUR CONSTRAINTS — FOLLOW THESE EXACTLY:

            GRID RULES (CRITICAL):
            - Grid is a 2D array of integers. Row 0 is the top. Col 0 is the left.
            - Tile values: 0=wall, 1=floor, 2=unused, 3=lava(volcanic only), 4=trap, 5=item
            - ALL border tiles (row 0, last row, col 0, last col) MUST be walls (0)
            - **CRITICAL**: There MUST be a continuous walkable path of floor tiles (1) from player_start to exit_position
            - SIMPLE LAYOUTS WORK BEST: Use large open rooms connected by corridors. Avoid complex mazes.
            - player_start: always in top-left quadrant (rows 1-4, cols 1-4) on a floor tile (1)
            - exit_position: always in bottom-right quadrant (last 4 rows, last 4 cols) on a floor tile (1)

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
            ✓ enemy_count matches len(enemies)
        """

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

REQUIRED JSON OUTPUT STRUCTURE:
(IMPORTANT: Item types MUST be "health_potion", "damage_boost", or "shield" ONLY!)
{{
  "level_id": "unique_id",
  "floor_number": {floor_number},
  "theme": "{theme}",
  "grid": [[0,0,0,...], [0,1,1,...], ...],
  "grid_rows": 10,
  "grid_cols": 10,
  "player_start": [1, 1],
  "exit_position": [8, 8],
  "enemies": [{{"id": "e1", "type": "goblin", "position": [4,4], "hp": 20, "max_hp": 20, "attack": 8, "defense": 3, "behavior": "rush_melee"}}],
  "items": [{{"id": "i1", "type": "health_potion", "position": [3,7]}}, {{"id": "i2", "type": "damage_boost", "position": [6,2]}}],
  "narrative_hook": "One sentence about {theme}",
  "player_analysis": "Analysis of player tactics",
  "difficulty_score": {difficulty_level}.0,
  "enemy_count": {enemy_count},
  "estimated_turns_to_clear": 15
}}

Generate the COMPLETE JSON with ALL FIELDS above.
Remember: ALL border tiles must be 0. Verify path exists from player_start to exit."""

    def _get_level_hash(self, context: dict) -> str:
        # Include session_id to ensure unique levels per session
        data = f"{context.get('session_id', 'default')}-{context.get('difficulty_level', 1)}-{context.get('theme', 'enchanted_forest')}-{context.get('player_class', 'warrior')}-{context.get('floor_number', 1)}"
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

        # CACHING DISABLED - Always generate fresh levels for unique gameplay
        # This ensures every session and every floor has a unique AI-generated layout

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

        # Use JSON mode WITHOUT schema validation
        # The old google-generativeai library can't handle complex schemas properly
        # Let Gemini generate free-form JSON, then validate with Pydantic
        generation_config = genai.GenerationConfig(
            temperature=0.4,
            top_p=0.9,
            max_output_tokens=4000,  # Increased to ensure full JSON (grid arrays are large)
            response_mime_type="application/json",
            # NO response_schema - it causes incomplete responses
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
            print(f"DEBUG: Gemini response:\n{response_text[:500]}")

            # Step 5: Check pathfinding
            path_valid = True
            path_error = ""
            if level_obj:
                path_valid, path_error = validate_level_playable(level_obj)

            # If validation fails (or pathfinding fails) -> retry once
            if validation_error or not path_valid:
                error_msg = validation_error or path_error
                from config import logger
                logger.warning(f"⚠️ Level validation failed: {error_msg}")

                rows, cols = self._get_grid_size(difficulty_level)
                expected_enemy_count = self._get_enemy_count(difficulty_level)
                retry_suffix = f"\n\nVALIDATION FAILED: {error_msg}\n\nCommon fixes:\n- Make sure all border tiles are 0 (first/last row, first/last col)\n- Make sure grid_rows={rows} and grid_cols={cols} match actual array size\n- Make sure enemy positions [row, col] are within grid bounds and on floor tiles (1)\n- Make sure player_start and exit_position are on floor tiles\n- Create a SIMPLE path of floor tiles (1) connecting player_start to exit_position\n- Check that enemy_count = {expected_enemy_count} matches len(enemies)\n\nOutput the corrected JSON now. Only the JSON. No explanation."

                response_text, tokens2, duration2 = await self._call_gemini(
                    user_prompt + retry_suffix, generation_config
                )
                tokens += tokens2
                duration += duration2
                level_obj, validation_error = self._safe_parse_json(
                    response_text, LevelSchema
                )

                # Step 7: Validate path exists again
                path_valid = True
                path_error = ""
                if level_obj:
                    path_valid, path_error = validate_level_playable(level_obj)

                if validation_error or not path_valid:
                    error_msg = validation_error or path_error
                    logger.error(f"❌ Retry also failed: {error_msg}")
                    raise AgentValidationError(f"Retry failed validation: {error_msg}")

            # Step 9: Log final trace
            from config import logger
            logger.info(f"✅ AI-Generated Level: Floor {floor_number}, Theme: {theme}, Size: {level_obj.grid_rows}x{level_obj.grid_cols}, Enemies: {len(level_obj.enemies)}, Items: {len(level_obj.items)}")

            self.log_trace(
                reasoning=f"✅ Successfully generated unique {level_obj.grid_rows}x{level_obj.grid_cols} dungeon for {theme} theme",
                tool_called="generate_grid",
                tool_input={"difficulty": difficulty_level, "theme": theme, "floor": floor_number},
                tool_output={"grid_generated": True, "enemies": len(level_obj.enemies), "items": len(level_obj.items)},
                decision=f"✅ AI-Generated Floor {floor_number} ready with {len(level_obj.enemies)} enemies",
                duration_ms=duration,
                tokens_used=tokens,
            )

        except Exception as e:
            # Step 6: If retry fails -> return FALLBACK_LEVEL
            import traceback
            error_details = traceback.format_exc()
            from config import logger
            logger.error(f"❌ LevelGenerator FAILED for floor {floor_number}, theme {theme}: {str(e)}\n{error_details}")

            level_obj = self._get_fallback_level(theme, floor_number, player_class)
            self.log_trace(
                reasoning=f"⚠️ AI GENERATION FAILED: {str(e)}. Using static fallback level - THIS SHOULD NOT HAPPEN IN PRODUCTION!",
                tool_called="use_fallback",
                tool_input={"theme": theme, "floor": floor_number, "error": str(e)},
                tool_output={"level_id": level_obj.level_id, "fallback_used": True},
                decision="❌ FALLBACK LEVEL USED - AI generation failed",
                fallback_used=True,
            )
            return level_obj

        # Ensure unique level ID
        level_obj.level_id = str(uuid.uuid4())
        level_obj.floor_number = floor_number

        # Return validated AI-generated LevelSchema
        return level_obj
