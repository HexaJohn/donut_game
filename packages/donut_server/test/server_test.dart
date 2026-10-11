import 'dart:convert';
import 'dart:math';

import 'package:donut_engine/donut_engine.dart';
import 'package:donut_server/donut_server.dart';
import 'package:test/test.dart';

/// Records what each connection was sent; connections in [gone] have closed.
class FakeSender implements Sender {
  final Map<String, List<Map<String, dynamic>>> sent = {};
  final Set<String> gone = {};

  @override
  Future<bool> send(String connectionId, Map<String, dynamic> message) async {
    if (gone.contains(connectionId)) return false;
    sent.putIfAbsent(connectionId, () => []).add(jsonDecode(jsonEncode(message)) as Map<String, dynamic>);
    return true;
  }

  List<Map<String, dynamic>> of(String connection, String kind) =>
      [for (final m in sent[connection] ?? <Map<String, dynamic>>[]) if (m['k'] == kind) m];
}

/// A store whose next write fails as if someone else got there first.
class RacyStore extends MemoryStore {
  bool raceNext = false;

  @override
  Future<String> put(String key, Map<String, dynamic> json, {String? ifMatch, bool ifAbsent = false}) async {
    if (raceNext && ifMatch != null && key.endsWith('state.json')) {
      raceNext = false;
      throw const Conflict();
    }
    return super.put(key, json, ifMatch: ifMatch, ifAbsent: ifAbsent);
  }
}

Map<String, dynamic> _event(String route, String connection, [Map<String, dynamic>? body]) => {
      'requestContext': {'routeKey': route, 'connectionId': connection, 'domainName': 'x', 'stage': 'live'},
      if (body != null) 'body': jsonEncode(body),
    };

Map<String, dynamic> _hello(String player, String name) =>
    {'player': player, 'name': name, 'secret': '$player-secret-0123456789'};

