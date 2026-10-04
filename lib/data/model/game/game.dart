import 'dart:math';

import 'package:donut_game/data/model/game_card/game_card_deck.dart';
import 'package:donut_game/data/model/game_card/game_card_stack.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/ui/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:platform_device_id/platform_device_id.dart';

class Game {
  static final Game _singleton = Game._internal();

  ValueNotifier<bool> flipFlop = ValueNotifier(false);

  factory Game() {
    return _singleton;
  }

  static reset() {
    Game().log.clear();
    Game().playerDB.clear();
    Game().deck = GameCardDeck.fresh();
    Game().protectedActive = 1;
    Game().protectedDealer = 0;
    Game().table.dump();
    Game().discard.dump();
    Game().state.value = GameState.waitingForPlayers;
    Game().trumpSuit.value = Suit.values.first;
    Game().suddenDeath.clear();
    Game().champion.value = null;
    //Provision
    Game().addBot();
    Game().addBot();
  }

  Game._internal();

  Map<String, bool> log = {};

  Map<String, GamePlayer> playerDB = {};
  List<GamePlayer> get players => playerDB.values.toList();
  Iterable<GamePlayer> get playersByRef => playerDB.values;
  GameCardDeck deck = GameCardDeck.fresh();
  int _tricksRemaining = 0;
  GameCard? _lastDeal;
  int __dealer = 0;
  int __active = 1;

  late final ValueNotifier<GamePlayer> _dealerValue = ValueNotifier(players[__dealer]);
  late final ValueNotifier<GamePlayer> _activeValue = ValueNotifier(players[__active]);

  final ValueNotifier<GameState> state = ValueNotifier(GameState.waitingForPlayers);
  final ValueNotifier<Suit> trumpSuit = ValueNotifier(Suit.values.first);
  GameCardStack table = GameCardStack();
  GameCardStack discard = GameCardStack();
  GameCard? leadingCard;

  /// Players still in a sudden death tiebreak. Empty during normal play.
  final List<GamePlayer> suddenDeath = [];
  final ValueNotifier<GamePlayer?> champion = ValueNotifier(null);

  /// Players taking part in the current hand.
  Iterable<GamePlayer> get seated => suddenDeath.isEmpty ? players : suddenDeath;

  bool canFold(GamePlayer player) => suddenDeath.isEmpty && player.folds < maxConsecutiveFolds;

  /// Folds [player] out of the current hand. Returns false if they may not fold.
  bool fold(GamePlayer player) {
    if (!canFold(player)) return false;
    player.skip = true;
    player.donut = false;
    player.notReady = false;
    return true;
  }

  /// Starts a new match with the same players.
  void newMatch() {
    for (var player in players) {
      player.score.value = startingScore;
      player.donuts.value = 0;
      player.folds = 0;
      player.winner.value = false;
      player.hand.dump();
    }
    deck = GameCardDeck.fresh();
    table.dump();
    discard.dump();
    suddenDeath.clear();
    champion.value = null;
    state.value = GameState.waitingToDeal;
  }

  int get _dealer => __dealer;

  int get protectedDealer => __dealer;

  int get protectedActive => __active;

  set protectedActive(int value) {
    _active = value;
  }

  set protectedDealer(int value) {
    _dealer = value;
  }

  set _dealer(int index) {
    int index0 = index;

    if (index0 >= players.length) {
      index0 = index0 - players.length;
    }
    __dealer = index0;
    _dealerValue.value = players.elementAt(__dealer);
  }

  int get _active => __active;

  set _active(int index) {
    int index0 = index;

    if (index0 >= players.length) {
      index0 = index0 - players.length;
    }
    __active = index0;
    if (players.length < 2) __active = 0;
    _activeValue.value = players.elementAt(__active);
  }

  ValueNotifier<GamePlayer> get dealer {
    _dealerValue.value = players.elementAt(_dealer);
    return _dealerValue;
  }

  ValueNotifier<GamePlayer> get activePlayer {
    try {
      _activeValue.value = players.elementAt(_active);
    } on RangeError {
      _active = 0;
      _activeValue.value = players.elementAt(_active);
    }
    return _activeValue;
  }

  GamePlayer get activePlayerLazy {
    if (players.length < 2) {
      return players.elementAt(0);
    } else {
      return players.elementAt(_active);
    }
  }

  void nextDealer() {
    _dealer++;
    if (_dealer > players.length - 1) {
      _dealer = 0;
    }
    _dealerValue.value = players.elementAt(_dealer);
  }

  void addPlayer() {
    var number = Random().nextInt(9999);
    var newPlayer = GamePlayer('$number', players.length, true);
    playerDB.addEntries([MapEntry(number.toString(), newPlayer)]);
  }

