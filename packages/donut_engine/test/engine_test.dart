import 'dart:convert';
import 'dart:math';

import 'package:donut_engine/donut_engine.dart';
import 'package:test/test.dart';

const _aliceSecret = 'alice-secret-0123456789';
const _bobSecret = 'bob-secret-0123456789ab';

/// Every card is somewhere, exactly once.
void _expectAllCards(TableState table) {
  final cards = [
    ...table.deck,
    ...table.discard,
    ...table.trick,
    for (final seat in table.seats) ...seat.hand,
  ];
  expect(cards, hasLength(52), reason: 'cards went missing or doubled');
  expect(cards.map((card) => card.faceId).toSet(), hasLength(52));
  for (final seat in table.seats) {
    expect(seat.hand.length, lessThanOrEqualTo(cardsPerHand), reason: '${seat.name} holds too many');
  }
}

/// A table with Alice hosting and Bob joined.
(DonutEngine, TableState) _table({int seed = 1}) {
  final engine = DonutEngine(random: Random(seed));
  final table = engine.create(code: 'ABC234', hostId: 'alice', hostName: 'Alice', secret: _aliceSecret, now: 0);
  engine.join(table, id: 'bob', name: 'Bob', secret: _bobSecret, now: 0);
  return (engine, table);
}

/// What the human whose turn it is would do, decided by a bot on their
/// behalf, sent through the same moves a player's app sends.
List<Frame> _humanTurn(DonutEngine engine, TableState table, int now) {
  final seat = table.seats[table.active];
  final brain = Brain<TableCard>(BotSkill.shark, random: Random(now));
  if (table.phase == Phase.swap) {
    final view = _View(table, seat);
    if (brain.shouldFold(seat.hand, view) && table.suddenDeath.isEmpty && seat.folds < maxConsecutiveFolds) {
      return engine.act(table, seat.id, 'fold', {}, now: now);
    }
    for (final card in brain.chooseSwaps(seat.hand, table.trump, seat.swaps)) {
      engine.act(table, seat.id, 'swap', {'swap': seat.hand.indexOf(card)}, now: now);
    }
    return engine.act(table, seat.id, 'swapvote', {}, now: now);
  }
  final card = brain.chooseCard(seat.hand, _View(table, seat));
  return engine.act(table, seat.id, 'play', {'card': seat.hand.indexOf(card)}, now: now);
}

class _View implements BrainTable<TableCard> {
  _View(this.table, this.seat);

  final TableState table;
  final Seat seat;

  @override
  Suit get trump => table.trump;
  @override
  List<TableCard> get trick => table.trick;
  @override
  Suit? get lead => table.trick.isEmpty ? null : table.lead;
  @override
  bool get canFold => table.suddenDeath.isEmpty && seat.folds < maxConsecutiveFolds;
  @override
  int get swapsLeft => seat.swaps;
  @override
  int get stillToPlay => table.seats.where((s) => !s.skip).length - table.trick.length - 1;
  @override
  Iterable<PlayingCard> get revealed => const [];
  @override
  bool playedByHuman(TableCard card) => false;
  @override
  bool get humanStillToPlay => false;
}

