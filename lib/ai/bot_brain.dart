import 'dart:math';

import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_engine/donut_engine.dart';

export 'package:donut_engine/donut_engine.dart' show BotSkill, BotSkillInfo;

/// A bot's decisions at an app table: the engine's [Brain], looking at the
/// table through [GameView]. Subclasses can override any decision.
class BotBrain {
  BotBrain(this.skill, {Random? random}) : _core = Brain<GameCard>(skill, random: random);

  final BotSkill skill;
  final Brain<GameCard> _core;

  /// How often a rookie throws the game rather than playing like a regular.
  static const double sabotage = Brain.sabotage;

  /// How strong [card] is with [trump] trumps, ignoring the lead.
  static int strength(GameCard card, Suit trump) => strengthOf(card, trump);

  /// Rough number of tricks [hand] should take.
  static double expectedTricks(List<GameCard> hand, Suit trump) => Brain.expectedTricks(hand, trump);

  /// The cards [hand] may play in [game] now: the lead suit if it has it.
  static List<GameCard> legal(List<GameCard> hand, Game game) =>
      legalPlays(hand, game.table.cards.value.isEmpty ? null : game.leadingCard?.suit);

  /// Cards to throw away, at most [swaps] of them.
  List<GameCard> chooseSwaps(List<GameCard> hand, Suit trump, int swaps) => _core.chooseSwaps(hand, trump, swaps);

  /// Whether to fold this hand rather than risk a donut.
  bool shouldFold(GamePlayer me, Game game) => _core.shouldFold(me.hand.cards.value, GameView(me, game));

  /// The card to play from [me]'s hand.
  GameCard chooseCard(GamePlayer me, Game game) => _core.chooseCard(me.hand.cards.value, GameView(me, game));
}

/// The app's table as a bot sees it.
class GameView implements BrainTable<GameCard> {
  GameView(this.me, this.game);

  final GamePlayer me;
  final Game game;

  @override
  Suit get trump => game.trumpSuit.value;

  @override
  List<GameCard> get trick => game.table.cards.value;

  @override
  Suit? get lead => trick.isEmpty ? null : game.leadingCard?.suit;

  @override
  bool get canFold => game.canFold(me);

  @override
  int get swapsLeft => me.swaps.value;

  @override
  int get stillToPlay => game.players.where((p) => !p.skip).length - trick.length - 1;

  @override
  Iterable<PlayingCard> get revealed => game.revealed;

  @override
  bool playedByHuman(GameCard card) => card.belongsTo?.human == true;

  @override
  bool get humanStillToPlay {
    final played = trick.map((card) => card.belongsTo).toSet();
    return game.players.any((p) => p.human && !p.skip && !played.contains(p));
  }
}
