"""
Test script to verify AI level generation is working.
Run this to ensure Gemini API is properly configured and generating unique levels.
"""
import asyncio
import sys
from agents.level_generator import LevelGeneratorAgent

async def test_level_generation():
    print("=" * 60)
    print("Testing AI Level Generation")
    print("=" * 60)

    test_cases = [
        {"theme": "enchanted_forest", "class": "warrior", "difficulty": 3},
        {"theme": "volcanic_caves", "class": "mage", "difficulty": 5},
        {"theme": "cursed_library", "class": "ranger", "difficulty": 7},
    ]

    for i, test in enumerate(test_cases, 1):
        print(f"\n[TEST] Test {i}: Generating {test['theme']} for {test['class']} (Difficulty: {test['difficulty']})")
        print("-" * 60)

        try:
            agent = LevelGeneratorAgent(
                session_id=f"test_session_{i}",
                floor_number=i
            )

            level = await agent.run({
                "session_id": f"test_session_{i}",
                "floor_number": i,
                "difficulty_level": test["difficulty"],
                "theme": test["theme"],
                "player_class": test["class"],
                "enemy_speed_multiplier": 1.0,
                "item_drop_rate": 1.0,
                "player_current_hp": 100,
                "player_move_history": []
            })

            print(f"[SUCCESS] SUCCESS!")
            print(f"   Level ID: {level.level_id}")
            print(f"   Grid Size: {level.grid_rows}x{level.grid_cols}")
            print(f"   Enemies: {len(level.enemies)}")
            print(f"   Items: {len(level.items)}")
            print(f"   Theme: {level.theme}")
            print(f"   Narrative: {level.narrative_hook}")

            # Check if it's a fallback
            if "fallback" in level.level_id.lower():
                print(f"   [WARNING]  WARNING: Using fallback level! AI generation may have failed.")

            # Show traces
            traces = agent.get_traces()
            print(f"   Traces: {len(traces)} decisions logged")
            for trace in traces:
                if trace.fallback_used:
                    print(f"   [FAILED] Fallback used: {trace.decision}")

        except Exception as e:
            print(f"[FAILED] FAILED: {str(e)}")
            import traceback
            traceback.print_exc()

    print("\n" + "=" * 60)
    print("Test Complete!")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(test_level_generation())
