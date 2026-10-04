import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Plays most of an offline hand and records frame timings.
/// Run: flutter drive --profile -d windows --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('offline hand frame timings', (tester) async {
    final controller = OfflineGameController(nickname: 'Perf', bots: 5);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(ThemePreset.values.byName(const String.fromEnvironment('THEME', defaultValue: 'donutDark'))),
      home: GameScreen(controller: controller),
    ));
    await Future.delayed(const Duration(seconds: 1));

    await binding.traceAction(() async {
      controller.deal();
      final game = Game();
      final end = DateTime.now().add(const Duration(seconds: 25));
      while (DateTime.now().isBefore(end)) {
        await Future.delayed(const Duration(milliseconds: 50));
        final local = controller.localPlayer;
        if (game.state.value == GameState.waitingForPlayerToSwap && controller.isLocalTurn && local.notReady) {
          controller.toggleSwap(local.hand.cards.value.first);
          controller.confirmSwap();
        }
        if (game.state.value == GameState.playing && controller.isLocalTurn && local.cardToPlay == null) {
          final legal = local.hand.cards.value.where(controller.isLegal);
          if (legal.isNotEmpty) controller.play(legal.first);
        }
      }
    }, reportKey: 'offline_hand');
  });
}
