import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../models/trace_entry.dart';
import '../../services/agent_service.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/error_card.dart';
import 'widgets/full_trace_entry_card.dart';

class TraceViewerScreen extends StatefulWidget {
  final String sessionId;

  const TraceViewerScreen({super.key, required this.sessionId});

  @override
  State<TraceViewerScreen> createState() => _TraceViewerScreenState();
}

class _TraceViewerScreenState extends State<TraceViewerScreen> {
  final AgentService _agentService = AgentService();

  bool _isLoading = true;
  bool _hasError = false;
  List<TraceEntry> _allTraces = [];

  // Filter state
  final Map<String, String> _agentFilterMap = const {
    'DM': 'DungeonMasterAgent',
    'LG': 'LevelGeneratorAgent',
    'NPC': 'RivalAgent',
    'NAR': 'NarrativeAgent',
    'REF': 'RefereeAgent',
  };
  Set<String> _selectedFilterAbbrevs = {};

  @override
  void initState() {
    super.initState();
    _selectedFilterAbbrevs = _agentFilterMap.keys.toSet();
    _loadTraces();
  }

  Future<void> _loadTraces() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final traces = await _agentService.getTraces(sessionId: widget.sessionId);
      traces.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (mounted) {
        setState(() {
          _allTraces = traces;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  List<TraceEntry> get _filteredTraces {
    final selectedAgents = _selectedFilterAbbrevs
        .map((a) => _agentFilterMap[a]!)
        .toSet();
    return _allTraces.where((t) => selectedAgents.contains(t.agent)).toList();
  }

  void _exportTraces() {
    if (_allTraces.isEmpty) return;

    final sb = StringBuffer();
    sb.writeln("DungeonMind AI Session Report");
    sb.writeln("Session: ${widget.sessionId}");
    sb.writeln("Total AI Decisions: ${_allTraces.length}");
    sb.writeln();

    for (final trace in _allTraces) {
      final abbrev = _agentFilterMap.entries
          .firstWhere(
            (e) => e.value == trace.agent,
            orElse: () => const MapEntry('?', '?'),
          )
          .key;
      final cleanAgentName = trace.agent.replaceAll('Agent', '');

      sb.writeln(
        "[$abbrev] ${cleanAgentName.toUpperCase()} — Step ${trace.step}",
      );
      sb.writeln("Reasoning: ${trace.reasoning}");
      sb.writeln("Decision: ${trace.decision}");
      sb.writeln();
    }

    Share.share(sb.toString(), subject: 'DungeonMind AI Session Report');
  }

  Color _getAgentColor(String abbrev) {
    switch (abbrev) {
      case 'DM':
        return DungeonColors.agentDM;
      case 'LG':
        return DungeonColors.agentLevel;
      case 'NPC':
        return DungeonColors.agentRival;
      case 'NAR':
        return DungeonColors.agentNarrative;
      case 'REF':
        return DungeonColors.agentReferee;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DungeonColors.background,
      appBar: AppBar(
        backgroundColor: DungeonColors.background,
        elevation: 0,
        title: Text("AI DECISION LOG", style: DungeonText.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DungeonColors.textPrimary),
          tooltip: "Back",
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: DungeonColors.textSecondary),
            tooltip: "Refresh traces",
            onPressed: _loadTraces,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _allTraces.isNotEmpty ? _buildSummaryCard() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: DungeonColors.gold),
            const SizedBox(height: DungeonSpacing.md),
            Text(
              "Loading AI traces…",
              style: DungeonText.caption.copyWith(color: DungeonColors.textDim),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DungeonSpacing.lg),
          child: ErrorCard(
            message:
                "Failed to load AI traces. Check your internet connection.",
            onRetry: _loadTraces,
          ),
        ),
      );
    }

    if (_allTraces.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.history,
        title: "No AI decisions recorded",
        description: "Play a game to see how the AI made decisions.",
      );
    }

    final filtered = _filteredTraces;

    String formatTime(String iso) {
      try {
        final dt = DateTime.parse(iso).toLocal();
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
      } catch (_) {
        return "Unknown";
      }
    }

