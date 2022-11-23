import 'package:donut_game/constants.dart';
import 'package:donut_game/modules/game.dart';
import 'package:donut_game/modules/players.dart';
import 'package:flutter/material.dart';

class GameCard {
  GameCard(this.suit, this.value);

  Suit suit;
  Value value;
  CardState state = CardState.unknown;
  GamePlayer? belongsTo;

  int get points => valueToScore[value] ?? 0;

  @override
  String toString() {
    return "${valueToString[value]} of ${suitToString[suit]}";
  }

  Map<String, String> toJson() {
    return {
      "suit": suitToString[suit]!,
      "value": valueToString[value]!,
      "state": cardStateToString[state]!,
      "belongsTo": belongsTo?.name ?? 'nobody',
    };
  }

  static GameCard? fromJson(Map<String, dynamic> element) {
    try {
      return GameCard(
          stringToSuit[element['suit']]!, stringToValue[element['value']]!)
        ..state = stringToCardState[element['state']]!
        ..belongsTo = Game().playerDB[element['belongsTo']];
    } catch (e, s) {
      print('invalid card');
      print(s);
      return null;
    }
  }

  static List<Map<String, String>> jsonArray(List<GameCard> value) {
    List<Map<String, String>> output = [];
    value.forEach((element) {
      output.add(element.toJson());
    });
    return output;
  }

  @override
  bool operator ==(other) =>
      other is GameCard && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;
}

class GameDeck {
  factory GameDeck.fresh({int? decks}) {
    GameDeck deck = GameDeck();
    deck.contents = deck.generate(decks ?? 1);
    return deck;
  }

  factory GameDeck.shuffled({int? decks}) {
    GameDeck deck = GameDeck();
    deck.contents = deck.generate(decks ?? 1);
    deck.shuffle();
    return deck;
  }

  GameDeck();
  int decks = 1;
  late List<GameCard> contents;

  void shuffle() {
    contents.shuffle();
  }

  void replace() {
    contents = generate(decks);
  }

  List<GameCard> generate(int decks) {
    List<GameCard> cards = <GameCard>[];
    for (var suit in Suit.values) {
      for (var value in Value.values) {
        cards.add(GameCard(suit, value));
      }
    }
    return cards;
  }
}
