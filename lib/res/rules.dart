import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_engine/donut_engine.dart';

// The rules live in the engine, shared with the server
export 'package:donut_engine/donut_engine.dart' show cardsPerHand, startingScore, maxSwaps, maxConsecutiveFolds, donutPenalty;

/// What [card] scores in [game]'s current trick.
int scoreThis(GameCard card, Game game) =>
    scoreFor(card, lead: game.leadingCard!.suit, trump: game.trumpSuit.value);
