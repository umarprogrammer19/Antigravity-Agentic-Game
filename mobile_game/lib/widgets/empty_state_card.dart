import 'package:flutter/material.dart';

import '../app/theme.dart';

/// A centered empty-state widget with icon, title, description, and optional CTA.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DungeonSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: DungeonColors.textDim),
            const SizedBox(height: DungeonSpacing.lg),
            Text(
              title,
              style: DungeonText.headingMedium.copyWith(
                color: DungeonColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DungeonSpacing.sm),
            Text(
              description,
              style: DungeonText.bodyMedium.copyWith(
                color: DungeonColors.textDim,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: DungeonSpacing.xl),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DungeonColors.gold,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(140, 48),
                ),
                child: Text(
                  buttonText!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
