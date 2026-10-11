import 'package:donut_game/campaign/campaign.dart';
import 'package:donut_game/campaign/campaign_controller.dart';
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
/// Add --dart-define=STAGE=<stage id> to play a campaign stage instead, with
/// its backdrop and table.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('offline hand frame timings', (tester) async {
    const stage = String.fromEnvironment('STAGE');
    final controller = stage.isEmpty
        ? OfflineGameController(nickname: 'Perf', bots: 5)
        : CampaignGameController(stage: stageById(stage)!, difficulty: Difficulty.standard);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(ThemePreset.values.byName(const String.fromEnvironment('THEME', defaultValue: 'donutDark'))),
      home: GameScreen(controller: controller),
    ));
    await Future.delayed(const Duration(seconds: 1));

    // HANDS=n plays n hands back to back and times each one on its own, to
    // see whether frames get slower as the session goes on
    const hands = int.fromEnvironment('HANDS');
    if (hands > 0) {
      for (var hand = 1; hand <= hands; hand++) {
        await binding.traceAction(() => _playHand(controller), reportKey: 'hand_$hand');
      }
      return;
    }

    await binding.traceAction(() async {
      controller.deal();
      final end = DateTime.now().add(const Duration(seconds: 25));
      while (DateTime.now().isBefore(end)) {
        await Future.delayed(const Duration(milliseconds: 50));
        _act(controller);
      }
    }, reportKey: 'offline_hand');
  });
}

/// Takes the local player's turn if it's theirs: swaps the first card, plays
/// the first legal one.
void _act(GameController controller) {
  final game = Game();
  final local = controller.localPlayer!;
  if (game.state.value == GameState.waitingForPlayerToSwap && controller.isLocalTurn && local.notReady) {
    controller.toggleSwap(local.hand.cards.value.first);
    controller.confirmSwap();
  }
  if (game.state.value == GameState.playing && controller.isLocalTurn && local.cardToPlay == null) {
    final legal = local.hand.cards.value.where(controller.isLegal);
    if (legal.isNotEmpty) controller.play(legal.first);
  }
}

/// Deals and plays one whole hand, starting a new match first if the last
/// one ended.
Future<void> _playHand(GameController controller) async {
  final game = Game();
  if (game.state.value == GameState.gameOver) {
    await controller.newMatch();
    await Future.delayed(const Duration(milliseconds: 500));
  }
  controller.deal();
  final end = DateTime.now().add(const Duration(seconds: 90));
  var started = false;
  while (DateTime.now().isBefore(end)) {
    await Future.delayed(const Duration(milliseconds: 50));
    final state = game.state.value;
    if (state != GameState.waitingToDeal) started = true;
    if (started && (state == GameState.waitingToDeal || state == GameState.gameOver)) break;
    _act(controller);
  }
  // Let the last cards settle
  await Future.delayed(const Duration(seconds: 1));
}
