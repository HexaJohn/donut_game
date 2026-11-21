import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/tutorial/tutorial_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tutorial's stacked hand, played out the way its coaching suggests.
void main() {
  setUp(() => PlayerProfile.instance.reset());

  test('the stacked deck is one whole deck', () {
    expect(TutorialController.stackedDeck.length, 52);
    expect(TutorialController.stackedDeck.toSet().length, 52);
  });

  /// Plays the hand: swaps what the coach names, and plays the card it
  /// suggests (or the lowest legal one). Returns the coaching seen, in order.
  Future<List<String>> playOut(WidgetTester tester, TutorialController controller,
      {bool swap = true, void Function()? each}) async {
    final seen = <String>[];
    void note() {
      final line = controller.coach.value;
      if (line != null && (seen.isEmpty || seen.last != line)) seen.add(line);
    }

    note();
    await controller.deal();
    final game = controller.game;
    final local = controller.localPlayer;
    for (var i = 0; i < 2000 && !controller.done.value; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      note();
      each?.call();
      if (game.state.value == GameState.waitingForPlayerToSwap && controller.isLocalTurn && local.notReady) {
        if (swap) {
          for (final card in [...local.hand.cards.value]) {
            if ((controller.coachLine() ?? '').contains(TutorialController.cardName(card))) {
              await controller.toggleSwap(card);
            }
          }
        }
        await controller.confirmSwap();
      } else if (controller.canPlayNow && local.cardToPlay == null) {
        final line = controller.coachLine() ?? '';
        if (seen.isEmpty || seen.last != line) seen.add(line);
        final legal = local.hand.cards.value.where(controller.isLegal).toList();
        final named = legal.where((card) => line.contains(TutorialController.cardName(card))).firstOrNull;
        final lowest = ([...legal]..sort((a, b) => valueToScore[a.value]!.compareTo(valueToScore[b.value]!))).first;
        await controller.play(named ?? lowest);
      }
    }
    return seen;
  }

  testWidgets('the coached hand plays out', (tester) async {
    final controller = TutorialController();
    final tricks = <String>[];
    final game = controller.game;
    var serial = game.trickSerial;
    void watch() {
      if (game.trickSerial != serial) {
        serial = game.trickSerial;
        tricks.add('${game.table.cards.value.map((c) => '${c.belongsTo?.name}:${TutorialController.cardName(c)}').join('  ')}'
            '  -> ${game.lastTrickWinner?.name}');
      }
    }

    final seen = await playOut(tester, controller, each: watch);
    expect(controller.done.value, isTrue, reason: 'the hand never finished');
    // ignore: avoid_print
    print('${seen.join('\n')}\n\n${tricks.join('\n')}');
    final local = controller.localPlayer;
    expect(game.trumpSuit.value, Suit.spades);
    expect(local.matchTricks, greaterThan(0), reason: 'following the coaching should take a trick');
    // Every teaching moment came up
    for (final part in ['Press Deal', 'trump', 'Tap up to', 'You lead', 'must play one', 'took the trick', 'No ']) {
      expect(seen.any((line) => line.contains(part)), isTrue, reason: 'never coached: $part');
    }
    controller.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('keeping the dealt hand still plays out', (tester) async {
    final controller = TutorialController();
    await playOut(tester, controller, swap: false);
    expect(controller.done.value, isTrue);
    controller.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  test('cards are named as printed', () {
    expect(TutorialController.cardName(GameCard(Suit.hearts, Value.jack)), 'J♥');
    expect(TutorialController.cardName(GameCard(Suit.spades, Value.ten)), '10♠');
  });
}
