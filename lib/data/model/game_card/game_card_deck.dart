import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/res/resources.dart';

class GameCardDeck {
  factory GameCardDeck.fresh({int? decks}) {
    GameCardDeck deck = GameCardDeck();
    deck.contents = deck.generate(decks ?? 1);
    return deck;
  }

  factory GameCardDeck.shuffled({int? decks}) {
    GameCardDeck deck = GameCardDeck();
    deck.contents = deck.generate(decks ?? 1);
    deck.shuffle();
    return deck;
  }

  GameCardDeck();
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
