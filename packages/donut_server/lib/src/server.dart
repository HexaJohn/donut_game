import 'dart:convert';
import 'dart:io';

import 'package:donut_engine/donut_engine.dart';

import 'aws.dart';
import 'store.dart';

/// Delivers messages to players' open WebSocket connections.
abstract interface class Sender {
  /// Returns false if the connection has gone.
  Future<bool> send(String connectionId, Map<String, dynamic> message);
}

/// Sends through API Gateway's connection management API.
class ApiGatewaySender implements Sender {
  ApiGatewaySender({required this.endpoint, required String region, required AwsCredentials credentials})
      : _signer = SigV4(credentials, region: region, service: 'execute-api');

  /// host/stage, from the incoming event.
  final String endpoint;
  final SigV4 _signer;

  @override
  Future<bool> send(String connectionId, Map<String, dynamic> message) async {
    final slash = endpoint.indexOf('/');
    final host = endpoint.substring(0, slash);
    final stage = endpoint.substring(slash + 1);
    final response = await awsRequest(
      _signer,
      method: 'POST',
      host: host,
      path: '/$stage/${SigV4.encode('@connections')}/${SigV4.encode(connectionId)}',
      body: utf8.encode(jsonEncode(message)),
      headers: {'content-type': 'application/json'},
    );
    if (response.status == 410) return false;
    if (response.status != 200) throw StateError('postToConnection: ${response.status} ${response.text}');
    return true;
  }
}

/// The party server: one call per WebSocket event. Tables, who's connected
/// to each, and which party each connection belongs to live in [store]:
///
///   tables/<CODE>/state.json    the table (TableState)
///   tables/<CODE>/players.json  {player id: connection id}
///   conns/<connection id>.json  {code, player}
///
/// Client messages are {"a": action, ...}: "create" and "join" carry name,
/// back, face, player (a device id) and secret; moves carry "b" (the body
/// the app's online moves use) and "n" (a serial to acknowledge). The
/// server sends "joined" {code, player}, "snap" {delay, players, game} for
/// each frame, "ack" {n, ok, status, message} and "error" {message}.
class PartyServer {
  PartyServer({required this.store, required this.sender, DonutEngine? engine, int Function()? clock})
      : engine = engine ?? DonutEngine(),
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final Store store;
  final Sender sender;
  final DonutEngine engine;
  final int Function() _clock;

  static String _stateKey(String code) => 'tables/$code/state.json';
  static String _playersKey(String code) => 'tables/$code/players.json';
  static String _connKey(String connection) => 'conns/$connection.json';

  /// Handles one API Gateway WebSocket event.
  Future<void> handle(Map<String, dynamic> event) async {
    final context = Map<String, dynamic>.from(event['requestContext'] as Map);
    final connection = context['connectionId'] as String;
    _log(connection, '${context['routeKey']}', event['body'] as String?);
    switch (context['routeKey']) {
      case r'$connect':
        return;
      case r'$disconnect':
        await _disconnect(connection);
      default:
        Map<String, dynamic> message;
        try {
          message = Map<String, dynamic>.from(jsonDecode(event['body'] as String? ?? '{}') as Map);
        } catch (e) {
          await sender.send(connection, {'k': 'error', 'message': 'Unreadable message.'});
          return;
        }
        await _message(connection, message);
    }
  }

  /// One line per event in the function's log: which connection did what.
  /// Never the body itself, which carries the player's secret.
  void log(String line) => stderr.writeln(line);

  void _log(String connection, String route, String? body) {
    var action = '';
    if (body != null) {
      try {
        final message = jsonDecode(body);
        if (message is Map) action = ' ${message['a']}${message['code'] is String ? ' ${message['code']}' : ''}';
      } catch (_) {}
    }
    log('event $route ${connection.substring(0, connection.length.clamp(0, 8))}$action');
  }

  Future<void> _message(String connection, Map<String, dynamic> message) async {
    final action = '${message['a']}';
    try {
      switch (action) {
        case 'create':
          await _create(connection, message);
        case 'join':
          await _join(connection, message);
        case 'ping':
          return;
        default:
          await _move(connection, action, message);
      }
    } on Refusal catch (refusal) {
      await sender.send(connection, {
        'k': 'ack',
        'n': message['n'],
        'ok': false,
        'status': refusal.status,
        'message': refusal.message,
      });
      if (action == 'create' || action == 'join') {
        await sender.send(connection, {'k': 'error', 'message': refusal.message});
      }
    }
  }

  ({String name, String player, String secret, String? back, String? face, Map<String, dynamic>? emblem}) _who(
      Map<String, dynamic> message) {
    final player = message['player'];
    final secret = message['secret'];
    final name = message['name'];
    if (player is! String || player.length < 8 || player.length > 80) throw const Refusal(400, 'Missing player id.');
    if (secret is! String || secret.length < 16 || secret.length > 200) throw const Refusal(400, 'Missing secret.');
    if (name is! String) throw const Refusal(400, 'Pick a name first.');
    String? optional(Object? value) => value is String && value.length <= 60 ? value : null;
    return (
      name: name,
      player: player,
      secret: secret,
      back: optional(message['back']),
      face: optional(message['face']),
      emblem: cleanEmblem(message['emblem']),
    );
  }

