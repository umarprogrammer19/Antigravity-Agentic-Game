import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../models/trace_entry.dart';
import '../../../../providers/game_state_provider.dart';
import '../../../../providers/session_provider.dart';
import '../../../../services/agent_service.dart';

class AiDecisionPanel extends ConsumerStatefulWidget {
  const AiDecisionPanel({super.key});

  @override
  ConsumerState<AiDecisionPanel> createState() => _AiDecisionPanelState();
}

class _AiDecisionPanelState extends ConsumerState<AiDecisionPanel> {
  double _currentSize = 0.10;
  String? _selectedFilter;
  ScrollController? _innerScrollController;

  int _dotCount = 1;
  Timer? _timer;
  Timer? _pollTimer;
  final AgentService _agentService = AgentService();

  @override
  void initState() {
    super.initState();
    // Animate thinking dots
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) setState(() => _dotCount = (_dotCount % 3) + 1);
    });
    
    // Poll traces every 3 seconds (faster than 5 for responsiveness)
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollTraces());
    
    // Poll immediately on start
    Future.delayed(const Duration(seconds: 2), _pollTraces);
  }

  Future<void> _pollTraces() async {
    final session = ref.read(sessionProvider);
    final sessionId = session.plan?.sessionId;
    if (sessionId == null) return;

    try {
      final traces = await _agentService.getTraces(sessionId: sessionId);
      final gameState = ref.read(gameStateProvider);
      if (traces.length > gameState.sessionTraces.length) {
        final gameStateNotifier = ref.read(gameStateProvider.notifier);
        // Replace all traces to ensure we have the latest
        // This relies on the provider having a way to set all traces or just updating them
        // For simplicity, we just add missing ones or overwrite if a method existed
        // Since we don't have setTraces, we'll iterate and add new ones
        for (int i = gameState.sessionTraces.length; i < traces.length; i++) {
          gameStateNotifier.addTrace(traces[i]);
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_innerScrollController != null && _innerScrollController!.hasClients) {
      _innerScrollController!.animateTo(
        _innerScrollController!.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Color _getAgentColor(String agent) {
    switch (agent) {
      case 'DungeonMasterAgent':
        return DungeonColors.agentDM;
      case 'LevelGeneratorAgent':
        return DungeonColors.agentLevel;
      case 'RivalAgent':
        return DungeonColors.agentRival;
      case 'NarrativeAgent':
        return DungeonColors.agentNarrative;
      case 'RefereeAgent':
        return DungeonColors.agentReferee;
      default:
        return Colors.grey;
    }
  }

  String _getAgentAbbrev(String agent) {
    switch (agent) {
      case 'DungeonMasterAgent':
        return 'DM';
      case 'LevelGeneratorAgent':
        return 'LG';
      case 'RivalAgent':
        return 'NPC';
      case 'NarrativeAgent':
        return 'NAR';
      case 'RefereeAgent':
        return 'REF';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final isThinking = gameState.aiIsThinking;
    final lastTrace = gameState.sessionTraces.isNotEmpty
        ? gameState.sessionTraces.last
        : null;

    // Listen for new traces to auto-scroll
    ref.listen(gameStateProvider.select((s) => s.sessionTraces.length), (
      prev,
      next,
    ) {
      if (next > (prev ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    // Immediately update when game state AI status changes to false (meaning processing done)
    ref.listen(gameStateProvider.select((s) => s.aiIsThinking), (prev, next) {
      if (prev == true && next == false) {
        _pollTraces();
      }
    });

    final bool isExpanded = _currentSize > 0.15;
    final backgroundColor = isThinking
        ? DungeonColors.surfaceElevated.withValues(alpha: 0.98)
        : DungeonColors.surfaceElevated.withValues(alpha: 0.90);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() {
          _currentSize = notification.extent;
        });
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.10,
        minChildSize: 0.10,
        maxChildSize: 0.60,
        builder: (context, scrollController) {
          _innerScrollController = scrollController;

          return Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(top: DungeonRadius.lg),
              border: const Border(
                top: BorderSide(color: DungeonColors.goldDim, width: 2),
              ),
            ),
            child: isExpanded
                ? _buildExpandedContent(gameState.sessionTraces)
                : _buildCollapsedContent(isThinking, lastTrace),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedContent(bool isThinking, TraceEntry? lastTrace) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: isThinking
                    ? Row(children: [
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(DungeonColors.gold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI THINKING${'..' * _dotCount}',
                          style: DungeonText.bodyMedium.copyWith(color: DungeonColors.gold),
                        ),
                      ])
                    : lastTrace != null
                        ? Text(
                            '${_getAgentAbbrev(lastTrace.agent)}: ${lastTrace.decision}',
                            style: DungeonText.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            'Waiting for AI session to start...',
                            style: DungeonText.caption.copyWith(color: DungeonColors.textDim),
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(List<TraceEntry> allTraces) {
    final filteredTraces = _selectedFilter == null
        ? allTraces
        : allTraces
              .where((t) => _getAgentAbbrev(t.agent) == _selectedFilter)
              .toList();

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '🧠 AI DECISION LOG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DungeonColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filteredTraces.length}',
                      style: DungeonText.caption,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: ['DM', 'LG', 'NPC', 'NAR', 'REF'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = selected ? filter : null;
                    });
                  },
                  selectedColor: DungeonColors.gold.withValues(alpha: 0.2),
                  backgroundColor: DungeonColors.surface,
                  labelStyle: DungeonText.caption.copyWith(
                    color: isSelected
                        ? DungeonColors.gold
                        : DungeonColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _pollTraces();
            },
            child: ListView.builder(
              controller: _innerScrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredTraces.length,
              itemBuilder: (context, index) {
                final trace = filteredTraces[index];
                return TraceEntryCard(
                  trace: trace,
                  agentColor: _getAgentColor(trace.agent),
                  agentAbbrev: _getAgentAbbrev(trace.agent),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class TraceEntryCard extends StatefulWidget {
  final TraceEntry trace;
  final Color agentColor;
  final String agentAbbrev;

  const TraceEntryCard({
    super.key,
    required this.trace,
    required this.agentColor,
    required this.agentAbbrev,
  });

  @override
  State<TraceEntryCard> createState() => _TraceEntryCardState();
}

class _TraceEntryCardState extends State<TraceEntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: DungeonColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: widget.agentColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: widget.agentColor),
                  const SizedBox(width: 8),
                  Text(
                    widget.agentAbbrev,
                    style: TextStyle(
                      color: widget.agentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(widget.trace.agent, style: DungeonText.caption),
                  const Spacer(),
                  Text(
                    'Step ${widget.trace.step} · ${widget.trace.timestamp.substring(11, 19)}',
                    style: DungeonText.caption.copyWith(
                      color: DungeonColors.textDim,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Reasoning
              Text(
                '"${widget.trace.reasoning}"',
                style: DungeonText.bodyMedium.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                maxLines: _expanded ? null : 2,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Decision
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.check, size: 16, color: DungeonColors.gold),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.trace.decision,
                      style: DungeonText.bodyMedium.copyWith(
                        color: DungeonColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.trace.durationMs}ms',
                    style: DungeonText.caption,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(color: DungeonColors.surfaceElevated),
                const SizedBox(height: 8),
                _buildCodeRow('TOOL:', widget.trace.toolCalled),
                _buildCodeRow('INPUT:', _formatJson(widget.trace.toolInput)),
                _buildCodeRow('OUTPUT:', _formatJson(widget.trace.toolOutput)),
                _buildCodeRow('MODEL:', widget.trace.modelUsed),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatJson(Map<String, dynamic> data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  Widget _buildCodeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DungeonText.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: DungeonText.trace.copyWith(color: Colors.grey[300]),
            ),
          ),
        ],
      ),
    );
  }
}
