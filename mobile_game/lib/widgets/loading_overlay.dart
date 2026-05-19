import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Full-screen semi-transparent overlay shown during long async operations
/// like session start and level generation. Auto-times-out after [timeoutSeconds].
class LoadingOverlay extends StatefulWidget {
  final String message;
  final String? subMessage;
  final int timeoutSeconds;
  final VoidCallback? onTimeout;

  const LoadingOverlay({
    super.key,
    required this.message,
    this.subMessage,
    this.timeoutSeconds = 8,
    this.onTimeout,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Timer _progressTimer;
  double _progress = 0.0;
  bool _timedOut = false;
  late final int _totalMs;

  @override
  void initState() {
    super.initState();
    _totalMs = widget.timeoutSeconds * 1000;

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _progress = min(1.0, _progress + (100 / _totalMs));
        if (_progress >= 1.0 && !_timedOut) {
          _timedOut = true;
          widget.onTimeout?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _progressTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _rotationController,
            child: const Icon(
              Icons.local_fire_department,
              size: 48,
              color: DungeonColors.gold,
            ),
          ),
          const SizedBox(height: DungeonSpacing.lg),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _timedOut ? null : _progress,
                backgroundColor: DungeonColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  DungeonColors.gold,
                ),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: DungeonSpacing.lg),
          if (_timedOut) ...[
            Text(
              "Taking longer than expected…",
              style: DungeonText.bodyMedium.copyWith(
                color: DungeonColors.crimsonLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DungeonSpacing.sm),
            Text(
              "Check your connection and try again.",
              style: DungeonText.caption.copyWith(color: DungeonColors.textDim),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              widget.message,
              style: DungeonText.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (widget.subMessage != null) ...[
              const SizedBox(height: DungeonSpacing.sm),
              Text(
                widget.subMessage!,
                style: DungeonText.caption.copyWith(
                  color: DungeonColors.textDim,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
