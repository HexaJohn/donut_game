import 'package:donut_game/modules/cards.dart';
import 'package:donut_game/modules/game.dart';

const int cardsPerHand = 5;

enum Suit {
  spades,
  clubs,
  diamonds,
  hearts,
}

enum Value {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace
}

enum CardState {
  deck,
  held,
  swap,
  folded,
  played,
  unknown,
}

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
  waitingForPlayers
}

Map<GameState, String> gameStateToString = {
  GameState.waiting: 'waiting',
  GameState.waitingToDeal: 'waitingToDeal',
  GameState.waitingForPlayers: 'waitingForPlayers',
  GameState.waitingForNextRound: 'waitingForNextRound',
  GameState.waitingToSwap: 'waitingToSwap',
  GameState.dealing: 'dealing',
  GameState.swapping: 'swapping',
  GameState.waitingForPlayerToSwap: 'waitingForPlayerToSwap',
  GameState.waitingForPlayer: 'waitingForPlayer',
  GameState.playing: 'playing'
};

Map<String, GameState> stringToGameState = {
  'waiting': GameState.waiting,
  'waitingToDeal': GameState.waitingToDeal,
  'waitingForPlayers': GameState.waitingForPlayers,
  'waitingToSwap': GameState.waitingToSwap,
  'dealing': GameState.dealing,
  'swapping': GameState.swapping,
  'waitingForPlayerToSwap': GameState.waitingForPlayerToSwap,
  'waitingForPlayer': GameState.waitingForPlayer,
  'playing': GameState.playing,
};

Map<CardState, String> cardStateToString = {
  CardState.deck: 'deck',
  CardState.held: 'held',
  CardState.swap: 'swap',
  CardState.folded: 'folded',
  CardState.played: 'played',
  CardState.unknown: 'unknown'
};

Map<String, CardState> stringToCardState = {
  'deck': CardState.deck,
  'held': CardState.held,
  'swap': CardState.swap,
  'folded': CardState.folded,
  'played': CardState.played,
  'unknown': CardState.unknown
};

Map<Value, int> valueToScore = {
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
  Value.ace: 14
};
Map<Value, String> valueToString = {
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
  Value.ace: 'ace'
};

Map<String, Value> stringToValue = {
  "two": Value.two,
  "three": Value.three,
  "four": Value.four,
  "five": Value.five,
  "six": Value.six,
  "seven": Value.seven,
  "eight": Value.eight,
  "nine": Value.nine,
  "ten": Value.ten,
  "jack": Value.jack,
  "queen": Value.queen,
  "king": Value.king,
  "ace": Value.ace,
};

Map<Suit, String> suitToString = {
  Suit.clubs: 'clubs',
  Suit.diamonds: 'diamonds',
  Suit.hearts: 'hearts',
  Suit.spades: 'spades'
};

Map<String, Suit> stringToSuit = {
  'clubs': Suit.clubs,
  'diamonds': Suit.diamonds,
  'hearts': Suit.hearts,
  'spades': Suit.spades,
};

Map<String, String> stringToCard = {
  'ace of spades': '🂡',
  'ace of hearts': '🂱',
  'ace of diamonds': '🃁',
  'ace of clubs': '🃑',
  'two of spades': '🂢',
  'two of hearts': '🂲',
  'two of diamonds': '🃂',
  'two of clubs': '🃒',
  'three of spades': '🂣',
  'three of hearts': '🂳',
  'three of diamonds': '🃃',
  'three of clubs': '🃓',
  'four of spades': '🂤',
  'four of hearts': '🂴',
  'four of diamonds': '🃄',
  'four of clubs': '🃔',
  'five of spades': '🂥',
  'five of hearts': '🂵',
  'five of diamonds': '🃅',
  'five of clubs': '🃕',
  'six of spades': '🂦',
  'six of hearts': '🂶',
  'six of diamonds': '🃆',
  'six of clubs': '🃖',
  'seven of spades': '🂧',
  'seven of hearts': '🂷',
  'seven of diamonds': '🃇',
  'seven of clubs': '🃗',
  'eight of spades': '🂨',
  'eight of hearts': '🂸',
  'eight of diamonds': '🃈',
  'eight of clubs': '🃘',
  'nine of spades': '🂩',
  'nine of hearts': '🂹',
  'nine of diamonds': '🃉',
  'nine of clubs': '🃙',
  'ten of spades': '🂪',
  'ten of hearts': '🂺',
  'ten of diamonds': '🃊',
  'ten of clubs': '🃚',
  'jack of spades': '🂫',
  'jack of hearts': '🂻',
  'jack of diamonds': '🃋',
  'jack of clubs': '🃛',
  'knight of spades': '🂬',
  'knight of hearts': '🂼',
  'knight of diamonds': '🃌',
  'knight of clubs': '🃜',
  'queen of spades': '🂭',
  'queen of hearts': '🂽',
  'queen of diamonds': '🃍',
  'queen of clubs': '🃝',
  'king of spades': '🂮',
  'king of hearts': '🂾',
  'king of diamonds': '🃎',
  'king of clubs': '🃞',
  'card back': '🂠',
};

int scoreThis(GameCard card, Game game) {
  int score = (valueToScore[card.value]! *
          (card.suit == game.leadingCard!.suit ||
                  card.suit == game.trumpSuit.value
              ? 1
              : 0)) +
      (card.suit == game.trumpSuit.value ? 15 : 0);
  // print(score);
  return (score);
}
