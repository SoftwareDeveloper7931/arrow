import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/logic/path_partitioner.dart';
import 'package:arrow_flow/logic/shape_library.dart';
import 'package:arrow_flow/models/arrow.dart';

void main() {
  group('PathPartitioner Tests', () {
    test('Every active mask cell is covered exactly once', () {
      final mask = ShapeLibrary.getShapeForLevel(1); // Trophy
      final random = math.Random(42);

      final paths = PathPartitioner.partition(
        mask: mask,
        random: random,
        minLen: 2,
        maxLen: 5,
      );

      expect(paths, isNotEmpty);

      final visited = <Cell>{};
      int totalPathCells = 0;

      for (final path in paths) {
        expect(path, isNotEmpty);
        totalPathCells += path.length;

        for (int i = 0; i < path.length; i++) {
          final cell = path[i];
          // Must be an active cell in the mask
          expect(mask.isSet(cell.col, cell.row), isTrue,
              reason: 'Cell $cell must be an active cell of the mask');

          // Must not be visited twice (no overlaps)
          expect(visited.contains(cell), isFalse,
              reason: 'Cell $cell was covered more than once');
          visited.add(cell);

          // If not the first cell, must be adjacent to previous cell (contiguous snake)
          if (i > 0) {
            final prev = path[i - 1];
            final dist = (cell.row - prev.row).abs() + (cell.col - prev.col).abs();
            expect(dist, equals(1),
                reason: 'Adjacent path cells must be 1 unit apart');
          }
        }
      }

      // Total path cells must match total active mask cells (no missing cells)
      expect(totalPathCells, equals(mask.activeCellCount));
    });
  });
}
