import 'dart:math';

import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/res/resources.dart';

/// How well a bot plays. Rookies throw the game to help a new player win;
/// regulars are the original table bots; each tier up makes fewer mistakes
/// and thinks further ahead.
enum BotSkill { rookie, regular, amateur, pro, shark }

extension BotSkillInfo on BotSkill {
  String get label => switch (this) {
        BotSkill.rookie => 'Rookie',
        BotSkill.regular => 'Regular',
        BotSkill.amateur => 'Amateur',
        BotSkill.pro => 'Pro',
        BotSkill.shark => 'Shark',
      };

  String get blurb => switch (this) {
        BotSkill.rookie => 'Still learning. Lets you win tricks.',
        BotSkill.regular => 'Plays whatever comes to hand.',
        BotSkill.amateur => 'Knows the basics, still slips up.',
        BotSkill.pro => 'Plays the odds and folds bad hands.',
        BotSkill.shark => 'Counts every card. Never blinks.',
      };

  /// Chance of playing a random legal card instead of thinking.
  double get blunder => switch (this) {
        BotSkill.rookie => 0,
        BotSkill.regular => 0,
        BotSkill.amateur => 0.2,
        BotSkill.pro => 0.08,
        BotSkill.shark => 0,
      };

  /// [steps] tiers up (positive) or down, clamped to the ends.
  BotSkill shifted(int steps) => BotSkill.values[(index + steps).clamp(0, BotSkill.values.length - 1)];
}

/// Decides a bot's swaps, folds and plays. Pure: reads the hand and the
/// table, changes nothing.
class BotBrain {
  BotBrain(this.skill, {Random? random}) : _random = random ?? Random();

  final BotSkill skill;
  final Random _random;

  bool get _smart => skill.index >= BotSkill.amateur.index;

  /// How often a rookie throws the game rather than playing like a regular.
  static const double sabotage = 0.85;

  bool get _throwing => skill == BotSkill.rookie && _random.nextDouble() < sabotage;

  /// How strong [card] is on a table where [trump] is trumps, ignoring the
  /// lead: trumps beat everything.
  static int strength(GameCard card, Suit trump) => valueToScore[card.value]! + (card.suit == trump ? 15 : 0);

  /// Cards to throw away, at most [swaps] of them.
  List<GameCard> chooseSwaps(List<GameCard> hand, Suit trump, int swaps) {
    if (_throwing) {
      // Throws away its best cards: trumps and court cards first
      final best = hand.where((card) => card.suit == trump || valueToScore[card.value]! >= 11).toList()
        ..sort((a, b) => strength(b, trump).compareTo(strength(a, trump)));
      return best.take(swaps).toList();
    }
    if (!_smart) {
      // The original bots: every non-trump card, in hand order
      return hand.where((card) => card.suit != trump).take(swaps).toList();
    }
    // Trumps are worth fishing for, so only top plain cards are kept:
    // aces, and kings for the better players
    final keepFrom = skill == BotSkill.amateur ? 14 : 13;
    final junk = hand.where((card) => card.suit != trump && valueToScore[card.value]! < keepFrom).toList()
      ..sort((a, b) => valueToScore[a.value]!.compareTo(valueToScore[b.value]!));
    return junk.take(swaps).toList();
  }

  /// Rough number of tricks [hand] should take.
  static double expectedTricks(List<GameCard> hand, Suit trump) {
    var tricks = 0.0;
    for (final card in hand) {
      final value = valueToScore[card.value]!;
      if (card.suit == trump) {
        tricks += value >= 11 ? 0.9 : 0.45;
      } else if (value == 14) {
        tricks += 0.55;
      } else if (value == 13) {
        tricks += 0.25;
      }
    }
    return tricks;
  }

  /// Whether to fold this hand rather than risk a donut. Only pros and up
  /// fold, and only when the rules allow it.
  bool shouldFold(GamePlayer me, Game game) {
    if (skill.index < BotSkill.pro.index || !game.canFold(me)) return false;
    final hand = me.hand.cards.value;
    final trump = game.trumpSuit.value;
    // Swaps will improve it a little; judge the hand as it would be kept
    final kept = hand.where((card) => !chooseSwaps(hand, trump, me.swaps.value).contains(card)).toList();
    final expected = expectedTricks(kept, trump) + 0.12 * (hand.length - kept.length);
    final nerve = skill == BotSkill.shark ? 0.75 : 0.5;
    return expected < nerve;
  }

  /// The cards [me] may play now: the lead suit if they have it.
  static List<GameCard> legal(List<GameCard> hand, Game game) {
    final lead = game.table.cards.value.isEmpty ? null : game.leadingCard?.suit;
    if (lead == null) return List.of(hand);
    final following = hand.where((card) => card.suit == lead).toList();
    return following.isEmpty ? List.of(hand) : following;
  }

