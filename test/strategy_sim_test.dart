// Headless strategy simulation: runs whole matches on the real Game engine
// under fake time. Run with: flutter test test/strategy_sim_test.dart
import 'dart:math';

import 'package:donut_game/ai/bot_brain.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/res/resources.dart';
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// The proposed human strategy. Only uses information a human has: its own
/// hand, the trump, and cards seen face up on the table since the last
/// reshuffle of the discard pile.
class StrategyBrain extends BotBrain {
  StrategyBrain({this.folding = true, this.counting = true, this.foldBelow = 0.75}) : super(BotSkill.shark);

  final bool folding;
  final bool counting;
  final double foldBelow;
  final Set<String> seen = {};
  int _deckLen = 0;

  /// Remembers every card that lands face up. Returns the unsubscribe.
  void Function() watch(Game game) {
    void listener() {
      for (final card in game.table.cards.value) {
        seen.add(card.toString());
      }
    }

    game.table.cards.addListener(listener);
    return () => game.table.cards.removeListener(listener);
  }

  void _sync(Game game) {
    // Discard went back into the deck: those cards are live again
    if (game.deck.contents.length > _deckLen) seen.clear();
    _deckLen = game.deck.contents.length;
    if (!counting) seen.clear();
  }

  @override
  List<GameCard> chooseSwaps(List<GameCard> hand, Suit trump, int swaps) {
    final junk = hand.where((c) => c.suit != trump && valueToScore[c.value]! < 13).toList()
      ..sort((a, b) => valueToScore[a.value]!.compareTo(valueToScore[b.value]!));
    return junk.take(swaps).toList();
  }

  @override
  bool shouldFold(GamePlayer me, Game game) {
    _sync(game);
    if (!folding || !game.canFold(me)) return false;
    final hand = me.hand.cards.value;
    final trump = game.trumpSuit.value;
    final kept = hand.where((c) => !chooseSwaps(hand, trump, me.swaps.value).contains(c)).toList();
    final expected = BotBrain.expectedTricks(kept, trump) + 0.12 * (hand.length - kept.length);
    return expected < foldBelow;
  }

  Set<String> _unseen(List<GameCard> hand, Game game) {
    final mine = hand.map((c) => c.toString()).toSet();
    return {
      for (final suit in Suit.values)
        for (final value in Value.values) GameCard(suit, value).toString(),
    }..removeWhere((c) => mine.contains(c) || seen.contains(c));
  }

  bool _isBoss(GameCard card, List<GameCard> hand, Game game) {
    final unseen = _unseen(hand, game);
    return !Value.values
        .any((v) => valueToScore[v]! > valueToScore[card.value]! && unseen.contains(GameCard(card.suit, v).toString()));
  }

  bool _trumpsOut(List<GameCard> hand, Game game) {
    final unseen = _unseen(hand, game);
    return Value.values.any((v) => unseen.contains(GameCard(game.trumpSuit.value, v).toString()));
  }

  @override
  GameCard chooseCard(GamePlayer me, Game game) {
    _sync(game);
    final hand = me.hand.cards.value;
    final trump = game.trumpSuit.value;
    int s(GameCard c) => BotBrain.strength(c, trump);
    if (game.table.cards.value.isEmpty) {
      final byStrength = [...hand]..sort((a, b) => s(a).compareTo(s(b)));
      final plain = byStrength.where((c) => c.suit != trump).toList();
      final trumps = byStrength.where((c) => c.suit == trump).toList();
      final boss = plain.reversed.where((c) => _isBoss(c, hand, game) && !_trumpsOut(hand, game)).firstOrNull;
      if (boss != null) return boss;
      if (trumps.isNotEmpty && (_isBoss(trumps.last, hand, game) || trumps.length >= 3)) return trumps.last;
      final ace = plain.where((c) => c.value == Value.ace).firstOrNull;
      if (ace != null && me.tricks == 0) return ace;
      return plain.isNotEmpty ? plain.first : trumps.first;
    }
    final options = BotBrain.legal(hand, game)..sort((a, b) => scoreThis(a, game).compareTo(scoreThis(b, game)));
    final best = game.table.cards.value.map((c) => scoreThis(c, game)).reduce(max);
    final winners = options.where((c) => scoreThis(c, game) > best).toList();
    if (winners.isEmpty) return ([...options]..sort((a, b) => s(a).compareTo(s(b)))).first;
    final stillToPlay = game.players.where((p) => !p.skip).length - game.table.cards.value.length - 1;
    if (stillToPlay > 0) {
      final safe = winners.where((c) => _isBoss(c, hand, game) && (c.suit == trump || !_trumpsOut(hand, game)));
      if (safe.isNotEmpty) return safe.first;
      // No trick yet and running out of cards: take the best shot now
      if (me.tricks == 0 && hand.length <= 2) return winners.last;
    }
    return winners.first;
  }
}

