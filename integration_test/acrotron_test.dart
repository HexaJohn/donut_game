import 'package:donut_game/ai/acrotron.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/modes/bad_batch/bb_controller.dart';
import 'package:donut_game/modes/bad_batch/bb_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Plays a short offline Bad Batch game with Acrotron seated, against a real
/// local Ollama (gemma3:4b by default). Needs Ollama running, so it's a manual
/// check rather than part of `flutter test`:
///   flutter test integration_test/acrotron_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('acrotron plays bad batch on ollama', (tester) async {
    Settings.instance
      ..seatAcrotronOffline = true
      ..acrotronChattiness = 0.6
      ..bbPointsToWin = 3;
    final c = OfflineBbController(nickname: 'John', bots: 3);
    c.start();
    var taunted = false;
    final end = DateTime.now().add(const Duration(seconds: 150));
    while (DateTime.now().isBefore(end) && c.view.value?.state != BbState.gameOver) {
      final v = c.view.value!;
      if (v.state == BbState.submitting && !c.isCzar && !v.answered.contains('John')) {
        final picks = [
          for (var i = 0; i < v.hand.length; i++)
            if (!v.hand[i].blank) i
        ].take(v.prompt!.pick).toList();
        await c.submit(picks, {});
        if (!taunted) {
          taunted = true;
          await c.sendChat('Acrotron, your answers are as limp as a day-old cruller.');
        }
      }
      if (v.state == BbState.judging && c.isCzar) await c.judge(0);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    for (final m in c.chat.value) {
      if (m.author == acrotronName) print('ACROCHECK chat> ${m.text}');
      if (m.system && (m.text.contains('wins') || m.text.contains('Ollama'))) print('ACROCHECK game> ${m.text}');
    }
    print('ACROCHECK final state ${c.view.value?.state} scores ${c.view.value?.scores}');
    c.dispose();
  });
}
