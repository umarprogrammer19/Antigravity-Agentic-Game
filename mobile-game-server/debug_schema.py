"""Debug script to test schema conversion"""
import json
from models.game_schemas import LevelSchema
from utils.schema_converter import convert_pydantic_schema_for_gemini

# Get Pydantic schema
print("=" * 60)
print("Original Pydantic Schema:")
print("=" * 60)
original = LevelSchema.model_json_schema()
print(json.dumps(original, indent=2)[:1000])  # First 1000 chars

print("\n" + "=" * 60)
print("Converted Gemini Schema:")
print("=" * 60)
converted = convert_pydantic_schema_for_gemini(original)
print(json.dumps(converted, indent=2)[:1000])  # First 1000 chars

print("\n" + "=" * 60)
print("Schema Differences:")
print("=" * 60)
print(f"Original keys: {list(original.keys())}")
print(f"Converted keys: {list(converted.keys())}")

# Try to use it with Gemini
print("\n" + "=" * 60)
print("Testing with Gemini API:")
print("=" * 60)

try:
    import google.generativeai as genai
    from config import gemini

    if gemini:
        print("[OK] Gemini initialized")

        # Try to create a generation config
        config = genai.GenerationConfig(
            temperature=0.7,
            response_mime_type="application/json",
            response_schema=converted
        )
        print("[OK] GenerationConfig created successfully!")
        print(f"Config: {config}")
    else:
        print("[ERROR] Gemini not initialized")

except Exception as e:
    print(f"[ERROR] {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 60)
print("Debug Complete")
print("=" * 60)
