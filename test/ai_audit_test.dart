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
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout_test.dart' show loadRealFonts, pumpFor;

/// The AI audit finds text and art on real screens. Set AUDIT_SHOTS to a
/// folder to see it.
void main() {
  setUpAll(() async {
    await loadRealFonts();
    await (FontLoader('FlowBlock')
          ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/FlowBlock-Regular.ttf').readAsBytesSync()))))
        .load();
  });
  tearDown(() {
    AiAudit.instance.enabled.value = false;
    AiAudit.instance.textMode.value = AuditTextMode.outline;
  });

  for (final (name, screen, mode) in [
    ('home', () => const HomeScreen(), AuditTextMode.outline),
    ('game', () => GameScreen(controller: OfflineGameController(nickname: 'You', bots: 3)), AuditTextMode.outline),
    ('home_blocks', () => const HomeScreen(), AuditTextMode.blocks),
    ('home_flow', () => const HomeScreen(), AuditTextMode.flow),
  ]) {
    testWidgets('the AI audit marks text and art on $name', (tester) async {
      tester.view.physicalSize = const Size(1280, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AiAudit.instance.enabled.value = true;
      AiAudit.instance.textMode.value = mode;
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AiAudit.instance.theme(buildTheme(ThemePreset.midnightCasino)),
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

  testWidgets('in Codes mode the AI text is never shown, only codes', (tester) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AiAudit.instance.enabled.value = true;
    AiAudit.instance.textMode.value = AuditTextMode.codes;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(ThemePreset.midnightCasino),
      builder: (context, child) => AiAuditOverlay(child: child!),
      home: const HomeScreen(),
    ));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.textContaining('trick-taking'), findsNothing);
    expect(find.text('Start game'), findsNothing);
    expect(find.text('[A1]'), findsWidgets, reason: 'the title shows its code');
    await tester.pumpWidget(const SizedBox());
    await pumpFor(tester, const Duration(seconds: 3));
  });
}
