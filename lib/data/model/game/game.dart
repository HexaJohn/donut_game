import 'dart:math';

import 'package:donut_game/data/model/game_card/game_card_deck.dart';
import 'package:donut_game/data/model/game_card/game_card_stack.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/ai/acrotron.dart';
import 'package:donut_game/data/model/bullet_hole.dart';
import 'package:donut_game/data/model/chat_message.dart';
import 'package:donut_game/data/model/ink_stroke.dart';
import 'package:flutter/material.dart';

extension _LastWhereOrNull<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}

/// Thrown inside the game loop when the game is reset mid-hand.
class _GameAborted implements Exception {}

const _botNames = [
  'Glazed Gary',
  'Sprinkles',
  'Boston Creme',
  'Cruller',
  'Maple Bar',
  'Jelly Jo',
  'Old Fashioned',
  'Bear Claw',
  'Cinnamon Sue',
  'Powdered Pete',
];

const _botTrickLines = ['Mine!', 'Thank you very much.', 'Too easy.', 'Yoink.', 'Called it.', 'Nom.'];
const _botDonutLines = ['Ouch.', 'Not again...', 'I was saving those cards.', 'Rigged deck.', 'Hmph.'];

class Game {
  static final Game _singleton = Game._internal();

  ValueNotifier<bool> flipFlop = ValueNotifier(false);

  factory Game() {
    return _singleton;
  }

  static reset() {
    Game().abort();
    Game().log.clear();
    Game().chat.value = [];
    Game().holes.value = [];
    Game().clearInk();
    Game().spins.value = {};
    Game().matchStarted = null;
    Game().matchEnded = null;
    Game().handNumber = 0;
    Game().playerDB.clear();
    Game().deck = GameCardDeck.fresh();
    Game().table.dump();
    Game().discard.dump();
    Game().state.value = GameState.waitingForPlayers;
    Game().trumpSuit.value = Suit.values.first;
    Game().suddenDeath.clear();
    Game().champion.value = null;
    //Provision
    Game().addBot();
    Game().addBot();
    // Seats exist now, so dealer and turn can point at them
    Game().protectedDealer = 0;
    Game().protectedActive = 1;
  }

  Game._internal();

  Map<String, bool> log = {};

  /// Bumped to cancel a game loop that is still running.
  int _epoch = 0;

  final ValueNotifier<List<ChatMessage>> chat = ValueNotifier([]);

  /// Bullet holes in the table, oldest first. Kept until a new match.
  final ValueNotifier<List<BulletHole>> holes = ValueNotifier([]);
  static const int _holeLimit = 80;

  /// How many times each player's placard has been shot (by name). Each shot
  /// spins it round once more.
  final ValueNotifier<Map<String, int>> spins = ValueNotifier({});

