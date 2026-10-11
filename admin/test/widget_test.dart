import 'dart:math';

import 'package:donut_admin/src/model.dart';
import 'package:donut_admin/src/tables_screen.dart';
import 'package:donut_admin/src/widgets.dart';
import 'package:donut_engine/donut_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TableState table() {
    final engine = DonutEngine(random: Random(1));
    final state = engine.create(
        code: 'ABC234',
        hostId: 'alice-device',
        hostName: 'Alice',
        secret: 'alice-secret-0123456789',
        emblem: {'bg': 0xFF123456},
        now: DateTime.now().millisecondsSinceEpoch);
    engine.join(state,
        id: 'bob-device', name: 'Bob', secret: 'bob-secret-0123456789ab', now: DateTime.now().millisecondsSinceEpoch);
    engine.act(state, 'bob-device', 'chat', {'text': 'hi all'}, now: DateTime.now().millisecondsSinceEpoch);
    return state;
  }

  testWidgets('a table shows its people, host and chat, never their secrets', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TableDetail(table: LiveTable(table(), DateTime.now())))));
    expect(find.text('ABC234'), findsOneWidget);
    expect(find.textContaining('Alice  (host)'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.textContaining('hi all', findRichText: true), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.text('In the lobby'), findsWidgets);
  });

  test('a table counts as live only with someone connected and a recent move', () {
    final state = table();
    expect(LiveTable(state, DateTime.now()).active, isTrue);
    expect(LiveTable(state, DateTime.now().subtract(const Duration(hours: 1))).active, isFalse);
    for (final seat in state.seats) {
      seat.connected = false;
    }
    expect(LiveTable(state, DateTime.now()).active, isFalse);
    expect(statusOf(state), 'In the lobby');
  });
}