    final timeRange =
        "${formatTime(_allTraces.first.timestamp)} → ${formatTime(_allTraces.last.timestamp)}";
    final agentsUsed = _allTraces.map((t) => t.agent).toSet().length;

    // Build list with date group headers
    final List<Widget> listItems = [];
    String? currentGroupKey;

    for (final trace in filtered) {
      String groupKey = "Unknown Date";
      try {
        final dt = DateTime.parse(trace.timestamp).toLocal();
        groupKey =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:00";
      } catch (_) {}

      if (groupKey != currentGroupKey) {
        currentGroupKey = groupKey;
        listItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DungeonSpacing.sm),
            child: Text(
              currentGroupKey,
              style: DungeonText.headingMedium.copyWith(
                color: DungeonColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        );
      }
      listItems.add(FullTraceEntryCard(trace: trace));
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DungeonSpacing.md,
            vertical: DungeonSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Session · ${_allTraces.length} decisions · $agentsUsed agents",
                style: DungeonText.bodyMedium,
              ),
              const SizedBox(height: DungeonSpacing.xs),
              Text(timeRange, style: DungeonText.caption),
            ],
          ),
        ),

        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: DungeonSpacing.md,
            vertical: DungeonSpacing.sm,
          ),
          child: Row(
            children: [
              _buildFilterChip("ALL", isAll: true),
              const SizedBox(width: DungeonSpacing.sm),
              ..._agentFilterMap.keys.map((abbrev) {
                return Padding(
                  padding: const EdgeInsets.only(right: DungeonSpacing.sm),
                  child: _buildFilterChip(abbrev),
                );
              }),
            ],
          ),
        ),

        // Trace List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(DungeonSpacing.md),
            itemCount: listItems.length,
            itemBuilder: (context, index) {
              return listItems[index];
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String abbrev, {bool isAll = false}) {
    final bool isSelected = isAll
        ? _selectedFilterAbbrevs.length == _agentFilterMap.length
        : _selectedFilterAbbrevs.contains(abbrev);

    final color = isAll ? DungeonColors.gold : _getAgentColor(abbrev);

    return Semantics(
      label: isAll ? "Show all agents" : "Filter by $abbrev agent",
      child: FilterChip(
        label: Text(
          abbrev,
          style: TextStyle(
            color: isSelected ? Colors.white : DungeonColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: color.withValues(alpha: 0.3),
        checkmarkColor: color,
        backgroundColor: DungeonColors.surfaceElevated,
        side: BorderSide(color: isSelected ? color : DungeonColors.textDim),
        onSelected: (selected) {
          setState(() {
            if (isAll) {
              if (selected) {
                _selectedFilterAbbrevs = _agentFilterMap.keys.toSet();
              } else {
                _selectedFilterAbbrevs.clear();
              }
            } else {
              if (selected) {
                _selectedFilterAbbrevs.add(abbrev);
              } else {
                _selectedFilterAbbrevs.remove(abbrev);
              }
            }
          });
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    int totalTime = 0;
    int totalTokens = 0;
    final Map<String, int> agentCounts = {};

    for (final t in _allTraces) {
      totalTime += t.durationMs;
      totalTokens += t.tokensUsed;
      agentCounts[t.agent] = (agentCounts[t.agent] ?? 0) + 1;
    }

    return Container(
      color: DungeonColors.surfaceElevated,
      padding: const EdgeInsets.all(DungeonSpacing.md),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This session: ${_allTraces.length} decisions by ${agentCounts.length} AI agents",
              style: DungeonText.bodyMedium,
            ),
            const SizedBox(height: DungeonSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Total processing: ${totalTime}ms",
                    style: DungeonText.caption,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Tokens used: $totalTokens",
                    style: DungeonText.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DungeonSpacing.md),

            // Proportional bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: _agentFilterMap.entries.map((e) {
                    final count = agentCounts[e.value] ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Expanded(
                      flex: count,
                      child: Container(color: _getAgentColor(e.key)),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: DungeonSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: "Export traces",
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text("EXPORT"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DungeonColors.gold,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _exportTraces,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
