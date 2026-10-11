import 'package:donut_game/ai/bot_brain.dart';
import 'package:donut_game/data/model/game_card/game_card_stack.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/ws_server.dart';
import 'package:flutter/widgets.dart';

class GamePlayer {
  GamePlayer(this.name, this.number, this.human);
  int number;
  String name;
  String id = '';
  GameCardStack hand = GameCardStack();
  final ValueNotifier<int> swaps = ValueNotifier(maxSwaps);
  bool swapped = false;

  /// Consecutive hands folded.
  int folds = 0;

  /// Tricks taken in the current hand.
  int tricks = 0;

  /// Tricks taken over the whole match, for the career tally.
  int matchTricks = 0;
  ValueNotifier<int> score = ValueNotifier(startingScore);
  ValueNotifier<int> donuts = ValueNotifier(0);
  ValueNotifier<bool> winner = ValueNotifier(false);
  bool human;
  GameCard? cardToPlay;
  bool donut = true;

  /// Only applies to swapping?
  bool notReady = true;
  bool skip = false;
  bool voteToDeal = false;

  /// True only while the game is actually waiting for this player to play a
  /// card. Plays at any other moment are refused.
  bool awaitingCard = false;

  /// The deck this player's cards are drawn with, as catalog ids. Humans
  /// bring their own; bots get one picked from their name.
  late String cardBack = human ? 'pattern.classic' : botDeck(name).back;
  late String cardFace = human ? 'face.classic' : botDeck(name).face;

  /// How well this player plays when the game plays for them.
  BotSkill skill = BotSkill.regular;
  BotBrain get brain => _brain?.skill == skill ? _brain! : _brain = BotBrain(skill);
  BotBrain? _brain;

  /// This player's own chat lines, in place of the table bots' stock ones.
  BotLines? lines;

  /// A named campaign character rather than a stock table bot.
  bool character = false;

  @override
  String toString() {
    return name;
  }

  GameCard play(GameCard card, {String? sender = ''}) {
    final played = hand.cards.value.singleWhere((element) => element.toString() == card.toString());
    hand.remove(played);
    played.state = CardState.played;
    return card;
  }

  Future<GameCard> botPlay({required Game game}) async {
    final card = brain.chooseCard(this, game);
    await Future.delayed(const Duration(milliseconds: 800));
    return play(card);
  }

  void botSwap(Suit trump) {
    for (final card in brain.chooseSwaps(hand.cards.value, trump, swaps.value)) {
      card.state = CardState.swap;
      swaps.value--;
    }
  }

  void notifyWin() async {
    donut = false;
    winner.value = true;
    await Future.delayed(const Duration(seconds: 5));
    winner.value = false;
  }

  static GamePlayer fromDonutConnection(DonutConnection message) {
    return GamePlayer(message.username, 0, true);
  }

  static fromJson(Map<String, dynamic> data) {
    return GamePlayer(data['data'][0], 0, true);
  }
}

/// What a bot says when it takes a trick or eats a donut.
class BotLines {
  const BotLines({this.greet = const [], this.trick = const [], this.donut = const [], this.win = const []});

  final List<String> greet;
  final List<String> trick;
  final List<String> donut;
  final List<String> win;
}
