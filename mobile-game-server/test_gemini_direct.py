"""Direct test of Gemini API for level generation"""
import asyncio
import json
import google.generativeai as genai
from models.game_schemas import LevelSchema
from utils.schema_converter import convert_pydantic_schema_for_gemini

async def test_gemini_direct():
    print("=" * 60)
    print("Direct Gemini API Test")
    print("=" * 60)

    # Configure Gemini
    try:
        from config import gemini, settings
        if not gemini:
            print("[ERROR] Gemini not initialized!")
            return

        print(f"[OK] Gemini initialized with API key: {settings.GEMINI_API_KEY[:20]}...")

        # Create model
        model = genai.GenerativeModel(
            model_name="gemini-2.5-flash",
            system_instruction="You are a level generator for a dungeon crawler game. Generate JSON layouts."
        )
        print("[OK] Model created")

        # Prepare schema
        original_schema = LevelSchema.model_json_schema()
        gemini_schema = convert_pydantic_schema_for_gemini(original_schema)
        print("[OK] Schema converted")

        # Create generation config
        config = genai.GenerationConfig(
            temperature=0.7,
            response_mime_type="application/json",
            response_schema=gemini_schema
        )
        print("[OK] GenerationConfig created")

        # Simple prompt
        prompt = """Generate a simple 10x10 dungeon level for floor 1, enchanted_forest theme, warrior class.

Requirements:
- 10x10 grid (0=wall, 1=floor, 2=exit, 3=lava)
- player_start at [1,1]
- exit_position at [8,8]
- 2 enemies (goblins)
- 1 health potion
- narrative_hook: one sentence about the forest

Make it playable!"""

        print("\n[TEST] Calling Gemini API...")
        print(f"Prompt: {prompt[:100]}...")

        response = await model.generate_content_async(prompt, generation_config=config)

        print("\n[SUCCESS] Got response!")
        print(f"Response text length: {len(response.text)} characters")
        print(f"First 500 chars:\n{response.text[:500]}")

        # Try to parse
        try:
            data = json.loads(response.text)
            level = LevelSchema.model_validate(data)
            print(f"\n[SUCCESS] Valid LevelSchema!")
            print(f"  Level ID: {level.level_id}")
            print(f"  Grid Size: {level.grid_rows}x{level.grid_cols}")
            print(f"  Enemies: {len(level.enemies)}")
            print(f"  Theme: {level.theme}")
        except Exception as e:
            print(f"\n[ERROR] Failed to parse response: {e}")

    except Exception as e:
        print(f"\n[ERROR] {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()

    print("\n" + "=" * 60)
    print("Test Complete")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(test_gemini_direct())