  /// The card to play from [me]'s hand.
  GameCard chooseCard(GamePlayer me, Game game) {
    final hand = me.hand.cards.value;
    final trump = game.trumpSuit.value;
    final leading = game.table.cards.value.isEmpty;
    if (_throwing) return leading ? _weakest(legal(hand, game), trump) : _helpFollow(legal(hand, game), game, trump);
    if (!_smart) return leading ? hand.first : _rookieFollow(hand, game);
    final options = legal(hand, game);
    if (_random.nextDouble() < skill.blunder) return options[_random.nextInt(options.length)];
    return leading ? _lead(hand, game, trump) : _follow(options, me, game, trump);
  }

  static GameCard _weakest(List<GameCard> cards, Suit trump) =>
      ([...cards]..sort((a, b) => strength(a, trump).compareTo(strength(b, trump)))).first;

  /// A rookie following: stays out of a human's way, and only takes a trick
  /// to stop another bot beating a human who has already played.
  GameCard _helpFollow(List<GameCard> options, Game game, Suit trump) {
    final table = game.table.cards.value;
    var winning = table.first;
    for (final card in table) {
      if (scoreThis(card, game) > scoreThis(winning, game)) winning = card;
    }
    final best = scoreThis(winning, game);
    final played = table.map((card) => card.belongsTo).toSet();
    final humanWaiting = game.players.any((p) => p.human && !p.skip && !played.contains(p));
    final humanBeaten = winning.belongsTo?.human == false && table.any((card) => card.belongsTo?.human == true);
    final winners = options.where((card) => scoreThis(card, game) > best).toList()
      ..sort((a, b) => scoreThis(a, game).compareTo(scoreThis(b, game)));
    if (humanBeaten && !humanWaiting && winners.isNotEmpty) return winners.first;
    final losers = options.where((card) => scoreThis(card, game) <= best).toList();
    if (losers.isEmpty) return _weakest(options, trump);
    // Burn the strongest card that still loses, so it can't win later
    return losers.reduce((a, b) => strength(a, trump) >= strength(b, trump) ? a : b);
  }

  GameCard _rookieFollow(List<GameCard> hand, Game game) {
    final lead = game.leadingCard!.suit;
    return hand.where((card) => card.suit == lead).firstOrNull ??
        hand.where((card) => card.suit == game.trumpSuit.value).firstOrNull ??
        hand.first;
  }

  /// Cards nobody has played face up since the last reshuffle and [hand]
  /// doesn't hold: what the others might have. Only sharks keep count; the
  /// rest only know their hand.
  Set<GameCard> _unseen(List<GameCard> hand, Game game) {
    final all = {
      for (final suit in Suit.values)
        for (final value in Value.values) GameCard(suit, value),
    };
    all.removeAll(hand);
    if (skill == BotSkill.shark) {
      all.removeAll(game.revealed);
    }
    return all;
  }

  /// Whether nothing unseen in [card]'s suit outranks it.
  bool _isBoss(GameCard card, Set<GameCard> unseen) =>
      !unseen.any((other) => other.suit == card.suit && valueToScore[other.value]! > valueToScore[card.value]!);

  GameCard _lead(List<GameCard> hand, Game game, Suit trump) {
    final byStrength = [...hand]..sort((a, b) => strength(a, trump).compareTo(strength(b, trump)));
    final plain = byStrength.where((card) => card.suit != trump).toList();
    final trumps = byStrength.where((card) => card.suit == trump).toList();
    if (skill == BotSkill.amateur) {
      // Cash an ace, otherwise get rid of something small
      final ace = plain.where((card) => card.value == Value.ace).firstOrNull;
      return ace ?? (plain.isNotEmpty ? plain.first : trumps.first);
    }
    final unseen = _unseen(hand, game);
    // A sure winner in a plain suit, unless someone trumps it
    final boss = plain.reversed.where((card) => _isBoss(card, unseen)).firstOrNull;
    if (boss != null) return boss;
    // Holding the top trump or plenty of them: pull everyone else's
    if (trumps.isNotEmpty && (_isBoss(trumps.last, unseen) || trumps.length >= 3)) return trumps.last;
    return plain.isNotEmpty ? plain.first : trumps.first;
  }

  GameCard _follow(List<GameCard> options, GamePlayer me, Game game, Suit trump) {
    final table = game.table.cards.value;
    final best = table.map((card) => scoreThis(card, game)).reduce(max);
    options.sort((a, b) => scoreThis(a, game).compareTo(scoreThis(b, game)));
    final winners = options.where((card) => scoreThis(card, game) > best).toList();
    if (winners.isEmpty) {
      // Can't win it: throw the least useful card, saving trumps
      return ([...options]..sort((a, b) => strength(a, trump).compareTo(strength(b, trump)))).first;
    }
    final stillToPlay = game.players.where((p) => !p.skip).length - table.length - 1;
    if (skill == BotSkill.shark && stillToPlay > 0) {
      // Others still to come: prefer the cheapest winner they can't top
      final unseen = _unseen(me.hand.cards.value, game);
      final safe = winners.where((card) => _isBoss(card, unseen) && (card.suit == trump || !_trumpsOut(unseen, trump)));
      if (safe.isNotEmpty) return safe.first;
    }
    return winners.first;
  }

  bool _trumpsOut(Set<GameCard> unseen, Suit trump) => unseen.any((card) => card.suit == trump);
}
