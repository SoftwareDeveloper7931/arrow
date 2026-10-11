import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/logic/game_constants.dart';
import 'package:arrow_flow/logic/level_generator.dart';
import 'package:arrow_flow/logic/solver.dart';

void main() {
  test('All 300 levels are 100% strictly solvable and valid', () {
    final stopwatch = Stopwatch()..start();
    int totalArrowsChecked = 0;

    for (int lvl = 1; lvl <= GameConstants.minLevelCount; lvl++) {
      final level = LevelGenerator.generateLevel(lvl);
      expect(level.initialArrows, isNotEmpty, reason: 'Level $lvl must not be empty');
      expect(level.number, equals(lvl));
      expect(level.shapeName, isNotEmpty);

      final board = level.createInitialBoard();
      final result = Solver.solve(board);

      expect(
        result.isSolvable,
        isTrue,
        reason: 'Level $lvl (${level.shapeName}, ${level.rows}x${level.cols}) must be solvable',
      );
      expect(
        result.solutionSteps.length,
        equals(level.initialArrows.length),
        reason: 'Level $lvl all arrows must be solved',
      );

      totalArrowsChecked += level.initialArrows.length;
    }

    stopwatch.stop();
    // ignore: avoid_print
    print('Successfully verified all ${GameConstants.minLevelCount} levels ($totalArrowsChecked total arrows) in ${stopwatch.elapsedMilliseconds}ms.');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
