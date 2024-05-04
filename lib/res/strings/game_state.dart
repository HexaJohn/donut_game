import 'package:donut_game/res/enums/game_state.dart';

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
