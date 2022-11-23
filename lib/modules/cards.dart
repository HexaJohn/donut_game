import 'package:donut_game/constants.dart';
import 'package:donut_game/modules/players.dart';

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
      "state": cardStateToString[state]!
    };
  }
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
