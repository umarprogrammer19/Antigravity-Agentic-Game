import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/trace_entry.dart';

class FullTraceEntryCard extends StatefulWidget {
  final TraceEntry trace;

  const FullTraceEntryCard({
    super.key,
    required this.trace,
  });

  @override
  State<FullTraceEntryCard> createState() => _FullTraceEntryCardState();
}

class _FullTraceEntryCardState extends State<FullTraceEntryCard> {
  bool _expanded = false;

  Color get _agentColor => {
        'DungeonMasterAgent': DungeonColors.agentDM,
        'LevelGeneratorAgent': DungeonColors.agentLevel,
        'RivalAgent': DungeonColors.agentRival,
        'NarrativeAgent': DungeonColors.agentNarrative,
        'RefereeAgent': DungeonColors.agentReferee,
      }[widget.trace.agent] ??
      Colors.grey;

  String get _agentAbbrev => {
        'DungeonMasterAgent': 'DM',
        'LevelGeneratorAgent': 'LG',
        'RivalAgent': 'NPC',
        'NarrativeAgent': 'NAR',
        'RefereeAgent': 'REF',
      }[widget.trace.agent] ??
      '?';

  String _formatJson(Map<String, dynamic> data) {
    if (data.isEmpty) return '{}';
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  // Format date/time nicely
  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: DungeonSpacing.md),
        padding: const EdgeInsets.all(DungeonSpacing.md),
        decoration: BoxDecoration(
          color: DungeonColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DungeonColors.surfaceElevated),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _agentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DungeonSpacing.sm),
                Text(
                  "$_agentAbbrev | ${widget.trace.agent}",
                  style: DungeonText.headingMedium.copyWith(
                    fontSize: 14,
                    color: _agentColor,
                  ),
                ),
                const Spacer(),
                Text(
                  "Step ${widget.trace.step} · ${_formatTime(widget.trace.timestamp)}",
                  style: DungeonText.caption,
                ),
              ],
            ),
            const Divider(color: DungeonColors.surface),
            
            // Reasoning
            const SizedBox(height: DungeonSpacing.sm),
            const Text(
              "📋 REASONING",
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 12,
                color: DungeonColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DungeonSpacing.xs),
            Text(
              '"${widget.trace.reasoning}"',
              style: DungeonText.trace.copyWith(
                fontStyle: FontStyle.italic,
                color: DungeonColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: DungeonSpacing.md),
            
            // Tool Called
            Row(
              children: [
                const Text(
                  "🔧 TOOL: ",
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 12,
                    color: DungeonColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DungeonColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.trace.toolCalled,
                    style: DungeonText.caption.copyWith(color: DungeonColors.textPrimary),
                  ),
                ),
              ],
            ),
            
            // Expanded Content (Input / Output)
            if (_expanded) ...[
              const SizedBox(height: DungeonSpacing.sm),
              _buildJsonBox("INPUT:", widget.trace.toolInput),
              const SizedBox(height: DungeonSpacing.sm),
              _buildJsonBox("OUTPUT:", widget.trace.toolOutput),
            ],

            const SizedBox(height: DungeonSpacing.md),
            
            // Decision
            const Text(
              "✓ DECISION",
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 12,
                color: DungeonColors.goldDim,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DungeonSpacing.xs),
            Text(
              widget.trace.decision,
              style: DungeonText.bodyMedium.copyWith(
                color: DungeonColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: DungeonSpacing.md),
            
            // Footer (Model, Tokens, Duration)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.trace.fallbackUsed)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: DungeonColors.crimson.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: DungeonColors.crimson),
                    ),
                    child: Text(
                      "FALLBACK",
                      style: DungeonText.caption.copyWith(color: DungeonColors.crimsonLight),
                    ),
                  ),
                Text(
                  "${widget.trace.modelUsed} · ${widget.trace.tokensUsed} tokens · ${widget.trace.durationMs}ms",
                  style: DungeonText.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonBox(String label, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DungeonText.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: DungeonSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DungeonSpacing.sm),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F16), // Darker code box
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: DungeonColors.surface),
          ),
          child: Text(
            _formatJson(data),
            style: DungeonText.caption.copyWith(
              color: DungeonColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
