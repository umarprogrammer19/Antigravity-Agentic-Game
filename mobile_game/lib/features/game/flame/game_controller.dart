import 'dart:math';

import '../../../../models/level_schema.dart';
import 'components/enemy_component.dart';

class GameController {
  final LevelSchema currentLevel;
  final Function(String) onGameEvent;

  GameController(this.currentLevel, this.onGameEvent);

  void processTurn(String action) {
    // Validates locally -> calls Flutter callback
    // Action could be 'move_up', 'move_down', etc.
    // In actual implementation, we just pass the action to the flutter callback to hit the Agent API
    onGameEvent(action);
  }

  int computeDamage(int attack, int defense) {
    return max(1, attack - defense);
  }

  bool isTileWalkable(int row, int col, List<List<int>> grid) {
    if (row < 0 || row >= grid.length) return false;
    if (col < 0 || col >= grid[row].length) return false;
    final tileValue = grid[row][col];
    // 0 = WALL, 1 = FLOOR, 3 = LAVA, 4 = TRAP
    return tileValue != 0;
  }

  List<int> getAdjacentPosition(List<int> pos, String direction) {
    int row = pos[0];
    int col = pos[1];
    switch (direction) {
      case 'up':
        row -= 1;
        break;
      case 'down':
        row += 1;
        break;
      case 'left':
        col -= 1;
        break;
      case 'right':
        col += 1;
        break;
    }
    return [row, col];
  }

  EnemyComponent? isEnemy(List<int> pos, List<EnemyComponent> enemies) {
    for (var enemy in enemies) {
      if (enemy.isAlive && enemy.gridRow == pos[0] && enemy.gridCol == pos[1]) {
        return enemy;
      }
    }
    return null;
  }
}
