import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_flow/logic/solver.dart';
import 'package:arrow_flow/models/arrow.dart';
import 'package:arrow_flow/services/audio_service.dart';
import 'package:arrow_flow/services/storage_service.dart';
import 'package:arrow_flow/state/game_controller.dart';
import 'package:arrow_flow/state/game_state.dart';
import 'package:arrow_flow/state/providers.dart';
import 'package:arrow_flow/ui/screens/game_screen.dart';

void main() {
  group('Arrow Flow Complete Gameplay Flow Tests', () {
    testWidgets('Trophy level 1 tap unblocked arrow escapes, blocked arrow reduces water drops', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'arrow_flow_current_level': 1,
        'arrow_flow_unlocked_level': 1,
        'arrow_flow_hints': 3,
      });

      final storage = await StorageService.init();
      late GameController controller;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            audioServiceProvider.overrideWithValue(AudioService(isTestMode: true)),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              controller = ref.watch(gameControllerProvider.notifier);
              return const MaterialApp(
                home: GameScreen(),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify initial level 1 state
      final initialBoard = controller.state.board;
      expect(controller.state.level.shapeName, equals('Trophy'));
      expect(controller.state.waterDrops, equals(3));
      expect(initialBoard.arrows, isNotEmpty);
      final initialArrowCount = initialBoard.arrows.length;

      // 2. Find an escapable arrow using solver/validator
      final validHint = Solver.getNextHint(initialBoard);
      expect(validHint, isNotNull);

      // Tap the escapable arrow (unawaited so fake async pump advances clock)
      unawaited(controller.onArrowTapped(validHint!));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify arrow successfully escaped and board count decreased
      expect(controller.state.board.arrows.length, equals(initialArrowCount - 1));
      expect(controller.state.waterDrops, equals(3)); // No drop lost on valid tap

      // 3. Find a blocked arrow (if any remains)
      Arrow? blockedArrow;
      for (final a in controller.state.board.arrows) {
        final check = Solver.getNextHint(controller.state.board);
        if (check?.id != a.id) {
          final b = controller.state.board;
          if (b.isOccupied(a.head.row + a.headDirection.dRow, a.head.col + a.headDirection.dCol)) {
            blockedArrow = a;
            break;
          }
        }
      }

      if (blockedArrow != null) {
        // Tap blocked arrow
        unawaited(controller.onArrowTapped(blockedArrow));
        await tester.pump(const Duration(milliseconds: 400));

        // Verify player lost 1 water drop
        expect(controller.state.waterDrops, equals(2));
      }

      // 4. Test dot grid toggle
      final gridBefore = controller.state.showDotGrid;
      controller.toggleDotGrid();
      expect(controller.state.showDotGrid, equals(!gridBefore));

      // 5. Test theme cycle
      final themeBefore = controller.state.currentTheme.type;
      controller.cycleTheme();
      expect(controller.state.currentTheme.type, isNot(equals(themeBefore)));

      // 6. Test hint request
      final hintsBefore = controller.state.availableHints;
      final hintSuccess = controller.requestHint();
      if (hintsBefore > 0) {
        expect(hintSuccess, isTrue);
        expect(controller.state.availableHints, equals(hintsBefore - 1));
        expect(controller.state.hintedArrowId, isNotNull);
      }
    });

    testWidgets('Clearing all arrows triggers won status and 3 stars', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'arrow_flow_current_level': 1,
        'arrow_flow_unlocked_level': 1,
        'arrow_flow_hints': 3,
      });

      final storage = await StorageService.init();
      late GameController controller;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            audioServiceProvider.overrideWithValue(AudioService(isTestMode: true)),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              controller = ref.watch(gameControllerProvider.notifier);
              return const MaterialApp(
                home: GameScreen(),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Solve the entire Trophy level step by step
      final solution = Solver.solve(controller.state.board);
      expect(solution.isSolvable, isTrue);

      for (final step in solution.solutionSteps) {
        final activeArrow = controller.state.board.arrows.firstWhere((a) => a.id == step.id);
        unawaited(controller.onArrowTapped(activeArrow));
        await tester.pump(const Duration(milliseconds: 400));
      }

      // Verify level won with 3 stars!
      expect(controller.state.status, equals(GameStatus.won));
      expect(controller.state.starsEarned, equals(3));
      expect(controller.state.board.isCleared, isTrue);

      // Pump to allow win celebration dialog timer to fire
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Level 1 • Trophy'), findsOneWidget);
      expect(find.text('Next Level'), findsOneWidget);
    });
  });
}
