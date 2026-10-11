import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_flow/main.dart';
import 'package:arrow_flow/services/storage_service.dart';
import 'package:arrow_flow/state/providers.dart';

void main() {
  testWidgets('ArrowFlowApp home screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'arrow_flow_current_level': 1,
      'arrow_flow_unlocked_level': 1,
      'arrow_flow_hints': 3,
    });

    final storage = await StorageService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const ArrowFlowApp(),
      ),
    );

    // Verify title and main buttons exist
    expect(find.text('Arrow Flow'), findsOneWidget);
    expect(find.text('A calm arrow-clearing puzzle'), findsOneWidget);
    expect(find.text('Start Playing'), findsOneWidget);
    expect(find.text('Select Level'), findsOneWidget);
  });
}
