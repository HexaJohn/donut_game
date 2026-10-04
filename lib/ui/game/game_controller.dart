import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:donut_game/data/model/bullet_hole.dart';
import 'package:donut_game/data/model/chat_message.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/ink_stroke.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/modes/game_mode.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_card/game_card_stack.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/res/resources.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:platform_device_id/platform_device_id.dart';

/// Everything the game screen can ask for, whether the game runs locally or
/// on a server.
abstract class GameController {
  Game get game;
  GamePlayer? get localPlayer;
  bool get online;
  String get label;

  /// Connection problem to show the player, if any.
  final ValueNotifier<String?> error = ValueNotifier(null);

  /// Set when an online server switches the table to another game.
  final ValueNotifier<GameMode?> switchedTo = ValueNotifier(null);

  void start() {}
  void dispose() {}

  bool get isLocalTurn => localPlayer != null && game.players.isNotEmpty && game.activePlayerLazy == localPlayer;

  bool get canFold => localPlayer != null && game.canFold(localPlayer!);

  /// A card has been chosen but the game hasn't taken it yet.
  bool get playPending {
    final local = localPlayer;
    return local != null && local.cardToPlay != null && local.hand.cards.value.contains(local.cardToPlay);
  }

  /// The game is waiting for the local player to play a card right now.
  bool get canPlayNow {
    final local = localPlayer;
    if (local == null || local.skip || !local.awaitingCard) return false;
    final state = game.state.value;
    return (state == GameState.playing || state == GameState.waitingForPlayer) && !playPending;
  }

  /// Offline: deals. Online: toggles this player's vote to deal.
  Future<void> deal();
  Future<void> toggleSwap(GameCard card);
  Future<void> confirmSwap();
  Future<void> fold();
  Future<void> play(GameCard card);
  Future<void> sendChat(String text);

  /// Fires the revolver at the table; [x] and [y] run 0..1 across the felt.
  Future<void> shootTable(double x, double y);

  /// Fires the revolver at a player's placard.
  Future<void> shootSeat(String name);

  /// Throws a flashbang at [x], [y] (0..1 across the felt).
  Future<void> throwFlashbang(double x, double y);

  /// Whether a flashbang can be thrown now (not cooling down).
  bool get flashReady => game.flashReady;

  /// Extends marker or eraser stroke [strokeId] with [points] (0..1 across
  /// the felt), starting it if it's new.
  void draw(String strokeId,
      {required Color color, required double width, required bool erase, required List<Offset> points});
  Future<void> newMatch();

  /// Whether the local player may play [card] right now.
  bool isLegal(GameCard card) {
    final hand = localPlayer?.hand.cards.value ?? [];
    final lead = game.leadingCard?.suit;
    if (lead == null || game.table.cards.value.isEmpty) return true;
    if (card.suit == lead) return true;
    return !hand.any((element) => element.suit == lead);
  }

  /// Marks or unmarks [card] for swapping. Returns false if out of swaps.
  bool _markSwap(GameCard card) {
    final player = localPlayer!;
    if (card.state == CardState.swap) {
      card.state = CardState.held;
      player.swaps.value++;
      return true;
    }
    if (card.state == CardState.held && player.swaps.value > 0) {
      card.state = CardState.swap;
      player.swaps.value--;
      return true;
    }
    return false;
  }
}

class OfflineGameController extends GameController {
  OfflineGameController({required String nickname, required int bots})
      : _local = GamePlayer(nickname.isEmpty ? 'You' : nickname, 0, true)..id = 'local' {
    game.setupOffline(_local, bots, acrotron: Settings.instance.seatAcrotronOffline);
  }

  final GamePlayer _local;

  @override
  final Game game = Game();

  @override
  GamePlayer get localPlayer => _local;

  @override
  bool get online => false;

  @override
  String get label => 'Offline vs bots';

  @override
  void dispose() => game.abort();

  @override
  Future<void> deal() async {
    game.deal();
  }

  @override
  Future<void> toggleSwap(GameCard card) async => _markSwap(card);

  @override
  Future<void> confirmSwap() async => _local.notReady = false;

  @override
  Future<void> fold() async => game.fold(_local);