  void shootTable(String shooter, double x, double y, {int? seed}) {
    final hole =
        BulletHole(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0), shooter: shooter, seed: seed ?? Random().nextInt(1 << 30));
    final all = [...holes.value, hole];
    holes.value = all.length > _holeLimit ? all.sublist(all.length - _holeLimit) : all;
  }

  /// Marker and eraser strokes on the table, in drawing order.
  final ValueNotifier<List<InkStroke>> ink = ValueNotifier([]);

  /// Bumped on every change to [ink], so online clients only download the
  /// drawing when it has actually changed.
  int inkRevision = 0;
  static const int _inkPointLimit = 20000;

  /// Adds [points] to stroke [id], starting it if it's new.
  void draw(String author, String id,
      {required int color, required double width, required bool erase, required List<Offset> points}) {
    if (points.isEmpty) return;
    final strokes = ink.value;
    var stroke = strokes.lastWhereOrNull((element) => element.id == id);
    if (stroke == null) {
      stroke = InkStroke(id: id, author: author, color: color, width: width, erase: erase);
      strokes.add(stroke);
    } else if (stroke.author != author) {
      return;
    }
    stroke.points.addAll([for (final p in points) Offset(p.dx.clamp(0.0, 1.0), p.dy.clamp(0.0, 1.0))]);
    // Oldest strokes go first once the table gets crowded
    var total = strokes.fold<int>(0, (sum, element) => sum + element.points.length);
    while (total > _inkPointLimit && strokes.length > 1) {
      total -= strokes.removeAt(0).points.length;
    }
    inkRevision++;
    ink.value = List.of(strokes);
  }

  void clearInk() {
    ink.value = [];
    inkRevision++;
  }

  /// Flashbangs: [flashSerial] goes up by one per detonation, so every client
  /// can spot a new one; [flashAt] is where it landed (0..1 across the felt).
  int flashSerial = 0;
  Offset flashAt = const Offset(0.5, 0.5);
  String flashBy = '';
  DateTime? _lastFlash;
  static const Duration flashCooldown = Duration(seconds: 10);

  bool get flashReady => _lastFlash == null || DateTime.now().difference(_lastFlash!) >= flashCooldown;

  /// Throws a flashbang at [x], [y]. Refused during the cooldown, so nobody
  /// can keep the table permanently blind.
  bool throwFlashbang(String thrower, double x, double y) {
    if (!flashReady) return false;
    _lastFlash = DateTime.now();
    flashAt = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
    flashBy = thrower;
    flashSerial++;
    _announce('$thrower threw a flashbang!');
    return true;
  }

  void shootSeat(String shooter, String target) {
    if (!playerDB.values.any((player) => player.name == target)) return;
    spins.value = {...spins.value, target: (spins.value[target] ?? 0) + 1};
    _announce(shooter == target ? '$shooter shot their own placard.' : '$shooter shot $target\'s placard!');
  }

  static const int _chatLimit = 200;

  DateTime? matchStarted;
  DateTime? matchEnded;
  int handNumber = 0;

  /// Increments every time a trick is won, so watchers can spot new tricks.
  int trickSerial = 0;
  GamePlayer? lastTrickWinner;

  Duration get matchElapsed {
    if (matchStarted == null) return Duration.zero;
    return (matchEnded ?? DateTime.now()).difference(matchStarted!);
  }

  void say(String author, String text, {bool system = false}) {
    final messages = [...chat.value, ChatMessage(author, text, system: system)];
    chat.value = messages.length > _chatLimit ? messages.sublist(messages.length - _chatLimit) : messages;
  }

  void _announce(String text) => say('', text, system: true);

  void _botQuip(GamePlayer player, List<String> lines, double chance) {
    if (!player.human && Random().nextDouble() < chance) {
      say(player.name, lines[Random().nextInt(lines.length)]);
    }
  }

  /// Roughly how long the UI takes to fly a card to its place.
  static const _cardFlight = Duration(milliseconds: 450);

  /// Stops any game loop in progress.
  void abort() => _epoch++;

  Future<void> _pause(Duration duration, int epoch) async {
    await Future.delayed(duration);
    if (epoch != _epoch) throw _GameAborted();
  }

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
    if (!player.skip) _announce('${player.name} folds.');
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
    matchStarted = null;
    matchEnded = null;
    handNumber = 0;
    holes.value = [];
    spins.value = {};
    clearInk();
    _announce('New match! Everyone starts on $startingScore.');
    state.value = GameState.waitingToDeal;
  }

  /// Seats Acrotron, the Ollama-driven player. Returns false if it's already
  /// here, bots can't change now, or the table is full.
  bool addAcrotron() {
    if (players.any((p) => p.name == acrotronName) || !canChangeBots || players.length >= maxPlayers) return false;
    final acrotron = GamePlayer(acrotronName, players.length, false);
    playerDB['acrotron'] = acrotron;
    Acrotron.instance.attach(this);
    _announce('$acrotronName joined the table.');
    if (players.length > 2 && state.value == GameState.waitingForPlayers) state.value = GameState.waitingToDeal;
    return true;
  }

  /// Sets up a local game against bots, cancelling anything in progress.
  /// With [acrotron], one of the [bots] seats goes to Acrotron.
  void setupOffline(GamePlayer localPlayer, int bots, {bool acrotron = false}) {
    abort();
    playerDB.clear();
    chat.value = [];
    addLocalPlayer(localPlayer);
    final names = List<String>.from(_botNames)..shuffle();
    for (var i = 0; i < bots - (acrotron ? 1 : 0); i++) {
      final bot = GamePlayer(names[i % names.length], players.length, false);
      playerDB[bot.hashCode.toString()] = bot;
    }
    if (acrotron) {
      playerDB['acrotron'] = GamePlayer(acrotronName, players.length, false);
      Acrotron.instance.attach(this);
    }
    protectedDealer = 0;
    protectedActive = 1;
    newMatch();
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
    final taken = players.map((element) => element.name).toSet();
    final free = _botNames.where((element) => !taken.contains(element)).toList()..shuffle();
    var newPlayer = GamePlayer(free.isNotEmpty ? free.first : 'Bot ${Random().nextInt(9999)}', players.length, false);
    playerDB.addEntries([MapEntry(newPlayer.hashCode.toString(), newPlayer)]);
  }

  /// Seats at the table; enough for everyone to get a full hand plus swaps.
  static const int maxPlayers = 7;

  /// Bots can only come and go between hands, so turn order never shifts
  /// under a hand that's being played.
  bool get canChangeBots =>
      state.value == GameState.waitingForPlayers ||
      state.value == GameState.waitingToDeal ||
      state.value == GameState.gameOver;

  /// Seats a new bot. Returns false if bots can't change now or it's full.
  bool addBotToTable() {
    if (!canChangeBots || players.length >= maxPlayers) return false;
    addBot();
    _announce('${players.last.name} joined the table.');
    if (players.length > 2 && state.value == GameState.waitingForPlayers) state.value = GameState.waitingToDeal;
    return true;
  }

  /// Removes [bot], or the most recently added bot. Returns false if bots
  /// can't change now or there are none.
  bool removeBot([GamePlayer? bot]) {
    if (!canChangeBots) return false;
    final bots = players.where((element) => !element.human).toList();
    final leaving = bot ?? (bots.isEmpty ? null : bots.last);
    if (leaving == null || leaving.human) return false;
    playerDB.removeWhere((key, value) => identical(value, leaving));
    spins.value = {...spins.value}..remove(leaving.name);
    _announce('${leaving.name} left the table.');
    if (players.isNotEmpty) {
      // Keep dealer and turn pointing at real seats
      protectedDealer = protectedDealer % players.length;
      protectedActive = (protectedDealer + 1) % players.length;
    }
    if (players.length < 3 && state.value == GameState.waitingToDeal) state.value = GameState.waitingForPlayers;
    return true;
  }

  Future deal({bool? shuffle}) async {
    if (state.value != GameState.waitingToDeal) return;
    final epoch = _epoch;
    try {
      await _deal(shuffle ?? true, epoch);
    } on _GameAborted {
      // Game was reset while this hand was in progress
    }
  }

  Future _deal(bool shuffle, int epoch) async {
    {
      state.value = GameState.dealing;
      matchStarted ??= DateTime.now();
      handNumber++;
      _announce(suddenDeath.isEmpty
          ? 'Hand $handNumber: ${dealer.value.name} deals.'
          : 'Sudden death hand: ${suddenDeath.join(', ')}.');
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
            await _pause(const Duration(milliseconds: 60), epoch);
          } catch (e) {
            // TODO: Out of cards. Will this ever actually happen?
            // nextDealer();
            rethrow;
          }
        }
      }
      // Let the last cards land before hands are tidied up
      await _pause(_cardFlight, epoch);
      state.value = GameState.waitingToSwap;
      trumpSuit.value = _lastDeal!.suit;
      _announce('Trump is ${suitToString[trumpSuit.value]}.');
      await _pause(const Duration(milliseconds: 600), epoch);
      await _swap(epoch);
    }
  }

  Future<void> dealCard(GamePlayer player) async {
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

  Future _swap(int epoch) async {
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
          await _pause(const Duration(milliseconds: 500), epoch);
          player.botSwap(trumpSuit.value);
          player.notReady = false;
        } else {
          state.value = GameState.waitingForPlayerToSwap;
        }
        while (player.notReady) {
          await _pause(const Duration(milliseconds: 100), epoch);
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
          _announce(swapped.isEmpty
              ? '${player.name} keeps their hand.'
              : '${player.name} swaps ${swapped.length} card${swapped.length == 1 ? '' : 's'}.');
          for (var i = 0; i < swapped.length; i++) {
            player.hand.remove(swapped[i]);
            discard.add(swapped[i]);
            await _pause(const Duration(milliseconds: 150), epoch);
          }
          for (var i = 0; i < swapped.length; i++) {
            await dealCard(player);
            await _pause(const Duration(milliseconds: 150), epoch);
          }
          if (swapped.isNotEmpty) await _pause(_cardFlight, epoch);
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
      await _playRound(epoch);
      _tricksRemaining--;
    }
    // This is where players are scored for donuts
    players.where((element) => element.donut).forEach((element) {
      element.score.value = element.score.value + donutPenalty;
      element.donuts.value++;
      _announce('${element.name} got a donut! +$donutPenalty');
      _botQuip(element, _botDonutLines, 0.4);
    });
    for (var player in players) {
      player.voteToDeal = false;
      player.winner.value = false;
      player.hand.dump();
    }
    final wasSuddenDeath = suddenDeath.isNotEmpty;
    _checkForWinner();
    if (champion.value != null) {
      champion.value!.winner.value = true;
      matchEnded = DateTime.now();
      _announce('${champion.value!.name} wins the match!');
      state.value = GameState.gameOver;
      return;
    }
    if (suddenDeath.isNotEmpty && !wasSuddenDeath) {
      _announce('Tie! Sudden death between ${suddenDeath.join(', ')}.');
    }
    _dealer++;
    _active = _dealer + 1;
    state.value = GameState.waitingToDeal;
  }

  Future _playRound(int epoch) async {
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
          if (epoch != _epoch) throw _GameAborted();
          addToTable(card);
        } else {
          if (!player.skip) {
            state.value = GameState.waitingForPlayer;

            player.awaitingCard = true;
            try {
              while (player.cardToPlay == null) {
                state.value = GameState.playing;

                await _pause(const Duration(milliseconds: 100), epoch);
              }
            } finally {
              player.awaitingCard = false;
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
    lastTrickWinner = winner;
    trickSerial++;
    _announce('${winner.name} takes the trick.');
    _botQuip(winner, _botTrickLines, 0.2);
    _active = players.indexOf(winner);
    await _pause(const Duration(milliseconds: 1400), epoch);
    final int toDiscard = table.cards.value.length;
    for (var i = 0; i < toDiscard; i++) {
      final discarded = table.cards.value.first;
      table.remove(discarded);
      discard.add(discarded);
      await _pause(const Duration(milliseconds: 120), epoch);
    }
    await _pause(const Duration(milliseconds: 400), epoch);
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
}
