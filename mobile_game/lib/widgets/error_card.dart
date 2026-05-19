import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Friendly error card that never exposes raw exception text.
/// Shows a user-facing message with optional retry and dismiss actions.
class ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final String? errorCode;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorCard({
    super.key,
    this.title = "Something went wrong",
    required this.message,
    this.errorCode,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DungeonSpacing.lg),
      decoration: BoxDecoration(
        color: DungeonColors.surfaceElevated,
        borderRadius: const BorderRadius.all(DungeonRadius.md),
        border: Border.all(color: DungeonColors.crimson, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: DungeonColors.crimsonLight,
            size: 40,
          ),
          const SizedBox(height: DungeonSpacing.md),
          Text(
            title,
            style: DungeonText.headingMedium.copyWith(
              color: DungeonColors.crimsonLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DungeonSpacing.sm),
          Text(
            message,
            style: DungeonText.bodyMedium.copyWith(
              color: DungeonColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (errorCode != null) ...[
            const SizedBox(height: DungeonSpacing.sm),
            Text(
              errorCode!,
              style: DungeonText.caption.copyWith(
                color: DungeonColors.textDim,
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: DungeonSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onDismiss != null) ...[
                OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DungeonColors.textSecondary,
                    side: const BorderSide(color: DungeonColors.textDim),
                    minimumSize: const Size(80, 44),
                  ),
                  child: const Text("DISMISS"),
                ),
                const SizedBox(width: DungeonSpacing.md),
              ],
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DungeonColors.gold,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(100, 44),
                  ),
                  child: const Text(
                    "RETRY",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Convenience: show a DungeonMind-styled SnackBar for transient errors.
  static void showSnackBarError(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: DungeonColors.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: onRetry != null
            ? SnackBarAction(
                label: "RETRY",
                textColor: DungeonColors.gold,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