  @override
  Future<void> play(GameCard card) async => _local.cardToPlay = card;

  @override
  Future<void> sendChat(String text) async => game.say(_local.name, text);

  @override
  Future<void> shootTable(double x, double y) async => game.shootTable(_local.name, x, y);

  @override
  Future<void> shootSeat(String name) async => game.shootSeat(_local.name, name);

  @override
  Future<void> throwFlashbang(double x, double y) async => game.throwFlashbang(_local.name, x, y);

  @override
  void draw(String strokeId,
      {required Color color, required double width, required bool erase, required List<Offset> points}) {
    game.draw(_local.name, strokeId, color: color.toARGB32(), width: width, erase: erase, points: points);
  }

  @override
  Future<void> newMatch() async => game.newMatch();
}

class OnlineGameController extends GameController {
  OnlineGameController({required this.host, required this.port, required this.username});

  final String host;
  final int port;
  final String username;
  String _deviceId = '';
  bool _running = false;
  int _failures = 0;
  Map<String, ChatMessage> _chatSeen = {};
  int _inkRevision = -1;

  @override
  final Game game = Game();

  @override
  GamePlayer? get localPlayer {
    for (final player in game.players) {
      if (player.name == username) return player;
    }
    return null;
  }

  @override
  bool get online => true;

  @override
  String get label => 'Online at $host:$port';

  String get _id => '$_deviceId$username';

  /// Registers with the server. Throws a readable message on failure.
  static Future<void> join(String host, int port, String username) async {
    final deviceId = await PlatformDeviceId.getDeviceId ?? 'unknown';
    final http.Response response;
    try {
      response = await http
          .post(Uri(scheme: 'http', host: host, port: port, path: '/connect'),
              body: jsonEncode({'username': username, 'id': deviceId}))
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      throw 'The server at $host:$port did not answer.';
    } catch (e) {
      throw 'Could not reach $host:$port.';
    }
    if (response.statusCode != 200) throw 'The server refused to let you in (${response.statusCode}).';
  }

  @override
  void start() {
    game.abort();
    game.playerDB.clear();
    game.chat.value = [];
    _running = true;
    _loop();
  }

  @override
  void dispose() => _running = false;

