class TraceEntry {
  final String? traceId;
  final String sessionId;
  final String agent;
  final int floorNumber;
  final int turnNumber;
  final int step;
  final String timestamp;
  final String reasoning;
  final String toolCalled;
  final Map<String, dynamic> toolInput;
  final Map<String, dynamic> toolOutput;
  final String decision;
  final int durationMs;
  final String modelUsed;
  final bool fallbackUsed;
  final int tokensUsed;

  TraceEntry({
    this.traceId,
    required this.sessionId,
    required this.agent,
    required this.floorNumber,
    required this.turnNumber,
    required this.step,
    required this.timestamp,
    required this.reasoning,
    required this.toolCalled,
    required this.toolInput,
    required this.toolOutput,
    required this.decision,
    required this.durationMs,
    required this.modelUsed,
    required this.fallbackUsed,
    required this.tokensUsed,
  });

  factory TraceEntry.fromJson(Map<String, dynamic> json) => TraceEntry(
        traceId: json['trace_id'],
        sessionId: json['session_id'],
        agent: json['agent'],
        floorNumber: json['floor_number'],
        turnNumber: json['turn_number'] ?? 0,
        step: json['step'],
        timestamp: json['timestamp'],
        reasoning: json['reasoning'],
        toolCalled: json['tool_called'],
        toolInput: json['tool_input'] ?? {},
        toolOutput: json['tool_output'] ?? {},
        decision: json['decision'],
        durationMs: json['duration_ms'] ?? 0,
        modelUsed: json['model_used'],
        fallbackUsed: json['fallback_used'] ?? false,
        tokensUsed: json['tokens_used'] ?? 0,
      );
}
