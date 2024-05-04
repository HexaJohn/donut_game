import 'package:donut_game/data/model/game_card/game_card_stack.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/ws_server.dart';
import 'package:flutter/widgets.dart';

class GamePlayer {
  GamePlayer(this.name, this.number, this.human);
  int number;
  String name;
  String id = '';
  GameCardStack hand = GameCardStack();
  final ValueNotifier<int> swaps = ValueNotifier(3);
  bool swapped = false;
  int folds = 0;
  ValueNotifier<int> score = ValueNotifier(20);
  ValueNotifier<int> donuts = ValueNotifier(0);
  ValueNotifier<bool> winner = ValueNotifier(false);
  bool human;
  GameCard? cardToPlay;
  bool donut = true;

  /// Only applies to swapping?
  bool notReady = true;
  bool skip = false;
  bool voteToDeal = false;

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

  Future<GameCard> botPlay({bool? leading, Game? game}) async {
    GameCard card;
    if (leading ?? false) {
      card = hand.cards.value.first;
    } else {
      card = logicalFirst(game!);
    }
    await Future.delayed(const Duration(milliseconds: 550));
    final played = play(card);
    return played;
  }

  GameCard logicalFirst(Game game) {
    GameCard card;
    try {
      card = hand.cards.value.firstWhere((element) => element.suit == game.leadingCard!.suit);
    } catch (e) {
      try {
        card = hand.cards.value.firstWhere((element) => element.suit == game.trumpSuit.value);
      } catch (e) {
        card = hand.cards.value.first;
      }
    }
    return card;
  }

  void botSwap(Suit trump) {
    for (var card in hand.cards.value) {
      if (card.suit != trump && swaps.value > 0) {
        card.state = CardState.swap;
        swaps.value--;
      }
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
