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
    final swap = cards.value.where((element) => element.state == CardState.swap).toList();
    for (var element in swap) {
      element.state = CardState.folded;
    }
    return swap.toList();
  }

  List<Map<String, String>> toJsonArray() {
    List<Map<String, String>> output = [];
    for (final element in cards.value) {
      output.add(element.toJson());
    }
    return output;
  }

  static GameCardStack fromJson(element) {
    var stack = GameCardStack();
    for (final card in element) {
      stack.add(GameCard.fromJson(card)!);
    }
    return stack;
  }
}
