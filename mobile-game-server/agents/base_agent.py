import time
from datetime import datetime, timezone
from abc import ABC, abstractmethod
from typing import Any
import json
from pydantic import ValidationError

import google.generativeai as genai

from models.game_schemas import TraceEntry
from exceptions import GeminiCallError


class BaseAgent(ABC):
    """
    Base class for all DungeonMind AI agents.
    Provides tracing, Gemini client, and error handling.
    """

    model_name: str = "gemini-2.5-flash"
    agent_version: str = "1.0.0"

    def __init__(self, session_id: str, floor_number: int = 1, turn_number: int = 0):
        self.session_id = session_id
        self.floor_number = floor_number
        self.turn_number = turn_number
        self._traces: list[TraceEntry] = []
        self._step_counter = 0

        # Initialize Gemini client
        self._model = genai.GenerativeModel(
            model_name=self.model_name, system_instruction=self._get_system_prompt()
        )

    @property
    def agent_name(self) -> str:
        return self.__class__.__name__

    def _get_system_prompt(self) -> str:
        """Override in subclass to return the system prompt."""
        raise NotImplementedError

    @abstractmethod
    async def run(self, context: dict) -> dict:
        """Execute the agent's main logic. Returns result dict."""
        pass

    def log_trace(
        self,
        reasoning: str,
        tool_called: str,
        tool_input: dict,
        tool_output: dict,
        decision: str,
        duration_ms: int = 0,
        fallback_used: bool = False,
        tokens_used: int = 0,
    ) -> TraceEntry:
        """
        Log one reasoning step. Call this after every meaningful action.
        This is what judges evaluate — be descriptive!
        """
        self._step_counter += 1

        entry = TraceEntry(
            session_id=self.session_id,
            agent=self.agent_name,
            floor_number=self.floor_number,
            turn_number=self.turn_number,
            step=self._step_counter,
            timestamp=datetime.now(timezone.utc).isoformat(),
            reasoning=reasoning,
            tool_called=tool_called,
            tool_input=tool_input,
            tool_output=tool_output,
            decision=decision,
            duration_ms=duration_ms,
            model_used=self.model_name,
            tokens_used=tokens_used,
            fallback_used=fallback_used,
            agent_version=self.agent_version,
        )

        self._traces.append(entry)
        return entry

    def get_traces(self) -> list[TraceEntry]:
        """Return all trace entries from this agent run."""
        return self._traces.copy()

    async def _call_gemini(
        self,
        user_prompt: str,
        generation_config: genai.GenerationConfig,
    ) -> tuple[str, int, int]:
        """
        Call Gemini API with timing and token tracking.
        Returns (response_text, tokens_used, duration_ms).
        Raises GeminiCallError on failure.
        """
        import asyncio

        start = time.time()
        try:
            response = await asyncio.wait_for(
                self._model.generate_content_async(
                    user_prompt, generation_config=generation_config
                ),
                timeout=30.0,
            )
            duration_ms = int((time.time() - start) * 1000)
            tokens = (
                response.usage_metadata.total_token_count
                if hasattr(response, "usage_metadata") and response.usage_metadata
                else 0
            )
            return response.text, tokens, duration_ms
        except asyncio.TimeoutError:
            raise GeminiCallError("Gemini API call timed out after 30.0 seconds")
        except Exception as e:
            raise GeminiCallError(f"Gemini API call failed: {str(e)}")

    def _safe_parse_json(
        self, json_str: str, model_class: type
    ) -> tuple[Any, str | None]:
        """
        Parse and validate JSON. Returns (parsed_object, error_message).
        error_message is None if successful.
        """
        try:
            raw = json.loads(json_str)
            validated = model_class.model_validate(raw)
            return validated, None
        except json.JSONDecodeError as e:
            return None, f"JSON parse error: {e}"
        except ValidationError as e:
            return None, f"Schema validation error: {e.json()}"