  void addLocalPlayer(GamePlayer player) {
    playerDB.addEntries([MapEntry(player.id, player)]);
  }

  void addBot() {
    var number = Random().nextInt(9999);
    var newPlayer = GamePlayer('Bot $number', players.length, false);
    playerDB.addEntries([MapEntry(newPlayer.hashCode.toString(), newPlayer)]);
  }

  Future deal({bool? shuffle}) async {
    if (state.value == GameState.waitingToDeal) {
      state.value = GameState.dealing;
      shuffle ??= true;
      if (shuffle) {
        deck.shuffle();
      }
      for (var ii = 0; ii < cardsPerHand; ii++) {
        for (var i = 0; i < players.length; i++) {
          try {
            var i0 = _dealer + 1 + i;
            if (i0 > players.length - 1) {
              i0 = i0 - players.length;
            }
            GamePlayer player = players[i0];
            if (!seated.contains(player)) continue;
            await dealCard(player);
          } catch (e) {
            // TODO: Out of cards. Will this ever actually happen?
            // nextDealer();
            rethrow;
          }
        }
      }
      state.value = GameState.waitingToSwap;
      trumpSuit.value = _lastDeal!.suit;
      await swap();
      // nextDealer();
    } else {
//Do nothing
    }
  }

  Future<void> dealCard(GamePlayer player) async {
    await Future.delayed(const Duration(milliseconds: 50));
    GameCard top;
    try {
      top = deck.contents.first;
    } catch (e) {
      deck.contents = discard.cards.value;
      discard.dump();
      deck.contents.shuffle();
      top = deck.contents.first;
    }
    deck.contents.removeAt(0);
    top.state = CardState.held;
    top.belongsTo = player;
    player.hand.add(top);
    _lastDeal = top;
  }

