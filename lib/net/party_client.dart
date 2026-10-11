import 'dart:async';
import 'dart:convert';

import 'package:donut_engine/donut_engine.dart' show BotSkill;
import 'package:donut_game/data/device_id.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/net/party_socket_io.dart'
    if (dart.library.js_interop) 'package:donut_game/net/party_socket_web.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// The party server in AWS (infra/game). Every table there has a six
/// character code that friends type in to join.
const partyServerUrl = 'wss://lb41mv4lkc.execute-api.us-east-2.amazonaws.com/live';

/// A table on the party server, hosted by this player or joined by code.
///
/// The server sends one "snap" per step of the table (a bot playing, a trick
/// clearing), each with how long to wait after the previous one, so they're
/// played back in order on a timed queue rather than all at once.
class PartyController extends RemoteTableController with WidgetsBindingObserver {
  /// Hosts a new party, joins [code], or with [matchmake] finds a public
  /// table with room (opening one if none has).
  PartyController({String? code, this.matchmake = false, required this.nickname, this.url = partyServerUrl, String? playerId, String? secret})
      : _code = code,
        _playerId = playerId,
        _secret = secret ?? '';

  final String nickname;
  final bool matchmake;
  final String url;
  String? _code;
  String? _playerId;
  String _secret;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _keepAlive;
  bool _running = false;
  int _attempts = 0;

  int _serial = 0;
  final Map<int, Completer<bool>> _pending = {};

  final List<(int, Map<String, dynamic>)> _queue = [];
  bool _draining = false;

  @override
  String get label => matchmake ? 'Public game' : (_code == null ? 'Party' : 'Party $_code');

  @override
  bool get publicParty => _public;

  @override
  String get kind => matchmake || _public ? 'public' : 'party';
  bool _public = false;

  @override
  GamePlayer? get localPlayer {
    for (final player in game.players) {
      if (player.id == _playerId) return player;
    }
    return null;
  }

  BotSkill? _botSkill;

  @override
  BotSkill? get tableBotSkill => _botSkill;

  @override
  Future<void> changeTable({BotSkill? skill, int? target}) async =>
      send('settings', {if (skill != null) 'skill': skill.name, if (target != null) 'target': target});

  @override
  bool get canReport => true;

  @override
  Future<String?> report(GamePlayer player, String reason, {String note = ''}) async {
    final sent = await send('report', {'player': player.id, 'reason': reason, if (note.isNotEmpty) 'note': note});
    return sent ? null : (error.value ?? 'The report didn\'t go through. Try again.');
  }

  @override
  bool get canManageBots => canRestart && (game.handNumber == 0 || game.champion.value != null);

  @override
  Future<void> addBot() async => send('addBot', {});

  @override
  Future<void> removeBot() async => send('removeBot', {});

  @override
  void start() {
    resetTable();
    _running = true;
    WidgetsBinding.instance.addObserver(this);
    _connect();
  }

  /// Back from the background: the connection may have died while asleep,
  /// so start a fresh one, which also brings the whole table back
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _running && _channel != null) {
      _subscription?.cancel();
      _channel?.sink.close();
      _lost();
    }
  }

  @override
  void dispose() {
    stopAutoReady();
    _running = false;
    WidgetsBinding.instance.removeObserver(this);
    _keepAlive?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    for (final pending in _pending.values) {
      pending.complete(false);
    }
    _pending.clear();
  }

  Future<void> _connect() async {
    _playerId ??= await deviceId();
    if (_secret.isEmpty) _secret = await deviceSecret();
    if (!_running) return;
    try {
      final channel = openPartySocket(Uri.parse(url));
      await channel.ready.timeout(const Duration(seconds: 8));
      if (!_running) {
        channel.sink.close();
        return;
      }
      _channel = channel;
      _subscription = channel.stream.listen(_receive, onDone: _lost, onError: (_) => _lost());
      final profile = PlayerProfile.instance;
      _write({
        // Once seated, coming back is always by code
        'a': _code != null ? 'join' : (matchmake ? 'matchmake' : 'create'),
        if (_code != null) 'code': _code,
        'name': nickname,
        'player': _playerId,
        'secret': _secret,
        'back': profile.cardPattern,
        'face': profile.cardFace,
        'emblem': profile.emblem.toJson(),
        if (_code == null && matchmake) 'blocked': Settings.instance.blocked.value.keys.toList(),
        // A table this player opens starts the way they like
        if (_code == null) 'skill': Settings.instance.botSkill.name,
        if (_code == null) 'target': Settings.instance.startingPoints,
      });
      // The API hangs up on connections quiet for ten minutes
      _keepAlive?.cancel();
      _keepAlive = Timer.periodic(const Duration(minutes: 5), (_) => _write({'a': 'ping'}));
    } catch (e) {
      _lost();
    }
  }

  /// The connection dropped: try again, backing off, keeping our seat.
  void _lost() {
    _keepAlive?.cancel();
    _subscription?.cancel();
    _channel = null;
    for (final pending in _pending.values) {
      pending.complete(false);
    }
    _pending.clear();
    if (!_running) return;
    _attempts++;
    if (_attempts > 1) error.value = 'Connection lost. Reconnecting...';
    Future.delayed(Duration(milliseconds: (500 * _attempts).clamp(500, 5000)), _connect);
  }

  void _write(Map<String, dynamic> message) => _channel?.sink.add(jsonEncode(message));

  void _receive(dynamic raw) {
    final Map<String, dynamic> message;
    try {
      message = Map<String, dynamic>.from(jsonDecode(raw as String) as Map);
    } catch (e) {
      return;
    }
    switch (message['k']) {
      case 'joined':
        _attempts = 0;
        error.value = null;
        _code = message['code'] as String?;
        _playerId = message['player'] as String? ?? _playerId;
        party.value = _code;
      case 'snap':
        _public = (message['game'] as Map?)?['public'] == true;
        final skill = (message['game'] as Map?)?['botSkill'];
        _botSkill = BotSkill.values.where((s) => s.name == skill).firstOrNull ?? _botSkill;
        _queue.add((message['delay'] as int? ?? 0, message));
        _drain();
      case 'ack':
        final pending = _pending.remove(message['n']);
        pending?.complete(message['ok'] == true);
        if (message['ok'] != true && message['message'] is String) _flash(message['message']);
      case 'error':
        // Couldn't get in (bad code, table full, party over): stop trying
        _running = false;
        _keepAlive?.cancel();
        _channel?.sink.close();
        error.value = message['message'] as String? ?? 'The party server refused.';
    }
  }

  /// A refused move: show why for a moment.
  void _flash(String text) {
    error.value = text;
    Future.delayed(const Duration(seconds: 3), () {
      if (error.value == text) error.value = null;
    });
  }

  /// Plays queued table steps one after another, each after its delay. If
  /// a backlog builds up (after a reconnect, or a slow phone), skips ahead
  /// rather than replaying the past slowly.
  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    while (_queue.isNotEmpty && _running) {
      final (delay, snap) = _queue.removeAt(0);
      if (delay > 0 && _queue.length < 6) await Future.delayed(Duration(milliseconds: delay));
      if (!_running) break;
      applySnapshot(snap);
    }
    _draining = false;
  }

  @override
  Future<bool> send(String action, Map<String, dynamic> body) {
    if (_channel == null) return Future.value(false);
    final n = ++_serial;
    final done = Completer<bool>();
    _pending[n] = done;
    _write({'a': action, 'b': body, 'n': n});
    return done.future.timeout(const Duration(seconds: 10), onTimeout: () {
      _pending.remove(n);
      return false;
    });
  }
}