  Future<void> _create(String connection, Map<String, dynamic> message) async {
    final who = _who(message);
    final now = _clock();
    // A fresh code nobody holds: claiming it only succeeds if it's free
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = newPartyCode();
      final table = engine.create(
          code: code,
          hostId: who.player,
          hostName: who.name,
          secret: who.secret,
          back: who.back,
          face: who.face,
          emblem: who.emblem,
          now: now);
      try {
        await store.put(_stateKey(code), table.toJson(), ifAbsent: true);
      } on Conflict {
        continue;
      }
      await store.put(_playersKey(code), {who.player: connection});
      await store.put(_connKey(connection), {'code': code, 'player': who.player});
      await sender.send(connection, {'k': 'joined', 'code': code, 'player': who.player});
      await sender
          .send(connection, {'k': 'snap', 'delay': 0, ...engine.view(table, who.player, now: now, withInk: true)});
      return;
    }
    throw const Refusal(503, 'Couldn\'t make a party. Try again.');
  }

  Future<void> _join(String connection, Map<String, dynamic> message) async {
    final who = _who(message);
    final code = '${message['code'] ?? ''}'.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) throw const Refusal(400, 'Party codes are six letters and numbers.');
    final frames = await _update(
        code,
        (table, now) => engine.join(table,
            id: who.player,
            name: who.name,
            secret: who.secret,
            back: who.back,
            face: who.face,
            emblem: who.emblem,
            now: now));
    await _setConnection(code, who.player, connection);
    await store.put(_connKey(connection), {'code': code, 'player': who.player});
    await sender.send(connection, {'k': 'joined', 'code': code, 'player': who.player});
    final latest = frames.$1;
    // The newcomer gets the whole table, drawing included; everyone else
    // sees them arrive
    await sender
        .send(connection, {'k': 'snap', 'delay': 0, ...engine.view(latest, who.player, now: _clock(), withInk: true)});
    await _broadcast(code, frames.$2, except: who.player, inkChanged: false);
  }

  Future<void> _move(String connection, String action, Map<String, dynamic> message) async {
    final link = await store.get(_connKey(connection));
    if (link == null) throw const Refusal(403, 'Join a party first.');
    final code = link.json['code'] as String;
    final player = link.json['player'] as String;
    final body = message['b'] is Map ? Map<String, dynamic>.from(message['b'] as Map) : <String, dynamic>{};
    var inkBefore = 0;
    final result = await _update(code, (table, now) {
      inkBefore = table.inkRevision;
      return engine.act(table, player, action, body, now: now);
    });
    await sender.send(connection, {'k': 'ack', 'n': message['n'], 'ok': true});
    await _broadcast(code, result.$2, inkChanged: result.$1.inkRevision != inkBefore);
  }

  Future<void> _disconnect(String connection) async {
    final link = await store.get(_connKey(connection));
    if (link == null) return;
    await store.delete(_connKey(connection));
    final code = link.json['code'] as String;
    final player = link.json['player'] as String;
    // A newer connection may already have taken over the seat
    if (!await _clearConnection(code, player, connection)) return;
    final result = await _update(code, (table, now) => engine.disconnect(table, player, now: now));
    await _broadcast(code, result.$2, inkChanged: false);
  }

  /// Loads the table, applies [change] and saves it, starting again if
  /// someone else saved in between. Returns the table and the frames.
  Future<(TableState, List<Frame>)> _update(String code, List<Frame> Function(TableState table, int now) change) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final stored = await store.get(_stateKey(code));
      if (stored == null) throw const Refusal(404, 'No party with that code. It may have ended.');
      final table = TableState.fromJson(stored.json);
      final frames = change(table, _clock());
      try {
        await store.put(_stateKey(code), table.toJson(), ifMatch: stored.etag);
        return (table, frames);
      } on Conflict {
        continue;
      }
    }
    throw const Refusal(503, 'The table is busy. Try again.');
  }

  Future<Map<String, String>> _connections(String code) async {
    final stored = await store.get(_playersKey(code));
    return stored == null ? {} : Map<String, String>.from(stored.json);
  }

  Future<void> _setConnection(String code, String player, String connection) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final stored = await store.get(_playersKey(code));
      final players = stored == null ? <String, dynamic>{} : Map<String, dynamic>.from(stored.json);
      players[player] = connection;
      try {
        await store.put(_playersKey(code), players, ifMatch: stored?.etag, ifAbsent: stored == null);
        return;
      } on Conflict {
        continue;
      }
    }
  }

  /// Forgets [player]'s connection if it's still [connection]. Returns
  /// whether it was.
  Future<bool> _clearConnection(String code, String player, String connection) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final stored = await store.get(_playersKey(code));
      if (stored == null || stored.json[player] != connection) return false;
      final players = Map<String, dynamic>.from(stored.json)..remove(player);
      try {
        await store.put(_playersKey(code), players, ifMatch: stored.etag);
        return true;
      } on Conflict {
        continue;
      }
    }
    return false;
  }

  /// Sends every frame to every connected player, each seeing their own
  /// view. Players whose connection has gone are treated as disconnected.
  Future<void> _broadcast(String code, List<Frame> frames, {String? except, required bool inkChanged}) async {
    if (frames.isEmpty) return;
    final connections = await _connections(code);
    final gone = <String>[];
    final now = _clock();
    await Future.wait([
      for (final MapEntry(key: player, value: connection) in connections.entries)
        if (player != except)
          () async {
            for (var i = 0; i < frames.length; i++) {
              final view =
                  engine.view(frames[i].state, player, now: now, withInk: inkChanged && i == frames.length - 1);
              if (!await sender.send(connection, {'k': 'snap', 'delay': frames[i].delayMs, ...view})) {
                gone.add(connection);
                return;
              }
            }
          }(),
    ]);
    for (final connection in gone) {
      await _disconnect(connection);
    }
  }
}