  Future swap() async {
    state.value = GameState.swapping;
    for (var i = 0; i < players.length; i++) {
      try {
        var i0 = _active;
        if (i0 > players.length - 1) {
          i0 = i0 - players.length;
        }
        _active = i0;
        final GamePlayer player = players[i0];
        player.tricks = 0;
        if (!seated.contains(player)) {
          // Sitting out a sudden death hand
          player.skip = true;
          player.donut = false;
          _active = _active + 1;
          continue;
        }
        player.skip = false;
        player.donut = true;
        player.notReady = true;
        player.swaps.value = maxSwaps;

        if (!player.human) {
          player.botSwap(trumpSuit.value);
          player.notReady = false;
        } else {
          state.value = GameState.waitingForPlayerToSwap;
        }
        while (player.notReady) {
          await Future.delayed(const Duration(seconds: 1));
        }
        state.value = GameState.swapping;
        if (player.skip) {
          // Folded: whole hand goes to the discard pile
          player.folds++;
          for (var card in List<GameCard>.from(player.hand.cards.value)) {
            player.hand.remove(card);
            card.state = CardState.folded;
            discard.add(card);
          }
        } else {
          player.folds = 0;
          final List<GameCard> swapped = player.hand.swapDiscard();
          for (var i = 0; i < swapped.length; i++) {
            player.hand.remove(swapped[i]);
            discard.add(swapped[i]);
            await Future.delayed(const Duration(milliseconds: 100));
          }
          for (var i = 0; i < swapped.length; i++) {
            await dealCard(player);
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        _active = _active + 1;
      } catch (e) {
        rethrow;
      }
    }
    // Nobody left to play if everyone folded
    _tricksRemaining = players.any((element) => !element.skip) ? cardsPerHand : 0;
    while (_tricksRemaining > 0) {
      state.value = GameState.waitingForNextRound;
      await playRound();
      _tricksRemaining--;
    }
    // This is where players are scored for donuts
    players.where((element) => element.donut).forEach((element) {
      element.score.value = element.score.value + donutPenalty;
      element.donuts.value++;
    });
    for (var player in players) {
      player.voteToDeal = false;
      player.winner.value = false;
      player.hand.dump();
    }
    _checkForWinner();
    if (champion.value != null) {
      champion.value!.winner.value = true;
      state.value = GameState.gameOver;
      return;
    }
    _dealer++;
    _active = _dealer + 1;
    state.value = GameState.waitingToDeal;
  }

  Future playRound() async {
    leadingCard = null;
    state.value = GameState.playing;
    for (var i = 0; i < players.length; i++) {
      try {
        var i0 = _active;
        if (i0 > players.length - 1) {
          i0 = i0 - players.length;
        }
        _active = i0;
        final GamePlayer player = players[i0];
        player.cardToPlay = null;
        if (!player.human && !player.skip) {
          GameCard card;
          if (leadingCard == null) {
            card = await player.botPlay(leading: true);
            leadingCard = card;
          } else {
            card = await player.botPlay(game: this);
          }
          addToTable(card);
        } else {
          if (!player.skip) {
            state.value = GameState.waitingForPlayer;

            while (player.cardToPlay == null) {
              state.value = GameState.playing;

              await Future.delayed(const Duration(milliseconds: 100));
            }
            if (player.cardToPlay != null) {
              final card = player.play(player.cardToPlay!);
              card.belongsTo = player;
              leadingCard ??= card;
              addToTable(card);
            }
          }
        }
        _active = _active + 1;
      } catch (e) {
        rethrow;
      }
    }
    var winner = evaluateTableForWinner();
    winner.tricks++;
    winner.score.value = winner.score.value - 1;
    winner.notifyWin();
    _active = players.indexOf(winner);
    await Future.delayed(const Duration(seconds: 1));
    final int toDiscard = table.cards.value.length;
    for (var i = 0; i < toDiscard; i++) {
      final discarded = table.cards.value.first;
      table.remove(discarded);
      discard.add(discarded);
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  void _checkForWinner() {
    if (suddenDeath.isEmpty) {
      final finishers = players.where((element) => element.score.value <= 0).toList();
      if (finishers.length == 1) {
        champion.value = finishers.single;
      } else if (finishers.length > 1) {
        // Tie: play sudden death hands among the finishers
        suddenDeath.addAll(finishers);
      }
      return;
    }
    // Sudden death: whoever took the fewest tricks is eliminated,
    // unless everyone tied, in which case the hand is replayed
    final fewest = suddenDeath.map((element) => element.tricks).reduce(min);
    final eliminated = suddenDeath.where((element) => element.tricks == fewest).toList();
    if (eliminated.length < suddenDeath.length) {
      suddenDeath.removeWhere(eliminated.contains);
    }
    if (suddenDeath.length == 1) {
      champion.value = suddenDeath.single;
      suddenDeath.clear();
    }
  }

  void addToTable(GameCard card) {
    table.add(card);
  }

  GamePlayer evaluateTableForWinner() {
    Map<GamePlayer, int> standings = {};
    final cards = table.cards.value;
    for (var card in cards) {
      var newEntry = {card.belongsTo!: scoreThis(card, this)};
      standings.addEntries(newEntry.entries);
    }
    MapEntry<GamePlayer, int> winner = standings.entries.reduce((max, element) {
      if (max.value > element.value) {
        return max;
      } else {
        return element;
      }
    });
    return winner.key;
  }

  Future clientDeal() async {
    Uri uri = Uri(scheme: 'http', host: serverAddress, port: port, path: '/vote');
    Response response;
    String? deviceId = await PlatformDeviceId.getDeviceId;

    String body = '''
{"id": "${deviceId!}$username", "vote": "${!players.where((element) => element.name == username).first.voteToDeal}"}''';
    response = await post(uri, body: body);
    if (response.statusCode == 200) {}
  }

  Future clientSwap(int cardIndex) async {
    Uri uri = Uri(scheme: 'http', host: serverAddress, port: port, path: '/swap');
    Response response;
    String? deviceId = await PlatformDeviceId.getDeviceId;

    String body = '''
{"id": "${deviceId!}$username", "swap": $cardIndex}''';
    response = await post(uri, body: body);
    if (response.statusCode == 200) {}
  }

  Future clientSwapFinalize() async {
    Uri uri = Uri(scheme: 'http', host: serverAddress, port: port, path: '/swapvote');
    Response response;
    String? deviceId = await PlatformDeviceId.getDeviceId;

    String body = '''
{"id": "${deviceId!}$username"}''';
    response = await post(uri, body: body);
    if (response.statusCode == 200) {}
  }

  Future clientPlayCard(int card) async {
    Uri uri = Uri(scheme: 'http', host: serverAddress, port: port, path: '/play');
    Response response;
    String? deviceId = await PlatformDeviceId.getDeviceId;

    String body = '''
{"id": "${deviceId!}$username", "card": $card}''';
    response = await post(uri, body: body);
    if (response.statusCode == 200) {}
  }

  Future clientFold() async {
    Uri uri = Uri(scheme: 'http', host: serverAddress, port: port, path: '/fold');
    Response response;
    String? deviceId = await PlatformDeviceId.getDeviceId;

    String body = '''
{"id": "${deviceId!}$username"}''';
    response = await post(uri, body: body);
    if (response.statusCode == 200) {}
  }

  Future adminReset() async {
    Uri uri = Uri(scheme: 'http', host: serverAddress, port: port, path: '/reset');
    Response response;

    response = await get(uri);
    if (response.statusCode == 200) {}
  }
}
