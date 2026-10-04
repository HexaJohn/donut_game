import 'dart:async';
import 'dart:convert';

import 'package:donut_game/data/model/chat_message.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/modes/bad_batch/bb_game.dart';
import 'package:donut_game/modes/bad_batch/deck_library.dart';
import 'package:donut_game/modes/game_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:platform_device_id/platform_device_id.dart';

/// Someone at the table.
class BbSeat {
  const BbSeat(this.name, {required this.human, this.ready = false, this.agent = false});

  final String name;
  final bool human;

  /// An AI agent playing through the MCP harness.
  final bool agent;

  /// Voted to start (online lobby).
  final bool ready;
}

/// What the Bad Batch screen can ask for, offline or online.
abstract class BbController {
  final ValueNotifier<BbView?> view = ValueNotifier(null);
  final ValueNotifier<List<BbSeat>> seats = ValueNotifier([]);
  final ValueNotifier<String?> error = ValueNotifier(null);

  /// Set when the server switches the table to another game.
  final ValueNotifier<GameMode?> switchedTo = ValueNotifier(null);

  String get localName;
  bool get online;
  String get label;
  ValueListenable<List<ChatMessage>> get chat;

  void start();
  void dispose();

  /// Plays [indexes] from your hand; [written] fills blank cards. Returns
  /// why it was refused, or null.
  Future<String?> submit(List<int> indexes, Map<int, String> written);

  /// As Card Czar, picks answer [index]. Returns why it was refused, or null.
  Future<String?> judge(int index);

  /// Offline: start (or restart) the game. Online: toggle ready to start.
  Future<void> ready();
  Future<void> sendChat(String text);

  bool get isCzar => view.value?.czar == localName;
  bool get readied => seats.value.any((seat) => seat.name == localName && seat.ready);
}

class OfflineBbController extends BbController {
  OfflineBbController({required String nickname, required int bots})
      : _local = GamePlayer(nickname.isEmpty ? 'You' : nickname, 0, true)..id = 'local' {
    table.setupOffline(_local, bots, acrotron: Settings.instance.seatAcrotronOffline);
    game = BadBatchGame(table);
  }

  final GamePlayer _local;
  final Game table = Game();
  late final BadBatchGame game;

  @override
  String get localName => _local.name;

  @override
  bool get online => false;

  @override
  String get label => 'Bad Batch · Offline vs bots';

  @override
  ValueListenable<List<ChatMessage>> get chat => table.chat;

  void _refresh() {
    view.value = BbView.fromJson(game.toJson(viewer: localName));
    seats.value = [for (final player in table.players) BbSeat(player.name, human: player.human)];
  }

  @override
  void start() {
    game.revision.addListener(_refresh);
    _refresh();
    ready();
  }

  @override
  void dispose() {
    game.revision.removeListener(_refresh);
    game.stop();
  }

  @override
  Future<void> ready() async {
    final settings = Settings.instance;
    game
      ..decks = DeckLibrary.instance.activeDecks
      ..pointsToWin = settings.bbPointsToWin
      ..blankCards = settings.bbBlankCards;
    error.value = game.start();
    _refresh();
  }

  @override
  Future<String?> submit(List<int> indexes, Map<int, String> written) async =>
      game.submit(localName, indexes, written: written);

  @override
  Future<String?> judge(int index) async => game.judge(localName, index);

  @override
  Future<void> sendChat(String text) async => table.say(localName, text);
}

class OnlineBbController extends BbController {
  OnlineBbController({required this.host, required this.port, required this.username});

  final String host;
  final int port;
  final String username;
  String _deviceId = '';
  bool _running = false;
  int _failures = 0;
  int _inkRevision = -1;

  final ValueNotifier<List<ChatMessage>> _chat = ValueNotifier([]);
  Map<String, ChatMessage> _chatSeen = {};

  @override
  String get localName => username;

  @override
  bool get online => true;

  @override
  String get label => 'Bad Batch · Online at $host:$port';

  @override
  ValueListenable<List<ChatMessage>> get chat => _chat;

  String get _id => '$_deviceId$username';

  @override
  void start() {
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
              scheme: 'http',
              host: host,
              port: port,
              path: '/update',
              queryParameters: {'id': _id, 'ink_rev': '$_inkRevision'},
            ))
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
    if (mode != GameMode.badBatch) {
      switchedTo.value = mode;
      return;
    }
    seats.value = [
      for (final player in json['players'])
        BbSeat(
          player['username'],
          human: player['human'] == 'true',
          ready: player['voteDeal'] == 'true',
          agent: player['agent'] == true,
        ),
    ];
    _inkRevision = json['game']?['ink_rev'] ?? _inkRevision;
    if (json['bb'] != null) view.value = BbView.fromJson(json['bb']);

    // Chat: keep each message's first-seen local time, shifted for clock skew
    final g = json['game'] ?? {};
    final now = DateTime.now();
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
      _chat.value = seen.values.toList();
    }
  }

  /// Returns null if accepted, otherwise the server's reason.
  Future<String?> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri(scheme: 'http', host: host, port: port, path: path), body: jsonEncode({'id': _id, ...body}))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return null;
      return response.body.isEmpty ? 'The server said no (${response.statusCode}).' : response.body;
    } catch (e) {
      error.value = 'Could not reach the server.';
      return 'Could not reach the server.';
    }
  }

  @override
  Future<String?> submit(List<int> indexes, Map<int, String> written) => _post('/bb/submit', {
        'cards': indexes,
        'written': {for (final entry in written.entries) '${entry.key}': entry.value},
      });

  @override
  Future<String?> judge(int index) => _post('/bb/judge', {'index': index});

  @override
  Future<void> ready() async {
    await _post('/vote', {'vote': '${!readied}'});
  }

  @override
  Future<void> sendChat(String text) async => await _post('/chat', {'text': text});
}
