import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:donut_game/net/party_client.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_server/donut_server.dart';
import 'package:flutter_test/flutter_test.dart';

/// The party server as it runs in Lambda, behind a local WebSocket server
/// standing in for API Gateway: each socket gets a connection id, and every
/// message becomes an event.
class LocalGateway implements Sender {
  late final HttpServer _http;
  late final PartyServer server = PartyServer(store: MemoryStore(), sender: this);
  final Map<String, WebSocket> _sockets = {};
  var _next = 0;

  String get url => 'ws://localhost:${_http.port}';

  Future<void> start() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      final id = 'conn${_next++}';
      _sockets[id] = socket;
      // One event at a time, like a concurrency of one
      var queue = Future<void>.value();
      void event(String route, [String? body]) => queue = queue.then((_) => server.handle({
            'requestContext': {'connectionId': id, 'routeKey': route},
            if (body != null) 'body': body,
          }));
      event(r'$connect');
      socket.listen((body) => event(r'$default', body as String), onDone: () {
        _sockets.remove(id);
        event(r'$disconnect');
      });
    });
  }

  Future<void> stop() => _http.close(force: true);

  @override
  Future<bool> send(String connectionId, Map<String, dynamic> message) async {
    final socket = _sockets[connectionId];
    if (socket == null) return false;
    socket.add(jsonEncode(message));
    return true;
  }
}

/// A second player, speaking the protocol directly.
class RawPlayer {
  RawPlayer._(this.socket) {
    socket.listen((raw) => messages.add(Map<String, dynamic>.from(jsonDecode(raw as String) as Map)));
  }

  static Future<RawPlayer> connect(String url) async => RawPlayer._(await WebSocket.connect(url));

  final WebSocket socket;
  final List<Map<String, dynamic>> messages = [];

  void send(Map<String, dynamic> message) => socket.add(jsonEncode(message));
}

Future<void> until(bool Function() condition, {String reason = ''}) async {
  for (var i = 0; i < 200; i++) {
    if (condition()) return;
    await Future.delayed(const Duration(milliseconds: 25));
  }
  fail('timed out waiting: $reason');
}

void main() {
  // The controller watches the app's lifecycle; real sockets stay allowed
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  late LocalGateway gateway;
  setUp(() async {
    gateway = LocalGateway();
    await gateway.start();
  });
  tearDown(() => gateway.stop());

  test('host a party, a friend joins by code, and the table deals', () async {
    final host = PartyController(
        nickname: 'Alice', url: gateway.url, playerId: 'alice-device', secret: 'alice-secret-0123456789');
    host.start();
    await until(() => host.partyCode != null, reason: 'the party was made');
    final code = host.partyCode!;
    expect(host.label, 'Party $code');
    await until(() => host.localPlayer != null, reason: 'the host was seated');
    expect(host.canRestart, isTrue);
    expect(host.canManageBots, isTrue);

    final friend = await RawPlayer.connect(gateway.url);
    friend.send({
      'a': 'join',
      'code': code.toLowerCase(),
      'name': 'Bob',
      'player': 'bob-device',
      'secret': 'bob-secret-0123456789ab',
    });
    await until(() => host.game.players.length == 2, reason: 'Bob appeared at the host');
    expect(friend.messages.first, {'k': 'joined', 'code': code, 'player': 'bob-device'});

    // The host's menu adds a bot
    expect(await host.send('addBot', {}), isTrue);
    await until(() => host.game.players.length == 3, reason: 'the bot sat down');

    await host.deal();
    friend.send({'a': 'vote', 'b': {'vote': 'true'}, 'n': 1});
    await until(() => host.game.handNumber == 1 && host.localPlayer!.hand.cards.value.length == cardsPerHand,
        reason: 'the hand was dealt');
    // The host sees their own cards and only the backs of Bob's
    expect(host.localPlayer!.hand.cards.value.every((card) => !card.hidden), isTrue);
    final bob = host.game.players.firstWhere((player) => player.name == 'Bob');
    expect(bob.hand.cards.value.every((card) => card.hidden), isTrue);
    expect(host.canManageBots, isFalse, reason: 'bots only change between matches');

    // A move out of turn is refused, not applied
    if (!host.isLocalTurn) expect(await host.send('swapvote', {}), isFalse);

    host.dispose();
    await friend.socket.close();
  });

  test('a wrong code says so and stops trying', () async {
    final guest = PartyController(
        code: 'ZZZZZZ', nickname: 'Carol', url: gateway.url, playerId: 'carol-device', secret: 'carol-secret-0123456789');
    guest.start();
    await until(() => guest.error.value != null, reason: 'an error was shown');
    expect(guest.error.value, contains('No party'));
    expect(guest.partyCode, isNull);
    guest.dispose();
  });
}
