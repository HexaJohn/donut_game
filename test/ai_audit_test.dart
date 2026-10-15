import 'dart:io';
import 'dart:ui' as ui;

import 'package:donut_game/audit/ai_audit.dart';
import 'package:donut_game/audit/ai_audit_overlay.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout_test.dart' show loadRealFonts, pumpFor;

/// The AI audit finds text and art on real screens. Set AUDIT_SHOTS to a
/// folder to see it.
void main() {
  setUpAll(loadRealFonts);
  tearDown(() => AiAudit.instance.enabled.value = false);

  for (final (name, screen) in [
    ('home', () => const HomeScreen()),
    ('game', () => GameScreen(controller: OfflineGameController(nickname: 'You', bots: 3))),
  ]) {
    testWidgets('the AI audit outlines text and art on the $name screen', (tester) async {
      tester.view.physicalSize = const Size(1280, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AiAudit.instance.enabled.value = true;
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(ThemePreset.midnightCasino),
        builder: (context, child) => RepaintBoundary(key: key, child: AiAuditOverlay(child: child!)),
        home: screen(),
      ));
      await pumpFor(tester, const Duration(seconds: 2));
      final summary = find.textContaining('AI audit:');
      expect(summary, findsOneWidget);
      final counts = RegExp(r'(\d+) text, (\d+) art').firstMatch((tester.widget(summary) as Text).data!)!;
      expect(int.parse(counts.group(1)!), greaterThan(5), reason: 'text found');
      expect(int.parse(counts.group(2)!), greaterThan(0), reason: 'art found');
      final dir = Platform.environment['AUDIT_SHOTS'];
      if (dir != null) {
        await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory(dir).createSync(recursive: true);
          File('$dir/audit_$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
      await tester.pumpWidget(const SizedBox());
      await pumpFor(tester, const Duration(seconds: 3));
    });
  }
}