class SimPlayer extends GamePlayer {
  SimPlayer(String name, this.custom) : super(name, 0, false);
  final BotBrain custom;
  @override
  BotBrain get brain => custom;
}

typedef Result = ({bool won, int donuts, int hands, int folds});

Result playMatch(BotBrain mine, BotSkill opponents, Random rng, {int seats = 4}) {
  late Result result;
  fakeAsync((async) {
    final game = Game();
    final me = SimPlayer('Me', mine)..id = 'me';
    final unwatch = mine is StrategyBrain ? mine.watch(game) : () {};
    final others = [for (var i = 1; i < seats; i++) GamePlayer('Bot $i', i, false)..skill = opponents];
    game.setupOffline(me, seats - 1, opponents: others);
    // Random first dealer so nobody gets the dealer edge for free
    final dealer = rng.nextInt(seats);
    game.protectedDealer = dealer;
    game.protectedActive = (dealer + 1) % seats;
    var folds = 0;
    while (game.state.value != GameState.gameOver) {
      game.deal();
      async.elapse(const Duration(minutes: 10));
      if (me.folds > 0) folds++;
      if (game.handNumber > 500) break;
    }
    async.elapse(const Duration(seconds: 10));
    result = (won: game.champion.value == me, donuts: me.donuts.value, hands: game.handNumber, folds: folds);
    game.abort();
    unwatch();
  });
  return result;
}

String row(String label, List<Result> results) {
  final n = results.length;
  final p = results.where((r) => r.won).length / n;
  final ci = 1.96 * sqrt(p * (1 - p) / n);
  final hands = results.fold<int>(0, (a, r) => a + r.hands);
  final donuts = results.fold<int>(0, (a, r) => a + r.donuts);
  final folds = results.fold<int>(0, (a, r) => a + r.folds);
  return '${label.padRight(24)} win ${(p * 100).toStringAsFixed(1).padLeft(5)}% ±${(ci * 100).toStringAsFixed(1)}'
      '  donut/hand ${(donuts / hands * 100).toStringAsFixed(1).padLeft(4)}%'
      '  fold/hand ${(folds / hands * 100).toStringAsFixed(1).padLeft(4)}%';
}

void main() {
  const matches = int.fromEnvironment('MATCHES', defaultValue: 300);
  test('strategy simulation', () {
    final rng = Random(7);
    final lines = <String>[];
    const only = String.fromEnvironment('TIERS'); // e.g. TIERS=shark,pro
    for (final tier
        in BotSkill.values.where((t) => t != BotSkill.rookie && (only.isEmpty || only.split(',').contains(t.name)))) {
      lines.add('--- vs 3x ${tier.label} ($matches matches each, fair share 25%) ---');
      final configs = <String, BotBrain Function()>{
        'Regular (naive) in seat': () => BotBrain(BotSkill.regular),
        'Strategy, no folding': () => StrategyBrain(folding: false),
        'Strategy, no counting': () => StrategyBrain(counting: false),
        'Strategy (full)': () => StrategyBrain(),
        'Strategy, fold < 1.0': () => StrategyBrain(foldBelow: 1.0),
        'Strategy, fold < 1.25': () => StrategyBrain(foldBelow: 1.25),
      };
      for (final entry in configs.entries) {
        final results = [for (var i = 0; i < matches; i++) playMatch(entry.value(), tier, rng)];
        lines.add(row(entry.key, results));
        // ignore: avoid_print
        print(lines.last);
      }
    }
    // ignore: avoid_print
    print('\n${lines.join('\n')}');
  }, timeout: Timeout.none);
}
