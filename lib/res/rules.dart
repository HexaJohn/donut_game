import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/res/values/value_score.dart';

const int cardsPerHand = 5;

int scoreThis(GameCard card, Game game) {
  int score =
      (valueToScore[card.value]! * (card.suit == game.leadingCard!.suit || card.suit == game.trumpSuit.value ? 1 : 0)) +
          (card.suit == game.trumpSuit.value ? 15 : 0);
  // print(score);
  return (score);
}