void main() {
  late RacyStore store;
  late FakeSender sender;
  late PartyServer server;
  var now = 1000;

  setUp(() {
    store = RacyStore();
    sender = FakeSender();
    now = 1000;
    server = PartyServer(
      store: store,
      sender: sender,
      engine: DonutEngine(random: Random(3), botMs: 0, swapMs: 0, trickMs: 0, dealMs: 0),
      clock: () => now += 10,
    );
  });

  Future<String> host() async {
    await server.handle(_event('\$default', 'c-alice', {'a': 'create', ..._hello('player-alice', 'Alice')}));
    return sender.of('c-alice', 'joined').single['code'] as String;
  }

  test('hosting gives a party code and the table', () async {
    final code = await host();
    expect(code, matches(RegExp(r'^[A-Z0-9]{6}$')));
    final snap = sender.of('c-alice', 'snap').single;
    expect((snap['players'] as List).single['username'], 'Alice');
    expect(snap['game']['code'], code);
    expect(store.keys, containsAll(['tables/$code/state.json', 'tables/$code/players.json', 'conns/c-alice.json']));
  });

  test('joining by code; a wrong code says so', () async {
    final code = await host();
    await server.handle(_event('\$default', 'c-bob', {'a': 'join', 'code': code.toLowerCase(), ..._hello('player-bob', 'Bob')}));
    expect(sender.of('c-bob', 'joined').single['code'], code);
    expect((sender.of('c-alice', 'snap').last['players'] as List).map((p) => p['username']), ['Alice', 'Bob']);

    await server.handle(_event('\$default', 'c-eve', {'a': 'join', 'code': 'ZZZZZZ', ..._hello('player-eve', 'Eve')}));
    expect(sender.of('c-eve', 'error').single['message'], contains('No party'));
  });

  test('moves deal the cards, and each player sees only their own', () async {
    final code = await host();
    await server.handle(_event('\$default', 'c-bob', {'a': 'join', 'code': code, ..._hello('player-bob', 'Bob')}));
    await server.handle(_event('\$default', 'c-alice', {'a': 'vote', 'b': {'vote': 'true'}, 'n': 1}));
    await server.handle(_event('\$default', 'c-bob', {'a': 'vote', 'b': {'vote': 'true'}, 'n': 1}));
    expect(sender.of('c-bob', 'ack').last, containsPair('ok', true));
    final view = sender.of('c-bob', 'snap').last;
    final players = (view['players'] as List).cast<Map>();
    expect(players, hasLength(3), reason: 'a bot makes three');
    final mine = players.firstWhere((p) => p['pid'] == 'player-bob')['cards'] as List;
    final alices = players.firstWhere((p) => p['pid'] == 'player-alice')['cards'] as List;
    expect(mine.every((c) => (c as Map).containsKey('suit')), isTrue);
    expect(alices.every((c) => !(c as Map).containsKey('suit')), isTrue);
    expect(jsonEncode(sender.sent), isNot(contains('player-alice-secret')), reason: 'a secret leaked');
  });

  test('a stranger\'s connection can\'t move', () async {
    await host();
    await server.handle(_event('\$default', 'c-mallory', {'a': 'chat', 'b': {'text': 'hi'}, 'n': 9}));
    expect(sender.of('c-mallory', 'ack').single, allOf(containsPair('ok', false), containsPair('status', 403)));
  });

  test('two moves at once: the loser tries again and still lands', () async {
    await host();
    store.raceNext = true;
    await server.handle(_event('\$default', 'c-alice', {'a': 'chat', 'b': {'text': 'still here'}, 'n': 2}));
    expect(sender.of('c-alice', 'ack').last, containsPair('ok', true));
    expect((sender.of('c-alice', 'snap').last['game']['chat'] as List).last['text'], 'still here');
  });

  test('leaving, and a dead connection, both count as disconnecting', () async {
    final code = await host();
    await server.handle(_event('\$default', 'c-bob', {'a': 'join', 'code': code, ..._hello('player-bob', 'Bob')}));
    await server.handle(_event('\$disconnect', 'c-bob'));
    final state = TableState.fromJson((await store.get('tables/$code/state.json'))!.json);
    expect(state.seat('player-bob')!.connected, isFalse);
    expect((await store.get('tables/$code/players.json'))!.json.keys, ['player-alice']);

    // Bob comes back on a new connection, then that one silently dies
    await server.handle(_event('\$default', 'c-bob2', {'a': 'join', 'code': code, ..._hello('player-bob', 'Bob')}));
    sender.gone.add('c-bob2');
    await server.handle(_event('\$default', 'c-alice', {'a': 'chat', 'b': {'text': 'anyone?'}, 'n': 3}));
    final after = TableState.fromJson((await store.get('tables/$code/state.json'))!.json);
    expect(after.seat('player-bob')!.connected, isFalse);
  });

  test('signs requests the way AWS documents', () {
    // get-vanilla, from AWS's Signature Version 4 test suite
    final signer = SigV4(const AwsCredentials('AKIDEXAMPLE', 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY'),
        region: 'us-east-1', service: 'service');
    final headers = signer.sign(
        method: 'GET', host: 'example.amazonaws.com', path: '/', time: DateTime.utc(2015, 8, 30, 12, 36));
    expect(headers['authorization'],
        'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, '
        'SignedHeaders=host;x-amz-date, Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31');
  });

  group('matchmaking', () {
    Future<String> matchmake(String who) async {
      await server.handle(_event('\$default', 'c-$who', {'a': 'matchmake', ..._hello('player-$who', who)}));
      return sender.of('c-$who', 'joined').single['code'] as String;
    }

    Iterable<String> listed() => store.keys.where((key) => key.startsWith('open/'));

    test('fills the oldest public table, up to four people, then opens another', () async {
      final first = await matchmake('ann');
      expect(listed(), hasLength(1), reason: 'nobody was waiting, so a public table opened');
      expect(sender.of('c-ann', 'snap').last['game']['public'], isTrue);
      final second = await matchmake('ben');
      expect(second, first);
      await matchmake('cat');
      await matchmake('dan');
      expect(listed(), isEmpty, reason: 'four people: no longer listed');
      final fifth = await matchmake('eve');
      expect(fifth, isNot(first));
      expect(listed(), hasLength(1));
    });

    test('a table leaves the listing when it deals or empties', () async {
      final code = await matchmake('ann');
      await matchmake('ben');
      for (final who in ['ann', 'ben']) {
        await server.handle(_event('\$default', 'c-$who', {'a': 'vote', 'b': {'vote': 'true'}, 'n': 1}));
      }
      expect(listed(), isEmpty, reason: 'the match started');
      expect(await matchmake('cat'), isNot(code));
      // Cat leaves before anyone joins: an empty table isn't offered
      await server.handle(_event('\$disconnect', 'c-cat'));
      expect(listed(), isEmpty);
      expect(await matchmake('dan'), isNot(code));
    });

    test('a stale listing is skipped and cleared', () async {
      final code = await matchmake('ann');
      // The table moved on without its listing being cleared
      final state = (await store.get('tables/$code/state.json'))!;
      await store.put('tables/$code/state.json', {...state.json, 'handNumber': 1});
      final next = await matchmake('ben');
      expect(next, isNot(code));
      expect(listed().where((key) => key.contains(code)), isEmpty);
    });

    test('parties with a code are never matchmade into', () async {
      final code = await host();
      expect(listed(), isEmpty);
      expect(await matchmake('ben'), isNot(code));
    });
  });
}
