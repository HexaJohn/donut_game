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
  int get cardsPerRound => 5;
  int _tricksRemaining = 0;
  int startingScore = 20;
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
        player.donut = true;
        player.notReady = true;
        player.swaps.value = 3;

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
        final List<GameCard> swapped = player.hand.swapDiscard();
        for (var i = 0; i < swapped.length; i++) {
          if (!player.skip) {
            player.hand.remove(swapped[i]);
            discard.add(swapped[i]);
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        for (var i = 0; i < swapped.length; i++) {
          if (!player.skip) {
            await dealCard(player);
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        _active = _active + 1;
      } catch (e) {
        rethrow;
      }
    }
    _tricksRemaining = 5;
    while (_tricksRemaining > 0) {
      state.value = GameState.waitingForNextRound;
      await playRound();
      _tricksRemaining--;
    }
    // This is where players are scored for donuts
    players.where((element) => element.donut).forEach((element) {
      element.score.value = element.score.value + 5;
      element.donuts.value++;
    });
    for (var player in players) {
      player.voteToDeal = false;
      player.winner.value = false;
      player.hand.dump();
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
{"id": "${deviceId!}$username"''';
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
