import 'package:donut_game/constants.dart';
import 'package:donut_game/modules/cards.dart';
import 'package:donut_game/modules/game.dart';
import 'package:flutter/widgets.dart';

class GamePlayer {
  GamePlayer(this.name, this.number, this.human);
  int number;
  String name;
  String id = '';
  CardStack hand = CardStack();
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
    print('($sender): ${name}: ${hand.cards.value}');
    print(card);
    final played = hand.cards.value
        .singleWhere((element) => element.toString() == card.toString());
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
    await Future.delayed(Duration(milliseconds: 550));
    final played = play(card);
    return played;
  }

  GameCard logicalFirst(Game game) {
    GameCard card;
    try {
      card = hand.cards.value
          .firstWhere((element) => element.suit == game.leadingCard!.suit);
    } catch (e) {
      try {
        card = hand.cards.value
            .firstWhere((element) => element.suit == game.trumpSuit.value);
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
    await Future.delayed(Duration(seconds: 5));
    winner.value = false;
  }
}

class CardStack {
  ValueNotifier<List<GameCard>> cards = ValueNotifier([]);

  void add(GameCard card) {
    var cache = cards.value;
    cache.add(card);
    cards.value = List.from(cache);
  }

  void remove(GameCard card) {
    var cache = cards.value;
    cache.remove(card);
    cards.value = List.from(cache);
  }

  void dump() {
    cards.value = List.from([]);
  }

  List<GameCard> swapDiscard() {
    int discarded = 0;
    final swap = cards.value
        .where((element) => element.state == CardState.swap)
        .toList();
    for (var element in swap) {
      discarded++;
      element.state = CardState.folded;
    }

    // cards.value = List.from(
    //     cards.value.where((element) => element.state == CardState.held));

    // cards.value = List.from(cards.value);
    return swap.toList();
  }

  List<Map<String, String>> toJsonArray() {
    List<Map<String, String>> output = [];
    cards.value.forEach((element) {
      output.add(element.toJson());
    });
    return output;
  }

  static CardStack fromJson(element) {
    var stack = CardStack();
    for (var card in element) {
      stack.add(GameCard.fromJson(card)!);
    }
    return stack;
  }
}
