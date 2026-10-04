import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/modes/bad_batch/bb_builtin_deck.dart';
import 'package:donut_game/modes/bad_batch/bb_cards.dart';
import 'package:donut_game/modes/bad_batch/bb_cream_filled_deck.dart';
import 'package:donut_game/modes/bad_batch/bb_game.dart';
import 'package:donut_game/modes/bad_batch/crcast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cards', () {
    test('prompts fill their blanks', () {
      final question = PromptCard(['What ruined the party?', '']);
      expect(question.pick, 1);
      expect(question.fill(['Glitter.']), 'What ruined the party? Glitter.');
      final sentence = PromptCard.parse('My last relationship ended because of _.');
      expect(sentence.fill(['Mom\'s new boyfriend, Chad.']),
          'My last relationship ended because of Mom\'s new boyfriend, Chad.');
      final two = PromptCard.parse('Step one: _. Step two: _. Profit.');
      expect(two.pick, 2);
      expect(two.fill(['Lie', 'Run']), 'Step one: Lie. Step two: Run. Profit.');
    });

    test('built-in decks are playable', () {
      for (final deck in [builtinDeck, creamFilledDeck]) {
        expect(deck.prompts, isNotEmpty);
        expect(deck.responses.length, greaterThanOrEqualTo(7 * BadBatchGame.handSize));
        expect(deck.prompts.every((p) => p.pick >= 1), isTrue);
      }
    });

    test('CrCast codes come from codes or links', () {
      expect(CrCast.parseCode('zqw8g'), 'ZQW8G');
      expect(CrCast.parseCode('https://cast.clrtd.com/deck/ZQW8G'), 'ZQW8G');
      expect(CrCast.parseCode('https://crcast.cc/deck/AB12C?x=1'), 'AB12C');
      expect(CrCast.parseCode('not a deck'), isNull);
    });
  });

  testWidgets('a full game against bots', (tester) async {
    final table = Game();
    final me = GamePlayer('Me', 0, true)..id = 'local';
    table.setupOffline(me, 3);
    final game = BadBatchGame(table)
      ..decks = [builtinDeck]
      ..pointsToWin = 3
      ..blankCards = 120;
    expect(game.start(), isNull);
    expect(game.state, BbState.submitting);
    expect(game.hands['Me']!.length, BadBatchGame.handSize);

    final czars = <String>{};
    var wroteBlank = false;
    for (var step = 0; step < 4000 && game.state != BbState.gameOver; step++) {
      czars.add(game.czar!);
      if (game.state == BbState.submitting && game.czar != 'Me' && !game.submissions.containsKey('Me')) {
        final hand = game.hands['Me']!;
        // Play a blank card when holding one, to cover writing answers
        final blank = hand.indexWhere((card) => card.blank);
        final picks = [
          if (blank >= 0) blank,
          ...List.generate(hand.length, (i) => i).where((i) => i != blank),
        ].take(game.prompt!.pick).toList();
        final written = {
          for (final i in picks)
            if (hand[i].blank) i: 'my own answer'
        };
        wroteBlank |= written.isNotEmpty;
        expect(game.submit('Me', picks, written: written), isNull);
        expect(game.submit('Me', picks), isNotNull, reason: 'second answer refused');
      }
      if (game.state == BbState.judging) {
        // Answers are anonymous while being judged
        expect(game.toJson(viewer: 'Me')['authors'], isNull);
        if (game.czar == 'Me') expect(game.judge('Me', 0), isNull);
      }
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(game.state, BbState.gameOver);
    expect(game.champion, isNotNull);
    expect(game.scores[game.champion], 3);
    expect(czars.length, greaterThan(1), reason: 'the Czar rotates');
    expect(wroteBlank, isTrue, reason: 'with 120 blanks in the pile one always turns up');
    expect(game.toJson(viewer: 'Me')['hand'], isNotEmpty);
    expect(game.toJson()['hand'], isEmpty, reason: 'hands are private');
    game.stop();
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('refuses bad moves', (tester) async {
    final table = Game();
    table.setupOffline(GamePlayer('Me', 0, true)..id = 'local', 1);
    final game = BadBatchGame(table)..decks = [builtinDeck];
    expect(game.start(), contains('at least'));
    table.addBot();
    expect(game.start(), isNull);
    final czar = game.czar!;
    expect(game.submit(czar, [0]), contains('Czar'));
    expect(game.judge(czar, 0), isNotNull, reason: 'nothing to judge yet');
    game.stop();
    await tester.pump(const Duration(seconds: 10));
  });
}
