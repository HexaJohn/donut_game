abstract class GameEvent {}

class GameStartEvent extends GameEvent {
  final int playerCount;
  final int deckCount;

  GameStartEvent(this.playerCount, this.deckCount);
}

class GameEndEvent extends GameEvent {}

class GameUpdateEvent extends GameEvent {}

class GameJoinPlayerEvent extends GameEvent {
  final String playerName;

  GameJoinPlayerEvent(this.playerName);
}

class GameLeavePlayerEvent extends GameEvent {}

class GameJoinBotEvent extends GameEvent {}

class GameLeaveBotEvent extends GameEvent {}
