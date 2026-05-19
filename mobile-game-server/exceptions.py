class GeminiCallError(Exception):
    """Exception raised when a Gemini API call fails."""
    pass

class AgentValidationError(Exception):
    """Exception raised when an agent's output fails validation."""
    pass

class AgentTimeoutError(Exception):
    """Exception raised when an agent takes too long to respond."""
    pass
