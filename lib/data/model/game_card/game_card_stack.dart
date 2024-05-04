import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:flutter/widgets.dart';

class GameCardStack {
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
    final swap = cards.value.where((element) => element.state == CardState.swap).toList();
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

  static GameCardStack fromJson(element) {
    var stack = GameCardStack();
    for (var card in element) {
      stack.add(GameCard.fromJson(card)!);
    }
    return stack;
  }
}
