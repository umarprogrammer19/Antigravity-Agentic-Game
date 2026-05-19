import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../../models/level_schema.dart';

class TileMapComponent extends Component {
  final LevelSchema levelSchema;
  static const double tileSize = 32.0;

  TileMapComponent(this.levelSchema);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final grid = levelSchema.grid;

    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        final tileValue = grid[r][c];
        final rect = Rect.fromLTWH(
          c * tileSize,
          r * tileSize,
          tileSize,
          tileSize,
        );

        switch (tileValue) {
          case 0: // WALL — very dark, no grid line
            canvas.drawRect(rect, Paint()..color = const Color(0xFF0D0F1A));
            break;
          case 1: // FLOOR — warm dark brown with subtle grid
            canvas.drawRect(rect, Paint()..color = const Color(0xFF2D1B0E));
            // Subtle grid line
            canvas.drawRect(
              rect,
              Paint()
                ..color = Colors.white.withOpacity(0.04)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.5,
            );
            break;
          case 3: // LAVA
            canvas.drawRect(rect, Paint()..color = const Color(0xFFEA580C));
            break;
          case 4: // TRAP (looks like floor)
            canvas.drawRect(rect, Paint()..color = const Color(0xFF2D1B0E));
            break;
          default:
            canvas.drawRect(rect, Paint()..color = const Color(0xFF2D1B0E));
        }
      }
    }

    // Draw EXIT tile — bright green with glow effect
    final exit = levelSchema.exitPosition;
    if (exit.length >= 2) {
      final r = exit[0];
      final c = exit[1];
      final exitRect = Rect.fromLTWH(
        c * tileSize,
        r * tileSize,
        tileSize,
        tileSize,
      );

      // Glow
      canvas.drawRect(
        exitRect.inflate(3),
        Paint()..color = const Color(0xFF059669).withOpacity(0.3),
      );
      // Tile
      canvas.drawRect(exitRect, Paint()..color = const Color(0xFF059669));

      // EXIT label
      final tp = TextPainter(
        text: const TextSpan(
          text: 'EXIT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(
          c * tileSize + (tileSize - tp.width) / 2,
          r * tileSize + (tileSize - tp.height) / 2,
        ),
      );
    }

    // Draw ITEMS — gold circle with "!" label
    for (var item in levelSchema.items) {
      final r = item.position[0];
      final c = item.position[1];
      final center = Offset(
        c * tileSize + tileSize / 2,
        r * tileSize + tileSize / 2,
      );

      canvas.drawCircle(
        center,
        tileSize / 3.5,
        Paint()..color = const Color(0xFFD4AF37),
      );

      final tp = TextPainter(
        text: const TextSpan(
          text: '!',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
      );
    }
  }
}