  Future<void> _loop() async {
    _deviceId = await PlatformDeviceId.getDeviceId ?? 'unknown';
    while (_running) {
      try {
        final response = await http
            .get(Uri(
                scheme: 'http', host: host, port: port, path: '/update', queryParameters: {'ink_rev': '$_inkRevision'}))
            .timeout(const Duration(seconds: 3));
        if (!_running) break;
        _apply(jsonDecode(response.body)[0]);
        _failures = 0;
        error.value = null;
      } catch (e) {
        _failures++;
        if (_failures > 2) error.value = 'Connection lost. Reconnecting...';
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  void _apply(Map<String, dynamic> json) {
    final mode = GameModeInfo.fromName(json['mode']);
    if (mode != GameMode.donut) {
      switchedTo.value = mode;
      return;
    }
    final activeKeys = <String>{};
    for (var element in json['players']) {
      final String id = element['id'];
      activeKeys.add(id);
      final player = game.playerDB
          .putIfAbsent(id, () => GamePlayer(element['username'], game.playerDB.length, element['human'] == 'true'));
      final cards = GameCardStack.fromJson(element['cards']);
      for (var card in cards.cards.value) {
        card.belongsTo = player;
      }
      player
        ..voteToDeal = element['voteDeal'] == 'true'
        ..swaps.value = element['swaps']
        ..notReady = element['notReady'] == 'true'
        ..score.value = element['score']
        ..donuts.value = element['donuts']
        ..winner.value = element['winner']
        ..folds = element['folds']
        ..tricks = element['tricks'] ?? 0
        ..skip = element['skip'] == 'true';
      // A fresh wait for our card: forget any earlier, stale choice
      final awaiting = element['awaitingCard'] == 'true';
      if (awaiting && !player.awaitingCard) player.cardToPlay = null;
      player.awaitingCard = awaiting;
      player.agent = element['agent'] == true;
      // Keep the same stack so listeners survive; only replace its contents
      player.hand.cards.value = cards.cards.value;
    }
    game.playerDB.removeWhere((key, value) => !activeKeys.contains(key));

    final g = json['game'];
    game.state.value = stringToGameState[g['state']] ?? game.state.value;
    if (game.players.isNotEmpty) {
      game.protectedActive = g['active'];
      game.protectedDealer = g['dealer'];
    }
    game.leadingCard = g['leading_card'] == null ? null : GameCard.fromJson(g['leading_card']);
    game.trumpSuit.value = stringToSuit[g['trump']] ?? game.trumpSuit.value;
    game.table.cards.value = [for (var card in g['table']) GameCard.fromJson(card)!];
    game.discard.cards.value = [for (var card in g['discard']) GameCard.fromJson(card)!];
    game.deck.contents = [for (var card in g['deck']) GameCard.fromJson(card)!];

    final suddenDeath = List<String>.from(g['sudden_death'] ?? []);
    game.suddenDeath
      ..clear()
      ..addAll(game.players.where((element) => suddenDeath.contains(element.name)));
    final champions = game.players.where((element) => element.name == g['champion']);
    game.champion.value = champions.isEmpty ? null : champions.first;

    game.handNumber = g['hand'] ?? 0;
    game.trickSerial = g['trick_serial'] ?? 0;
    final trickWinners = game.players.where((element) => element.name == g['trick_winner']);
    game.lastTrickWinner = trickWinners.isEmpty ? null : trickWinners.first;

    // Clock: rebuild start time from elapsed, ignoring small drift
    final elapsed = Duration(milliseconds: g['elapsed_ms'] ?? 0);
    final running = g['clock_running'] == true;
    final now = DateTime.now();
    if (elapsed == Duration.zero) {
      game.matchStarted = null;
      game.matchEnded = null;
    } else if ((game.matchElapsed - elapsed).abs() > const Duration(seconds: 1) ||
        running != (game.matchEnded == null)) {
      game.matchStarted = now.subtract(elapsed);
      game.matchEnded = running ? null : now;
    }

    final holes = [for (var hole in g['holes'] ?? []) BulletHole.fromJson(hole)];
    if (holes.length != game.holes.value.length || (holes.isNotEmpty && holes.last != game.holes.value.last)) {
      game.holes.value = holes;
    }
    if (g['ink'] is List) {
      final strokes = [for (var stroke in g['ink']) InkStroke.fromJson(stroke)];
      // Keep our own unsent points on the stroke we're still drawing
      final local = game.ink.value.where((element) => element.id == _activeStroke);
      if (local.isNotEmpty) {
        final index = strokes.indexWhere((element) => element.id == _activeStroke);
        if (index < 0) {
          strokes.add(local.first);
        } else if (strokes[index].points.length < local.first.points.length) {
          strokes[index] = local.first;
        }
      }
      game.ink.value = strokes;
      _inkRevision = g['ink_rev'] ?? 0;
    }
    final flash = g['flash'];
    if (flash is Map) {
      game.flashAt = Offset((flash['x'] as num? ?? 0.5).toDouble(), (flash['y'] as num? ?? 0.5).toDouble());
      game.flashBy = flash['by'] ?? '';
      game.flashSerial = flash['serial'] ?? game.flashSerial;
      _serverFlashReady = flash['ready'] != false;
    }
    final spins = Map<String, int>.from(g['spins'] ?? {});
    if (!mapEquals(spins, game.spins.value)) game.spins.value = spins;

    // Shift server timestamps onto this machine's clock so chat bubbles
    // expire correctly even if the clocks disagree. Each message keeps the
    // local time it was first seen with, so polling jitter can't move it.
    final skew = g['now_ms'] == null ? Duration.zero : now.difference(DateTime.fromMillisecondsSinceEpoch(g['now_ms']));
    final seen = <String, ChatMessage>{};
    var changed = false;
    for (var raw in g['chat'] ?? []) {
      final key = '${raw['time']}|${raw['author']}|${raw['text']}';
      var message = _chatSeen[key];
      if (message == null) {
        final parsed = ChatMessage.fromJson(raw);
        message = ChatMessage(parsed.author, parsed.text, system: parsed.system, time: parsed.time.add(skew));
        changed = true;
      }
      seen[key] = message;
    }
    if (changed || seen.length != _chatSeen.length) {
      _chatSeen = seen;
      game.chat.value = seen.values.toList();
    }
  }

  /// Returns whether the server accepted it.
  Future<bool> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri(scheme: 'http', host: host, port: port, path: path), body: jsonEncode({'id': _id, ...body}))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      error.value = 'Could not reach the server.';
      return false;
    }
  }

