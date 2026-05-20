import hashlib
import json
import google.generativeai as genai

from agents.base_agent import BaseAgent
from models.game_schemas import NarrativeResponse
from config import redis_client
from utils.schema_converter import convert_pydantic_schema_for_gemini

NARRATIVE_FALLBACKS = {
    "session_start": {
        "cursed_library": "The library doors seal behind you. Silence — then a whisper.",
        "volcanic_caves": "Heat floods the entrance. The caves breathe like a living thing.",
        "enchanted_forest": "The trees close in. Something ancient watches you enter.",
    },
    "floor_cleared": {
        "cursed_library": "The shadows retreat. Floor {n} waits, darker than before.",
        "volcanic_caves": "The heat intensifies ahead. Keep moving.",
        "enchanted_forest": "The forest shifts. New paths form where walls once stood.",
    },
    "player_death": "The dungeon claims another. Your story ends here — for now.",
    "item_found_health_potion": "Warmth spreads through your veins. A brief mercy.",
    "item_found_damage_boost": "Power surges through you. Use it well.",
    "item_found_shield": "The air hardens around you. Temporary. But real.",
}


class NarrativeAgent(BaseAgent):
    model_name = "gemini-2.5-flash"

    def _get_system_prompt(self) -> str:
        return """You are the storyteller for DungeonMind, a dark fantasy dungeon crawler.

YOUR ROLE:
Generate SHORT, atmospheric story text for key game events.
Every line you write appears on the player's screen during gameplay.

YOUR WRITING RULES:
- Maximum 200 characters total (strictly enforced)
- 1-2 sentences only. Never more.
- Second person perspective: "You...", "Your...", "The dungeon..."
- Present tense always
- Dark fantasy tone: gritty, atmospheric, never cheesy
- No exclamation marks. No "Congratulations". No "Well done".
- Reference the theme and player class when relevant
- Make it feel personal and earned, not generic

THEME ATMOSPHERES:
- cursed_library: Ancient knowledge, forbidden books, whispering shadows, ink and dust
- volcanic_caves: Heat, pressure, ancient fire, molten stone, survival
- enchanted_forest: Twisted nature, feral magic, watching eyes, dark beauty

CLASS REFERENCES (optional, use naturally):
- warrior: "your blade", "your shield", "battle-hardened hands"
- mage: "your spell", "the arcane currents", "your focus"
- ranger: "your arrow", "hunter's instinct", "swift feet" """

    async def run(self, context: dict) -> NarrativeResponse:
        event_type = context.get("event_type", "session_start")
        player_class = context.get("player_class", "warrior")
        floor_number = context.get("floor_number", 1)
        theme = context.get("theme", "enchanted_forest")
        event_context = context.get("context", {})

        # Cache check
        hash_str = f"{event_type}-{theme}-{floor_number}"
        hash_val = hashlib.md5(hash_str.encode()).hexdigest()[:12]
        cache_key = f"narr:{hash_val}"

        try:
            if redis_client:
                cached = await redis_client.get(cache_key)
                if cached:
                    resp, _ = self._safe_parse_json(cached, NarrativeResponse)
                    if resp:
                        self.log_trace(
                            "Cache hit",
                            "check_cache",
                            {"key": cache_key},
                            {"hit": True},
                            "Using cached narrative",
                        )
                        return resp
        except Exception:
            pass

        user_prompt = f"""Write narrative text for this game event.

EVENT: {event_type}
PLAYER CLASS: {player_class}
FLOOR: {floor_number}
THEME: {theme}

EVENT CONTEXT:
{json.dumps(event_context, indent=2)}

Write the narrative text now. Remember: max 200 chars, dark fantasy tone, no exclamation marks.
Make it specific to the {theme} theme and the {player_class} class if relevant."""

        # Convert Pydantic schema to Gemini-compatible format
        pydantic_schema = NarrativeResponse.model_json_schema()
        gemini_schema = convert_pydantic_schema_for_gemini(pydantic_schema)

        generation_config = genai.GenerationConfig(
            temperature=0.8,
            top_p=0.95,
            max_output_tokens=300,
            response_mime_type="application/json",
            response_schema=gemini_schema,
        )

        try:
            self.log_trace(
                reasoning=f"Generating narrative for {event_type} in {theme}",
                tool_called="generate_narrative",
                tool_input={"event": event_type, "theme": theme},
                tool_output={},
                decision="Calling Gemini for story text",
            )

            response_text, tokens, duration = await self._call_gemini(
                user_prompt, generation_config
            )
            narrative, err = self._safe_parse_json(response_text, NarrativeResponse)
            if err:
                raise Exception(err)
        except Exception as e:
            text = "The shadows shift around you."
            if event_type in NARRATIVE_FALLBACKS:
                if isinstance(NARRATIVE_FALLBACKS[event_type], dict):
                    text = NARRATIVE_FALLBACKS[event_type].get(theme, text)
                    if "{n}" in text:
                        text = text.replace("{n}", str(floor_number + 1))
                else:
                    text = NARRATIVE_FALLBACKS[event_type]
            narrative = NarrativeResponse(
                event_type=event_type, text=text, display_duration=2000
            )

        try:
            if redis_client:
                await redis_client.setex(cache_key, 3600, narrative.model_dump_json())
        except Exception:
            pass

        return narrative
