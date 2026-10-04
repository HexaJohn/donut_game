import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1280, 760);
    view.devicePixelRatio = 1;
  });

  testWidgets('home screen offers offline and online play', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildTheme(ThemePreset.donutLight), home: const HomeScreen()));
    await tester.pump();
    expect(find.text('Donut'), findsWidgets);
    expect(find.text('Start game'), findsOneWidget);
    await tester.tap(find.text('Online'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Join game'), findsOneWidget);
  });

  testWidgets('offline game deals and asks you to swap', (tester) async {
    final controller = OfflineGameController(nickname: 'Tester', bots: 3);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(ThemePreset.donutDark),
      home: GameScreen(controller: controller),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Deal'), findsOneWidget);

    await tester.tap(find.text('Deal'));
    // Dealing plus three bot swaps before it's our turn
    await _pumpFor(tester, const Duration(seconds: 8));
    expect(Game().state.value, GameState.waitingForPlayerToSwap);
    expect(find.text('Keep hand'), findsOneWidget);
    expect(controller.localPlayer.hand.cards.value.length, cardsPerHand);

    await tester.tap(find.text('Keep hand'));
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('Keep hand'), findsNothing);

    // Leave and let the cancelled game loop wind down
    await tester.pumpWidget(const SizedBox());
    await _pumpFor(tester, const Duration(seconds: 3));
  });

  for (final preset in ThemePreset.values) {
    testWidgets('${preset.label} theme renders the table', (tester) async {
      final controller = OfflineGameController(nickname: 'Tester', bots: 5);
      await tester.pumpWidget(MaterialApp(theme: buildTheme(preset), home: GameScreen(controller: controller)));
      await tester.tap(find.text('Deal'));
      await _pumpFor(tester, const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await _pumpFor(tester, const Duration(seconds: 3));
    });
  }
}