  int _indexOf(GameCard card) => localPlayer?.hand.cards.value.indexOf(card) ?? -1;

  @override
  Future<void> deal() async {
    final player = localPlayer;
    if (player == null) return;
    player.voteToDeal = !player.voteToDeal;
    await _post('/vote', {'vote': '${player.voteToDeal}'});
  }

  @override
  Future<void> toggleSwap(GameCard card) async {
    final index = _indexOf(card);
    if (index < 0 || !_markSwap(card)) return;
    await _post('/swap', {'swap': index});
  }

  @override
  Future<void> confirmSwap() async {
    localPlayer?.notReady = false;
    await _post('/swapvote', {});
  }

  @override
  Future<void> fold() async {
    final player = localPlayer;
    if (player == null || !game.fold(player)) return;
    await _post('/fold', {});
  }

  @override
  Future<void> play(GameCard card) async {
    final index = _indexOf(card);
    if (index < 0) return;
    final local = localPlayer!;
    local.cardToPlay = card;
    // If the server says no (or can't be reached), let the player try again
    final accepted = await _post('/play', {'card': index});
    if (!accepted && local.cardToPlay == card) local.cardToPlay = null;
  }

  @override
  Future<void> sendChat(String text) async => await _post('/chat', {'text': text});

  @override
  Future<void> shootTable(double x, double y) async {
    // Show it straight away; the server's copy uses the same seed, so the hole
    // looks identical when the next sync replaces it
    final seed = Random().nextInt(1 << 30);
    game.shootTable(username, x, y, seed: seed);
    await _post('/shoot', {'x': x, 'y': y, 'seed': seed});
  }

  /// Stroke points waiting to go to the server, sent in small batches so
  /// other players watch the line being drawn.
  final Map<String, (Map<String, dynamic>, List<Offset>)> _pendingInk = {};
  Timer? _inkFlush;

  /// The stroke being drawn here right now; syncs keep our longer local copy
  /// of it until the server has caught up.
  String? _activeStroke;

  @override
  void draw(String strokeId,
      {required Color color, required double width, required bool erase, required List<Offset> points}) {
    _activeStroke = strokeId;
    game.draw(username, strokeId, color: color.toARGB32(), width: width, erase: erase, points: points);
    final meta = {'stroke': strokeId, 'color': color.toARGB32(), 'width': width, 'erase': erase};
    _pendingInk.putIfAbsent(strokeId, () => (meta, <Offset>[])).$2.addAll(points);
    _inkFlush ??= Timer(const Duration(milliseconds: 80), _flushInk);
  }

  Future<void> _flushInk() async {
    _inkFlush = null;
    final batches = Map.of(_pendingInk);
    _pendingInk.clear();
    for (final (meta, points) in batches.values) {
      await _post('/draw', {
        ...meta,
        'points': [
          for (final p in points) ...[p.dx, p.dy]
        ],
      });
    }
  }

  bool _serverFlashReady = true;

  @override
  bool get flashReady => _serverFlashReady;

  @override
  Future<void> throwFlashbang(double x, double y) async {
    // The server decides (cooldown); the bang arrives with the next sync
    _serverFlashReady = false;
    await _post('/flashbang', {'x': x, 'y': y});
  }

  @override
  Future<void> shootSeat(String name) async {
    game.spins.value = {...game.spins.value, name: (game.spins.value[name] ?? 0) + 1};
    await _post('/shoot', {'seat': name});
  }

  @override
  Future<void> newMatch() async {
    try {
      await http.get(Uri(scheme: 'http', host: host, port: port, path: '/reset'));
    } catch (e) {
      error.value = 'Could not reach the server.';
    }
  }
}
