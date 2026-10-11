import 'dart:async';

import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/net/match_controllers.dart';
import 'package:donut_game/net/match_link.dart';
import 'package:donut_game/net/table_host.dart';
import 'package:donut_game/res/resources.dart';
import 'package:flutter_test/flutter_test.dart';

/// A match passed around in memory. [sent] records every outgoing message.
class FakeLink extends MatchLink {
  FakeLink(this.localId, this.peers);

  @override
  final String localId;

  @override
  final List<MatchPeer> peers;

  final _events = StreamController<LinkEvent>.broadcast();
  final List<(String?, Map<String, dynamic>)> sent = [];
  bool closed = false;

  @override
  Stream<LinkEvent> get events => _events.stream;

  /// Something arriving from another player.
  void receive(LinkEvent event) => _events.add(event);

  @override
  Future<void> send(Map<String, dynamic> message, {String? to}) async {
    // Through the real codec, so anything that can't travel fails here
    sent.add((to, decodeMessage(encodeMessage(message))));
  }

  @override
  Future<void> close() async => closed = true;

  Iterable<Map<String, dynamic>> ofKind(String kind) => sent.map((s) => s.$2).where((m) => m['k'] == kind);
}

const _alice = MatchPeer('A:alice', 'Alice');
const _bob = MatchPeer('B:bob', 'Bob');

/// Seats Alice and Bob at a fresh table, ready to deal.
TableHost _table() {
  final table = TableHost();
  final game = table.game
    ..abort()
    ..playerDB.clear()
    ..chat.value = [];
  table.join(_alice.id, _alice.name);
  table.join(_bob.id, _bob.name);
  game.addBot();
  game.newMatch();
  return table;
}

Future<void> _until(bool Function() done, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('never happened');
    await Future.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  tearDown(() => Game().abort());

  group('table host', () {
    test('deals once every human is ready, bots always are', () {
      final table = _table();
      expect(table.act(_alice.id, 'vote', {'vote': 'true'}).ok, isTrue);
      expect(table.game.state.value, GameState.waitingToDeal);
      table.act(_bob.id, 'vote', {'vote': 'true'});
      expect(table.game.state.value, isNot(GameState.waitingToDeal));
    });

    test('refuses plays out of turn and moves from strangers', () {
      final table = _table();
      expect(table.act(_alice.id, 'play', {'card': 0}).status, 409);
      expect(table.act('nobody', 'chat', {'text': 'hi'}).ok, isFalse);
      expect(table.act(_alice.id, 'teleport', {}).status, 400);
      expect(table.act(_alice.id, 'chat', {'text': 'hi'}).ok, isTrue);
      expect(table.game.chat.value.last.text, 'hi');
    });

    test('a departed player becomes a bot and the table carries on', () async {
      final table = _table();
      table.act(_alice.id, 'vote', {'vote': 'true'});
      // Bob leaves before voting; his seat shouldn't hold the deal up
      table.replaceWithBot(_bob.id);
      expect(table.player(_bob.id)!.human, isFalse);
      expect(table.game.state.value, isNot(GameState.waitingToDeal));
    });

    test('a whole table travels as one small message', () {
      final table = _table();
      for (var i = 0; i < 200; i++) {
        table.act(_alice.id, 'chat', {'text': 'Message number $i, padded out like a real chat line'});
      }
      final snapshot = {'k': 'snap', 'mode': 'donut', 'players': table.playersJson(), 'game': table.gameJson()};
      final bytes = encodeMessage(snapshot);
      expect(decodeMessage(bytes)['players'], hasLength(3));
      // Game Center's reliable messages top out around 87 KB
      expect(bytes.length, lessThan(20 * 1024), reason: '${bytes.length} bytes');
    });
  });

  group('match host', () {
    test('seats everyone uniquely, answers moves and keeps them posted', () async {
      final link = FakeLink(_alice.id, [_alice, _bob, const MatchPeer('C:alice2', 'Alice')]);
      expect(link.isHost, isTrue);
      final host = MatchHostController(link);
      addTearDown(host.dispose);

      final names = host.game.players.map((p) => p.name).toSet();
      expect(names, containsAll(['Alice', 'Bob', 'Alice 2']));
      expect(host.localPlayer!.id, _alice.id);

      link.receive(LinkMessage(_bob.id, {'k': 'act', 'a': 'chat', 'b': {'text': 'hello'}, 'n': 7}));
      await _until(() => link.ofKind('ack').isNotEmpty);
      final ack = link.sent.firstWhere((s) => s.$2['k'] == 'ack');
      expect(ack.$1, _bob.id);
      expect(ack.$2['n'], 7);
      expect(ack.$2['ok'], isTrue);

      final snap = link.ofKind('snap').last;
      expect((snap['game']['chat'] as List).last['text'], 'hello');
    });

    test('two humans get a bot, since Donut needs three', () {
      final host = MatchHostController(FakeLink(_alice.id, [_alice, _bob]));
      addTearDown(host.dispose);
      expect(host.game.players, hasLength(3));
      expect(host.game.players.where((p) => !p.human), hasLength(1));
    });
  });

  group('match client', () {
    test('rebuilds the host\'s table, finds its seat and sends moves to the host', () async {
      // What the host would send, made the same way
      final table = _table();
      final snapshot = decodeMessage(encodeMessage(
          {'k': 'snap', 'mode': 'donut', 'players': table.playersJson(), 'game': table.gameJson()}));

      final link = FakeLink(_bob.id, [_alice, _bob]);
      expect(link.hostId, _alice.id);
      final client = MatchClientController(link);
      addTearDown(client.dispose);
      client.start();
      expect(link.ofKind('hello').single, containsPair('k', 'hello'));
      expect(client.game.players, isEmpty);

      link.receive(LinkMessage(_alice.id, snapshot));
      await _until(() => client.localPlayer != null);
      expect(client.localPlayer!.name, 'Bob');
      expect(client.game.players, hasLength(3));

      // A move goes to the host and waits for its answer
      final sending = client.send('chat', {'text': 'hi'});
      await _until(() => link.ofKind('act').isNotEmpty);
      final act = link.sent.lastWhere((s) => s.$2['k'] == 'act');
      expect(act.$1, _alice.id);
      link.receive(LinkMessage(_alice.id, {'k': 'ack', 'n': act.$2['n'], 'ok': true}));
      expect(await sending, isTrue);

      // Only the host speaks for the table
      link.receive(const LinkMessage('B:bob', {'k': 'snap', 'mode': 'donut', 'players': [], 'game': {}}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(client.game.players, hasLength(3));

      link.receive(LinkPeerLeft(_alice.id));
      await _until(() => client.error.value != null);
      expect(client.error.value, contains('host left'));
    });
  });
}