void main() {
  group('joining', () {
    test('seats players under unique names and keeps seats for their owners', () {
      final (engine, table) = _table();
      expect(table.seats.map((s) => s.name), ['Alice', 'Bob']);
      engine.join(table, id: 'bob2', name: 'bob', secret: 'other-secret-0123456789', now: 0);
      expect(table.seats.last.name, 'bob 2');
      expect(() => engine.join(table, id: 'bob', name: 'Bob', secret: 'stolen-secret-012345678', now: 0),
          throwsA(isA<Refusal>().having((r) => r.status, 'status', 403)));
      expect(() => engine.join(table, id: 'eve', name: 'Eve', secret: 'short', now: 0),
          throwsA(isA<Refusal>().having((r) => r.status, 'status', 400)));
      // Bob dropping out and coming back keeps his seat
      engine.disconnect(table, 'bob', now: 1);
      expect(table.seat('bob')!.connected, isFalse);
      engine.join(table, id: 'bob', name: 'Bob', secret: _bobSecret, now: 2);
      expect(table.seat('bob')!.connected, isTrue);
    });

    test('nobody new joins once the match has started', () {
      final (engine, table) = _table();
      engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: 1);
      engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: 2);
      expect(table.handNumber, 1);
      expect(() => engine.join(table, id: 'carol', name: 'Carol', secret: 'carol-secret-0123456789', now: 3),
          throwsA(isA<Refusal>().having((r) => r.status, 'status', 409)));
    });
  });

  group('playing', () {
    test('waits for every human to be ready, then fills the table with a bot and deals', () {
      final (engine, table) = _table();
      engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: 1);
      expect(table.handNumber, 0);
      expect(table.status, GameState.waitingToDeal);
      final frames = engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: 2);
      expect(table.seats, hasLength(3), reason: 'a bot makes up the three Donut needs');
      expect(table.handNumber, 1);
      expect(frames.any((f) => f.state.status == GameState.dealing), isTrue);
      expect(table.seats.where((s) => !s.skip).every((s) => s.hand.length == cardsPerHand), isTrue);
      _expectAllCards(table);
    });

    test('a whole match plays out through the moves players send', () {
      for (final seed in [1, 2, 3]) {
        final (engine, table) = _table(seed: seed);
        engine.act(table, 'alice', 'addBot', {}, now: 0);
        var now = 1;
        var moves = 0;
        while (table.phase != Phase.over) {
          expect(moves++, lessThan(5000), reason: 'the match never ended');
          List<Frame> frames;
          if (table.phase == Phase.lobby) {
            frames = [
              ...engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: now),
              ...engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: now),
            ];
          } else {
            frames = _humanTurn(engine, table, now);
          }
          for (final frame in frames) {
            _expectAllCards(frame.state);
          }
          // What players were last shown is exactly what was saved
          if (frames.isNotEmpty) {
            expect(jsonEncode(frames.last.state.toJson()), jsonEncode(table.toJson()),
                reason: 'the last frame left players behind the table');
          }
          now += 1000;
        }
        expect(table.champion, isNotNull);
        expect(table.seat(table.champion!)!.score, lessThanOrEqualTo(0));
        expect(table.handNumber, greaterThan(1));
      }
    });

    test('refuses moves out of turn, off suit, or from the wrong player', () {
      final (engine, table) = _table(seed: 4);
      engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: 1);
      engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: 2);
      final waiting = table.seats[table.active];
      final other = table.seats.firstWhere((s) => s.human && s != waiting);
      expect(() => engine.act(table, other.id, 'swapvote', {}, now: 3), throwsA(isA<Refusal>()));
      expect(() => engine.act(table, waiting.id, 'play', {'card': 0}, now: 3),
          throwsA(isA<Refusal>().having((r) => r.status, 'status', 409)));
      expect(() => engine.act(table, 'bob', 'newMatch', {}, now: 3),
          throwsA(isA<Refusal>().having((r) => r.status, 'status', 403)));
      expect(() => engine.act(table, 'nobody', 'chat', {'text': 'hi'}, now: 3), throwsA(isA<Refusal>()));

      // Play on until a human must follow suit, and try not to
      var now = 4;
      for (var i = 0; i < 200 && table.phase != Phase.over; i++) {
        final seat = table.seats[table.active];
        if (table.phase == Phase.play && seat.human && table.trick.isNotEmpty) {
          final offSuit = seat.hand.indexWhere((c) => c.suit != table.lead);
          if (offSuit >= 0 && seat.hand.any((c) => c.suit == table.lead)) {
            expect(() => engine.act(table, seat.id, 'play', {'card': offSuit}, now: now),
                throwsA(isA<Refusal>().having((r) => r.message, 'message', contains('follow'))));
            return;
          }
        }
        if (table.phase == Phase.lobby) {
          engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: now);
          engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: now);
        } else {
          _humanTurn(engine, table, now);
        }
        now += 1000;
      }
    });

    test('a finished trick is shown before it is cleared', () {
      final (engine, table) = _table(seed: 5);
      final frames = [
        ...engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: 1),
        ...engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: 2),
      ];
      var now = 3;
      while (!frames.any((f) => f.state.status == GameState.waitingForNextRound)) {
        frames.addAll(_humanTurn(engine, table, now++));
      }
      final shown = frames.indexWhere((f) => f.state.status == GameState.waitingForNextRound);
      expect(frames[shown].state.trick, hasLength(frames[shown].state.seats.where((s) => !s.skip).length));
      expect(frames[shown].state.seats.any((s) => s.winner), isTrue);
      expect(frames[shown + 1].state.trick, isEmpty);
      expect(frames[shown + 1].delayMs, engine.trickMs);
    });

    test('dropping out and coming back mid-swap leaves everyone on the saved table', () {
      // The S8 bug: the last swapper's move handed play to a human without a frame
      final (engine, table) = _table(seed: 9);
      engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: 1);
      engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: 2);
      var now = 3;
      for (var i = 0; i < 20 && table.phase == Phase.swap; i++) {
        final seat = table.seats[table.active];
        final other = seat.id == 'alice' ? 'bob' : 'alice';
        void check(List<Frame> frames) {
          if (frames.isNotEmpty) expect(jsonEncode(frames.last.state.toJson()), jsonEncode(table.toJson()));
        }

        check(engine.disconnect(table, other, now: now++));
        check(
            engine.join(table, id: other, name: other, secret: other == 'bob' ? _bobSecret : _aliceSecret, now: now++));
        if (table.phase == Phase.swap && table.seats[table.active].human) {
          check(engine.act(table, table.seats[table.active].id, 'swapvote', {}, now: now++));
        }
      }
      expect(table.phase, isNot(Phase.swap));
    });

    test('a disconnected player is played for, so the table carries on', () {
      final (engine, table) = _table(seed: 6);
      engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: 1);
      engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: 2);
      // Whoever's turn it is drops out; once Bob's gone, only Alice is waited for
      engine.disconnect(table, 'bob', now: 3);
      var now = 4;
      for (var i = 0; i < 50 && table.handNumber == 1; i++) {
        expect(table.seats[table.active].id, isNot('bob'), reason: 'the table waited for a player who left');
        if (table.phase == Phase.lobby) break;
        _humanTurn(engine, table, now++);
      }
      expect(table.phase, anyOf(Phase.lobby, Phase.over));
    });
  });

  group('what players see', () {
    test('only their own hand; the deck and discard never show faces', () {
      final (engine, table) = _table(seed: 7);
      engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: 1);
      engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: 2);
      final view = engine.view(table, 'alice', now: 3);
      final players = (view['players'] as List).cast<Map>();
      final mine = players.firstWhere((p) => p['pid'] == 'alice')['cards'] as List;
      final bobs = players.firstWhere((p) => p['pid'] == 'bob')['cards'] as List;
      expect(mine.every((c) => (c as Map)['suit'] != null), isTrue);
      expect(bobs.every((c) => (c as Map)['suit'] == null && c['tid'] != null), isTrue);
      final game = view['game'] as Map;
      expect((game['deck'] as List).every((c) => (c as Map)['suit'] == null), isTrue);
      expect(game['host'], 'Alice');
      expect(jsonEncode(view), isNot(contains(_bobSecret)), reason: 'a secret leaked');
      expect(jsonEncode(view), isNot(contains(_aliceSecret)));
    });

    test('a saved table carries on exactly where it left off', () {
      final (engine, table) = _table(seed: 8);
      engine.act(table, 'alice', 'vote', {'vote': 'true'}, now: 1);
      engine.act(table, 'bob', 'vote', {'vote': 'true'}, now: 2);
      final saved = TableState.fromJson(jsonDecode(jsonEncode(table.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(saved.toJson()), jsonEncode(table.toJson()));
      _humanTurn(engine, saved, 3);
      _expectAllCards(saved);
    });
  });
}
