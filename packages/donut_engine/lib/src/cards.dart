/// Cards, the states a game moves through, and the scoring rules.
library;

enum Suit { spades, clubs, diamonds, hearts }

enum Value { two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace }

enum CardState { deck, held, swap, folded, played, unknown }

enum GameState {
  waiting,
  waitingToDeal,
  dealing,
  swapping,
  waitingForPlayerToSwap,
  waitingForPlayer,
  playing,
  waitingToSwap,
  waitingForNextRound,
  waitingForPlayers,
  gameOver,
}

/// Cards in a hand.
const int cardsPerHand = 5;

/// The score everyone starts a match on; first to zero wins.
const int startingScore = 20;

/// The starting points a table can choose from.
const List<int> startingScoreChoices = [10, 15, 20, 25, 30];

/// Cards a player may swap each hand.
const int maxSwaps = 3;

/// A player may not fold if they folded this many hands in a row.
const int maxConsecutiveFolds = 2;

/// Penalty for taking no tricks in a hand.
const int donutPenalty = 5;

/// Seats at a table.
const int maxSeats = 7;

/// People matchmaking puts at one public table.
const int maxPublicPlayers = 4;

const Map<Value, int> valueToScore = {
  Value.two: 2,
  Value.three: 3,
  Value.four: 4,
  Value.five: 5,
  Value.six: 6,
  Value.seven: 7,
  Value.eight: 8,
  Value.nine: 9,
  Value.ten: 10,
  Value.jack: 11,
  Value.queen: 12,
  Value.king: 13,
  Value.ace: 14,
};

const Map<Suit, String> suitToString = {
  Suit.spades: 'spades',
  Suit.clubs: 'clubs',
  Suit.diamonds: 'diamonds',
  Suit.hearts: 'hearts',
};

final Map<String, Suit> stringToSuit = {for (final e in suitToString.entries) e.value: e.key};

const Map<Value, String> valueToString = {
  Value.two: 'two',
  Value.three: 'three',
  Value.four: 'four',
  Value.five: 'five',
  Value.six: 'six',
  Value.seven: 'seven',
  Value.eight: 'eight',
  Value.nine: 'nine',
  Value.ten: 'ten',
  Value.jack: 'jack',
  Value.queen: 'queen',
  Value.king: 'king',
  Value.ace: 'ace',
};

final Map<String, Value> stringToValue = {for (final e in valueToString.entries) e.value: e.key};

const Map<CardState, String> cardStateToString = {
  CardState.deck: 'deck',
  CardState.held: 'held',
  CardState.swap: 'swap',
  CardState.folded: 'folded',
  CardState.played: 'played',
  CardState.unknown: 'unknown',
};

final Map<String, CardState> stringToCardState = {for (final e in cardStateToString.entries) e.value: e.key};

const Map<GameState, String> gameStateToString = {
  GameState.waiting: 'waiting',
  GameState.waitingToDeal: 'waitingToDeal',
  GameState.dealing: 'dealing',
  GameState.swapping: 'swapping',
  GameState.waitingForPlayerToSwap: 'waitingForPlayerToSwap',
  GameState.waitingForPlayer: 'waitingForPlayer',
  GameState.playing: 'playing',
  GameState.waitingToSwap: 'waitingToSwap',
  GameState.waitingForNextRound: 'waitingForNextRound',
  GameState.waitingForPlayers: 'waitingForPlayers',
  GameState.gameOver: 'gameOver',
};

final Map<String, GameState> stringToGameState = {for (final e in gameStateToString.entries) e.value: e.key};

/// Anything with a face: the app's cards and the engine's alike.
abstract interface class PlayingCard {
  Suit get suit;
  Value get value;
}

/// What [card] scores in a trick led in [lead] with [trump] trumps: its face
/// value if it follows the lead or is a trump, plus 15 for a trump. The
/// highest score takes the trick.
int scoreFor(PlayingCard card, {required Suit lead, required Suit trump}) =>
    valueToScore[card.value]! * (card.suit == lead || card.suit == trump ? 1 : 0) + (card.suit == trump ? 15 : 0);

/// How strong [card] is with [trump] trumps, ignoring the lead.
int strengthOf(PlayingCard card, Suit trump) => valueToScore[card.value]! + (card.suit == trump ? 15 : 0);

/// The cards that may be played from [hand]: the [lead] suit if there is
/// one and the hand has it, anything otherwise.
List<C> legalPlays<C extends PlayingCard>(List<C> hand, Suit? lead) {
  if (lead == null) return List.of(hand);
  final following = hand.where((card) => card.suit == lead).toList();
  return following.isEmpty ? List.of(hand) : following;
}
