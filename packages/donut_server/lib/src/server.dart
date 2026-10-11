import 'dart:convert';
import 'dart:io';

import 'package:donut_engine/donut_engine.dart';

import 'aws.dart';
import 'stats.dart';
import 'store.dart';

/// Who's asking to sit down: what create, join and matchmake carry.
typedef Who = ({String name, String player, String secret, String? back, String? face, Map<String, dynamic>? emblem});

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
///   open/<created>-<CODE>.json  a public table matchmaking can fill,
///                               oldest first
///
/// Client messages are {"a": action, ...}: "create", "join" (with "code")
/// and "matchmake" carry name, back, face, emblem, player (a device id) and
/// secret; moves carry "b" (the body
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

  /// Usage numbers this event adds, saved once it's handled.
  late final Stats stats = Stats(store, log: log);

  static String _stateKey(String code) => 'tables/$code/state.json';
  static String _playersKey(String code) => 'tables/$code/players.json';
  static String _connKey(String connection) => 'conns/$connection.json';
  static String _openKey(TableState table) => 'open/${'${table.createdAt}'.padLeft(15, '0')}-${table.code}.json';
  static String? _codeOfOpenKey(String key) => RegExp(r'-([A-Z0-9]{6})\.json$').firstMatch(key)?.group(1);

  /// Handles one API Gateway WebSocket event.
  Future<void> handle(Map<String, dynamic> event) async {
    final context = Map<String, dynamic>.from(event['requestContext'] as Map);
    final connection = context['connectionId'] as String;
    _log(connection, '${context['routeKey']}', event['body'] as String?);
    try {
      await _route(connection, context, event);
    } finally {
      await stats.flush(_clock());
    }
  }

  Future<void> _route(String connection, Map<String, dynamic> context, Map<String, dynamic> event) async {
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
          final code = '${message['code'] ?? ''}'.trim().toUpperCase();
          if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code))
            throw const Refusal(400, 'Party codes are six letters and numbers.');
          await _join(connection, _who(message), code);
        case 'matchmake':
          await _matchmake(connection, _who(message));
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
      if (action == 'create' || action == 'join' || action == 'matchmake') {
        await sender.send(connection, {'k': 'error', 'message': refusal.message});
      }
    }
  }

  Who _who(Map<String, dynamic> message) {
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

  Future<void> _create(String connection, Map<String, dynamic> message) => _host(connection, _who(message));

  /// Opens a new table with this player as host; [public] lists it for
  /// matchmaking.
  Future<void> _host(String connection, Who who, {bool public = false}) async {
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
          public: public,
          now: now);
      try {
        await store.put(_stateKey(code), table.toJson(), ifAbsent: true);
      } on Conflict {
        continue;
      }
      if (table.openToMatchmaking) await store.put(_openKey(table), {'code': code});
      stats
        ..count(public ? 'tablesPublic' : 'tablesParty')
        ..sawPlayer(who.player);
      await store.put(_playersKey(code), {who.player: connection});
      await store.put(_connKey(connection), {'code': code, 'player': who.player});
      await sender.send(connection, {'k': 'joined', 'code': code, 'player': who.player});
      await sender
          .send(connection, {'k': 'snap', 'delay': 0, ...engine.view(table, who.player, now: now, withInk: true)});
      return;
    }
    throw const Refusal(503, 'Couldn\'t make a party. Try again.');
  }

  /// Sends the player to the oldest public table with room, or opens a new
  /// one for others to be sent to.
  Future<void> _matchmake(String connection, Who who) async {
    for (final key in await store.list('open/', limit: 10)) {
      final code = _codeOfOpenKey(key);
      if (code == null) continue;
      try {
        await _join(connection, who, code, matchmaking: true);
        return;
      } on Refusal {
        // Started, full or abandoned since it was listed
        await store.delete(key);
      }
    }
    stats.count('matchmakeOpened');
    await _host(connection, who, public: true);
  }

  /// Seats the player at [code]. [matchmaking] only takes a table that's
  /// still open to strangers.
  Future<void> _join(String connection, Who who, String code, {bool matchmaking = false}) async {
    var returning = false;
    final frames = await _update(code, (table, now) {
      returning = table.seat(who.player) != null;
      if (matchmaking && !table.openToMatchmaking && table.seat(who.player) == null) {
        throw const Refusal(409, 'That table filled up.');
      }
      return engine.join(table,
          id: who.player,
          name: who.name,
          secret: who.secret,
          back: who.back,
          face: who.face,
          emblem: who.emblem,
          now: now);
    });
    stats.sawPlayer(who.player);
    if (!returning) stats.count(matchmaking ? 'joinedByMatchmaking' : 'joinedByCode');
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
    if (action == 'chat') stats.count('chats');
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
    stats.count(result.$1.seat(player) == null ? 'leftBetweenHands' : 'droppedMidHand');
    await _broadcast(code, result.$2, inkChanged: false);
  }

  /// Loads the table, applies [change] and saves it, starting again if
  /// someone else saved in between. Returns the table and the frames.
  Future<(TableState, List<Frame>)> _update(String code, List<Frame> Function(TableState table, int now) change) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final stored = await store.get(_stateKey(code));
      if (stored == null) throw const Refusal(404, 'No party with that code. It may have ended.');
      final table = TableState.fromJson(stored.json);
      final wasOpen = table.openToMatchmaking;
      final handBefore = table.handNumber;
      final wasOver = table.phase == Phase.over;
      final frames = change(table, _clock());
      try {
        await store.put(_stateKey(code), table.toJson(), ifMatch: stored.etag);
        // Keep the matchmaking listing in step with the table
        if (table.openToMatchmaking && !wasOpen) await store.put(_openKey(table), {'code': code});
        if (!table.openToMatchmaking && wasOpen) await store.delete(_openKey(table));
        _countProgress(table, handBefore: handBefore, wasOver: wasOver);
        return (table, frames);
      } on Conflict {
        continue;
      }
    }
    throw const Refusal(503, 'The table is busy. Try again.');
  }

  /// Hands dealt and matches started or finished by the change just saved.
  void _countProgress(TableState table, {required int handBefore, required bool wasOver}) {
    if (table.handNumber > handBefore) {
      stats.count('hands', table.handNumber - handBefore);
      if (handBefore == 0) {
        final humans = table.seats.where((seat) => seat.human).length;
        stats
          ..count(table.public ? 'matchesStartedPublic' : 'matchesStartedParty')
          ..count('matchesWith${humans}People');
      }
    }
    if (table.phase == Phase.over && !wasOver) {
      stats.count('matchesFinished');
      final started = table.matchStartedAt, ended = table.matchEndedAt;
      if (started != null && ended != null) stats.count('matchMinutes', ((ended - started) / 60000).round());
    }
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
