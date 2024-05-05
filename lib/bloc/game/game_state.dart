abstract class GameState {}

class GameInitial extends GameState {}

class GameWaiting extends GameState {}

class GameWaitingToDeal extends GameState {}

class GameDealing extends GameState {}

class GameSwapping extends GameState {}

class GameWaitingForPlayerToSwap extends GameState {}

class GameWaitingForPlayer extends GameState {}

class GamePlaying extends GameState {}

class GameWaitingToSwap extends GameState {}

class GameWaitingForNextRound extends GameState {}

class GameWaitingForPlayers extends GameState {}

class GameEnd extends GameState {}
