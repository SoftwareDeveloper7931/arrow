import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_flow/services/audio_service.dart';
import 'package:arrow_flow/services/storage_service.dart';
import 'package:arrow_flow/state/providers.dart';
import 'package:arrow_flow/ui/screens/game_screen.dart';

void main() {
  testWidgets('Capture Level 1 Trophy silhouette screenshot', (WidgetTester tester) async {
    // Configure mobile phone viewport (Pixel 7/8 dimensions: 412x892)
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'arrow_flow_current_level': 1,
      'arrow_flow_unlocked_level': 1,
      'arrow_flow_hints': 3,
    });

    final storage = await StorageService.init();
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          audioServiceProvider.overrideWithValue(AudioService(isTestMode: true)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: boundaryKey,
            child: const GameScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Render screenshot inside runAsync to allow platform image encoding
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = File('d:/work/game/arrow/trophy_level_1.png');
      await file.writeAsBytes(bytes);

      final artifactFile = File('C:/Users/afaqm/.gemini/antigravity-ide/brain/7af0f955-9450-4de9-851b-b9bab17ef025/trophy_level_1.png');
      await artifactFile.writeAsBytes(bytes);
    });

    final file = File('d:/work/game/arrow/trophy_level_1.png');
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(1000));
  });
}
