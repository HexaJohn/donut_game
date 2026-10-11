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
    // Before the deal, leaving leaves the table
    final state = TableState.fromJson((await store.get('tables/$code/state.json'))!.json);
    expect(state.seat('player-bob'), isNull);
    expect((await store.get('tables/$code/players.json'))!.json.keys, ['player-alice']);

    // Bob comes back on a new connection, then that one silently dies
    await server.handle(_event('\$default', 'c-bob2', {'a': 'join', 'code': code, ..._hello('player-bob', 'Bob')}));
    sender.gone.add('c-bob2');
    await server.handle(_event('\$default', 'c-alice', {'a': 'chat', 'b': {'text': 'anyone?'}, 'n': 3}));
    final after = TableState.fromJson((await store.get('tables/$code/state.json'))!.json);
    expect(after.seat('player-bob'), isNull);
    expect(sender.of('c-alice', 'snap').last['players'], hasLength(1), reason: 'Alice saw Bob go');
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

  test('keeps daily counts and unique players, never who they were', () async {
    final code = await host();
    await server.handle(_event('\$default', 'c-bob', {'a': 'join', 'code': code, ..._hello('player-bob', 'Bob')}));
    await server.handle(_event('\$default', 'c-bob', {'a': 'chat', 'b': {'text': 'hi'}, 'n': 1}));
    for (final who in ['alice', 'bob']) {
      await server.handle(_event('\$default', 'c-$who', {'a': 'vote', 'b': {'vote': 'true'}, 'n': 2}));
    }
    // Bob reconnects: not a new join, not a new player
    await server.handle(_event('\$default', 'c-bob2', {'a': 'join', 'code': code, ..._hello('player-bob', 'Bob')}));

    final day = (await store.get('stats/days/1970-01-01.json'))!.json;
    expect(day, containsPair('tablesParty', 1));
    expect(day, containsPair('joinedByCode', 1));
    expect(day, containsPair('chats', 1));
    expect(day, containsPair('hands', 1));
    expect(day, containsPair('matchesStartedParty', 1));
    expect(day, containsPair('matchesWith2People', 1));

    final uniques = (await store.get('stats/uniques/1970-01-01.json'))!.json['players'] as List;
    expect(uniques, hasLength(2));
    // The same counts land in the 15-minute window too (the test clock is 1970-01-01 00:00)
    final quarter = (await store.get('stats/quarters/1970-01-01T00:00.json'))!.json;
    expect(quarter, allOf(containsPair('hands', 1), containsPair('chats', 1)));
    expect(quarter['players'], hasLength(2));
    final everything = jsonEncode([for (final key in store.keys.where((k) => k.startsWith('stats/'))) (await store.get(key))!.json]);
    expect(everything, isNot(contains('player-')), reason: 'a raw install id was stored');
    expect(everything, isNot(contains('Alice')), reason: 'a name was stored');
  });

  group('safety', () {
    test('a report is filed with the table\'s chat and acknowledged', () async {
      final code = await host();
      await server.handle(_event('\$default', 'c-bob', {'a': 'join', 'code': code, ..._hello('player-bob', 'Bob')}));
      await server.handle(_event('\$default', 'c-bob', {'a': 'chat', 'b': {'text': 'go away loser'}, 'n': 1}));
      await server.handle(_event('\$default', 'c-alice', {
        'a': 'report',
        'b': {'player': 'player-bob', 'reason': 'harassment', 'note': 'rude'},
        'n': 9
      }));
      expect(sender.of('c-alice', 'ack').last, containsPair('ok', true));
      final key = store.keys.singleWhere((key) => key.startsWith('reports/'));
      final report = (await store.get(key))!.json;
      expect(report['reason'], 'harassment');
      expect(report['reported'], {'id': 'player-bob', 'name': 'Bob'});
      expect((report['chat'] as List).single['text'], 'go away loser');
      expect(jsonEncode(report), isNot(contains('secret')));
    });

    test('a banned player can\'t host, join or matchmake until the ban ends', () async {
      final code = await host();
      await store.put('bans/player-bob.json', {'until': now + 100000, 'reason': 'harassment'});
      for (final message in [
        {'a': 'create'},
        {'a': 'join', 'code': code},
        {'a': 'matchmake'},
      ]) {
        await server.handle(_event('\$default', 'c-bob', {...message, ..._hello('player-bob', 'Bob')}));
      }
      expect(sender.of('c-bob', 'joined'), isEmpty);
      expect(sender.of('c-bob', 'error').last['message'], contains('can\'t play online until'));
      now += 200000;
      await server.handle(_event('\$default', 'c-bob', {'a': 'join', 'code': code, ..._hello('player-bob', 'Bob')}));
      expect(sender.of('c-bob', 'joined'), hasLength(1), reason: 'the ban ran out');
    });

    test('matchmaking keeps players away from people they blocked, without delisting the table', () async {
      await server.handle(_event('\$default', 'c-ann', {'a': 'matchmake', ..._hello('player-ann', 'Ann')}));
      final annTable = sender.of('c-ann', 'joined').single['code'];
      await server.handle(_event('\$default', 'c-ben', {
        'a': 'matchmake',
        'blocked': ['player-ann'],
        ..._hello('player-ben', 'Ben')
      }));
      expect(sender.of('c-ben', 'joined').single['code'], isNot(annTable));
      await server.handle(_event('\$default', 'c-cat', {'a': 'matchmake', ..._hello('player-cat', 'Cat')}));
      expect(sender.of('c-cat', 'joined').single['code'], annTable, reason: 'Ann\'s table was still listed');
    });
  });

  test('usage reports add to the day\'s app counts, keeping only well-formed tallies', () async {
    await server.handle(_event('\$default', 'c-app', {
      'a': 'usage',
      'player': 'install-0001',
      'n': 4,
      'events': {'campaign.bakery.1.casual.won': 2, 'session.minutes': 14, 'bad name!': 3, 'negative': -5, 'huge': 999999999},
    }));
    expect(sender.of('c-app', 'ack').single, containsPair('ok', true));
    final day = (await store.get('stats/days/1970-01-01.json'))!.json;
    expect(day, {'app.campaign.bakery.1.casual.won': 2, 'app.session.minutes': 14});
    expect((await store.get('stats/uniques/1970-01-01.json'))!.json['players'], hasLength(1));
  });
}
