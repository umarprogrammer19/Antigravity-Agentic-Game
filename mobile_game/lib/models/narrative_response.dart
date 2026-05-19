class NarrativeResponse {
  final String eventType;
  final String text;
  final int displayDuration;
  final bool aiUsed;
  final bool fallbackUsed;
  final bool cached;
  final int? processingTimeMs;

  NarrativeResponse({
    required this.eventType,
    required this.text,
    required this.displayDuration,
    required this.aiUsed,
    required this.fallbackUsed,
    required this.cached,
    this.processingTimeMs,
  });

  factory NarrativeResponse.fromJson(Map<String, dynamic> json) => NarrativeResponse(
        eventType: json['event_type'],
        text: json['text'],
        displayDuration: json['display_duration'],
        aiUsed: json['ai_used'] ?? true,
        fallbackUsed: json['fallback_used'] ?? false,
        cached: json['cached'] ?? false,
        processingTimeMs: json['processing_time_ms'],
      );
}
