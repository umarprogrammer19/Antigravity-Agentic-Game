import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';

/// D-pad directional controls for mobile gameplay.
///
/// [onDirectionTap] is called with 'up', 'down', 'left', or 'right'
/// whenever a direction button is pressed. This MUST be connected to
/// the game's movement logic (e.g. DungeonGame._handlePlayerMove).
class DPadControls extends StatelessWidget {
  final void Function(String direction) onDirectionTap;
  final double buttonSize;
  final double iconSize;
  final double centerSize;
  final bool enabled;

  const DPadControls({
    super.key,
    required this.onDirectionTap,
    this.buttonSize = 56,
    this.iconSize = 28,
    this.centerSize = 48,
    this.enabled = true,
  });

  void _onTap(String direction) {
    HapticFeedback.lightImpact();
    if (!enabled) return;
    onDirectionTap(direction);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // UP
        _DPadButton(
          icon: Icons.arrow_upward,
          label: "Move up",
          size: buttonSize,
          iconSize: iconSize,
          enabled: enabled,
          onTap: () => _onTap('up'),
        ),

        // LEFT, CENTER, RIGHT
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DPadButton(
              icon: Icons.arrow_back,
              label: "Move left",
              size: buttonSize,
              iconSize: iconSize,
              enabled: enabled,
              onTap: () => _onTap('left'),
            ),

            // Center indicator (non-interactive)
            Container(
              width: centerSize,
              height: centerSize,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: DungeonColors.goldDim.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.circle,
                color: DungeonColors.goldDim.withValues(alpha: 0.2),
                size: 16,
              ),
            ),

            _DPadButton(
              icon: Icons.arrow_forward,
              label: "Move right",
              size: buttonSize,
              iconSize: iconSize,
              enabled: enabled,
              onTap: () => _onTap('right'),
            ),
          ],
        ),

        // DOWN
        _DPadButton(
          icon: Icons.arrow_downward,
          label: "Move down",
          size: buttonSize,
          iconSize: iconSize,
          enabled: enabled,
          onTap: () => _onTap('down'),
        ),
      ],
    );
  }
}

/// Individual D-pad button with proper minimum tap target (48x48).
class _DPadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;
  final double iconSize;
  final bool enabled;
  final VoidCallback onTap;

  const _DPadButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.iconSize,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(size / 2),
          splashColor: DungeonColors.gold.withValues(alpha: 0.2),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DungeonColors.surface.withValues(
                alpha: enabled ? 0.7 : 0.35,
              ),
              border: Border.all(
                color: DungeonColors.goldDim.withValues(
                  alpha: enabled ? 0.5 : 0.2,
                ),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: enabled ? DungeonColors.gold : DungeonColors.textDim,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
