import 'dart:math';

import 'package:donut_copy/donut_copy.dart';

import 'cards.dart';

/// How well a bot plays. Rookies throw the game to help a new player win;
/// regulars are the original table bots; each tier up makes fewer mistakes
/// and thinks further ahead.
enum BotSkill { rookie, regular, amateur, pro, shark }

extension BotSkillInfo on BotSkill {
  String get label => switch (this) {
        BotSkill.rookie => announceSkillRookie(),
        BotSkill.regular => announceSkillRegular(),
        BotSkill.amateur => announceSkillAmateur(),
        BotSkill.pro => announceSkillPro(),
        BotSkill.shark => announceSkillShark(),
      };

  String get blurb => switch (this) {
        BotSkill.rookie => announceSkillRookieBlurb(),
        BotSkill.regular => announceSkillRegularBlurb(),
        BotSkill.amateur => announceSkillAmateurBlurb(),
        BotSkill.pro => announceSkillProBlurb(),
        BotSkill.shark => announceSkillSharkBlurb(),
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

/// What a bot can see of the table when it's its turn: the facts a player
/// sitting there would know.
abstract interface class BrainTable<C extends PlayingCard> {
  Suit get trump;

  /// The trick so far, in play order.
  List<C> get trick;

  /// The suit led this trick; null when the bot is leading.
  Suit? get lead;

  /// Whether the rules let this bot fold now.
  bool get canFold;

  int get swapsLeft;

  /// Players still to play this trick after this bot.
  int get stillToPlay;

  /// Cards seen face up since the discard pile was last shuffled back in.
  Iterable<PlayingCard> get revealed;

  /// Whether a human played [card] in this trick.
  bool playedByHuman(C card);

  /// Whether a human in this hand hasn't played to the trick yet.
  bool get humanStillToPlay;
}

/// Decides a bot's swaps, folds and plays. Pure: reads the hand and the
/// table, changes nothing.
class Brain<C extends PlayingCard> {
  Brain(this.skill, {Random? random}) : _random = random ?? Random();

  final BotSkill skill;
  final Random _random;

  bool get _smart => skill.index >= BotSkill.amateur.index;

  /// How often a rookie throws the game rather than playing like a regular.
  static const double sabotage = 0.85;

  bool get _throwing => skill == BotSkill.rookie && _random.nextDouble() < sabotage;

  /// Cards to throw away, at most [swaps] of them.
  List<C> chooseSwaps(List<C> hand, Suit trump, int swaps) {
    if (_throwing) {
      // Throws away its best cards: trumps and court cards first
      final best = hand.where((card) => card.suit == trump || valueToScore[card.value]! >= 11).toList()
        ..sort((a, b) => strengthOf(b, trump).compareTo(strengthOf(a, trump)));
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
  static double expectedTricks(List<PlayingCard> hand, Suit trump) {
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
  bool shouldFold(List<C> hand, BrainTable<C> table) {
    if (skill.index < BotSkill.pro.index || !table.canFold) return false;
    final trump = table.trump;
    // Swaps will improve it a little; judge the hand as it would be kept
    final swapped = chooseSwaps(hand, trump, table.swapsLeft);
    final kept = hand.where((card) => !swapped.contains(card)).toList();
    final expected = expectedTricks(kept, trump) + 0.12 * (hand.length - kept.length);
    final nerve = skill == BotSkill.shark ? 0.75 : 0.5;
    return expected < nerve;
  }

  /// The card to play from [hand].
  C chooseCard(List<C> hand, BrainTable<C> table) {
    final trump = table.trump;
    final leading = table.trick.isEmpty;
    final options = legalPlays(hand, leading ? null : table.lead);
    if (_throwing) return leading ? _weakest(options, trump) : _helpFollow(options, table);
    if (!_smart) return leading ? hand.first : _regularFollow(hand, table);
    if (_random.nextDouble() < skill.blunder) return options[_random.nextInt(options.length)];
    return leading ? _lead(hand, table) : _follow(options, hand, table);
  }

  int _score(PlayingCard card, BrainTable<C> table) => scoreFor(card, lead: table.lead!, trump: table.trump);

  static C _weakest<C extends PlayingCard>(List<C> cards, Suit trump) =>
      ([...cards]..sort((a, b) => strengthOf(a, trump).compareTo(strengthOf(b, trump)))).first;

  /// A rookie following: stays out of a human's way, and only takes a trick
  /// to stop another bot beating a human who has already played.
  C _helpFollow(List<C> options, BrainTable<C> table) {
    final trick = table.trick;
    var winning = trick.first;
    for (final card in trick) {
      if (_score(card, table) > _score(winning, table)) winning = card;
    }
    final best = _score(winning, table);
    final humanBeaten = !table.playedByHuman(winning) && trick.any(table.playedByHuman);
    final winners = options.where((card) => _score(card, table) > best).toList()
      ..sort((a, b) => _score(a, table).compareTo(_score(b, table)));
    if (humanBeaten && !table.humanStillToPlay && winners.isNotEmpty) return winners.first;
    final losers = options.where((card) => _score(card, table) <= best).toList();
    if (losers.isEmpty) return _weakest(options, table.trump);
    // Burn the strongest card that still loses, so it can't win later
    return losers.reduce((a, b) => strengthOf(a, table.trump) >= strengthOf(b, table.trump) ? a : b);
  }

  /// The original bots: the lead suit, else a trump, else the first card.
  C _regularFollow(List<C> hand, BrainTable<C> table) =>
      hand.where((card) => card.suit == table.lead).firstOrNull ??
      hand.where((card) => card.suit == table.trump).firstOrNull ??
      hand.first;

  static int _id(PlayingCard card) => card.suit.index * 13 + card.value.index;

  /// Cards nobody has played face up since the last reshuffle and [hand]
  /// doesn't hold: what the others might have. Only sharks keep count; the
  /// rest only know their hand.
  Set<int> _unseen(List<C> hand, BrainTable<C> table) {
    final all = {for (var i = 0; i < 52; i++) i};
    all.removeAll(hand.map(_id));
    if (skill == BotSkill.shark) all.removeAll(table.revealed.map(_id));
    return all;
  }

  /// Whether nothing unseen in [card]'s suit outranks it.
  static bool _isBoss(PlayingCard card, Set<int> unseen) =>
      !unseen.any((id) => id ~/ 13 == card.suit.index && id % 13 > card.value.index);

  C _lead(List<C> hand, BrainTable<C> table) {
    final trump = table.trump;
    final byStrength = [...hand]..sort((a, b) => strengthOf(a, trump).compareTo(strengthOf(b, trump)));
    final plain = byStrength.where((card) => card.suit != trump).toList();
    final trumps = byStrength.where((card) => card.suit == trump).toList();
    if (skill == BotSkill.amateur) {
      // Cash an ace, otherwise get rid of something small
      final ace = plain.where((card) => card.value == Value.ace).firstOrNull;
      return ace ?? (plain.isNotEmpty ? plain.first : trumps.first);
    }
    final unseen = _unseen(hand, table);
    // A sure winner in a plain suit, unless someone trumps it
    final boss = plain.reversed.where((card) => _isBoss(card, unseen)).firstOrNull;
    if (boss != null) return boss;
    // Holding the top trump or plenty of them: pull everyone else's
    if (trumps.isNotEmpty && (_isBoss(trumps.last, unseen) || trumps.length >= 3)) return trumps.last;
    return plain.isNotEmpty ? plain.first : trumps.first;
  }

  C _follow(List<C> options, List<C> hand, BrainTable<C> table) {
    final trump = table.trump;
    final best = table.trick.map((card) => _score(card, table)).reduce(max);
    options.sort((a, b) => _score(a, table).compareTo(_score(b, table)));
    final winners = options.where((card) => _score(card, table) > best).toList();
    if (winners.isEmpty) {
      // Can't win it: throw the least useful card, saving trumps
      return ([...options]..sort((a, b) => strengthOf(a, trump).compareTo(strengthOf(b, trump)))).first;
    }
    if (skill == BotSkill.shark && table.stillToPlay > 0) {
      // Others still to come: prefer the cheapest winner they can't top
      final unseen = _unseen(hand, table);
      final trumpsOut = unseen.any((id) => id ~/ 13 == trump.index);
      final safe = winners.where((card) => _isBoss(card, unseen) && (card.suit == trump || !trumpsOut));
      if (safe.isNotEmpty) return safe.first;
    }
    return winners.first;
  }
}
