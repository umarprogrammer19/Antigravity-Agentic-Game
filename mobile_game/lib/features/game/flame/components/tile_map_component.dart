import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../../../app/theme.dart';
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
        final rect = Rect.fromLTWH(c * tileSize, r * tileSize, tileSize, tileSize);
        Paint paint = Paint();

        switch (tileValue) {
          case 0:
            paint.color = DungeonColors.tileWall;
            break;
          case 1:
            paint.color = DungeonColors.tileFloor;
            break;
          case 3:
            paint.color = DungeonColors.tileLava;
            break;
          case 4:
            // Trap appears as floor until triggered
            paint.color = DungeonColors.tileFloor;
            break;
          default:
            paint.color = DungeonColors.tileFloor;
        }

        canvas.drawRect(rect, paint);
      }
    }

    // Draw exit tile
    final exitPos = levelSchema.exitPosition;
    if (exitPos.length >= 2) {
      final r = exitPos[0];
      final c = exitPos[1];
      
      // Glow
      final glowRect = Rect.fromLTWH((c * tileSize) - 2, (r * tileSize) - 2, tileSize + 4, tileSize + 4);
      final glowPaint = Paint()..color = DungeonColors.tileExit.withValues(alpha: 0.5);
      canvas.drawRect(glowRect, glowPaint);
      
      // Center
      final rect = Rect.fromLTWH(c * tileSize, r * tileSize, tileSize, tileSize);
      final paint = Paint()..color = DungeonColors.tileExit;
      canvas.drawRect(rect, paint);
    }

    // Draw item tiles
    for (var item in levelSchema.items) {
      final r = item.position[0];
      final c = item.position[1];
      final center = Offset(c * tileSize + tileSize / 2, r * tileSize + tileSize / 2);
      final paint = Paint()..color = DungeonColors.gold;
      canvas.drawCircle(center, tileSize / 4, paint);
    }
  }
}
