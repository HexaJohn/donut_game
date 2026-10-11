import 'dart:math';

import 'package:donut_admin/src/model.dart';
import 'package:donut_admin/src/reports_screen.dart';
import 'package:donut_admin/src/app_usage.dart';
import 'package:donut_admin/src/aws.dart';
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
      now: DateTime.now().millisecondsSinceEpoch,
    );
    engine.join(
      state,
      id: 'bob-device',
      name: 'Bob',
      secret: 'bob-secret-0123456789ab',
      now: DateTime.now().millisecondsSinceEpoch,
    );
    engine.act(state, 'bob-device', 'chat', {'text': 'hi all'}, now: DateTime.now().millisecondsSinceEpoch);
    return state;
  }

  testWidgets('a table shows its people, host and chat, never their secrets', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TableDetail(table: LiveTable(table(), DateTime.now()))),
      ),
    );
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

  testWidgets('a report shows its reason, note and the chat, with the reported player picked out', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final model = AdminModel(_NoAws())
      ..reports = [
        Report('reports/1-ABC234-1.json', {
          'time': DateTime.now().millisecondsSinceEpoch,
          'code': 'ABC234',
          'reason': 'harassment',
          'note': 'kept insulting me',
          'reporter': {'id': 'a', 'name': 'Alice'},
          'reported': {'id': 'b', 'name': 'Bob'},
          'chat': [
            {'author': 'Bob', 'text': 'you are terrible'},
          ],
        }),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReportsScreen(model: model)),
      ),
    );
    expect(find.text('Open reports (1)'), findsOneWidget);
    await tester.tap(find.text('Bob · Harassment'));
    await tester.pump();
    expect(find.text('"kept insulting me"'), findsOneWidget);
    expect(find.textContaining('you are terrible', findRichText: true), findsOneWidget);
    expect(find.text('Ban 7 days'), findsOneWidget);
  });

  testWidgets('app counts add up across days, with campaign stages read correctly', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final model = AdminModel(_NoAws())
      ..days = [
        DayStats('2026-10-10', {
          'app.campaign.bakery.2.casual.won': 3,
          'app.session.count': 4,
          'app.session.minutes': 40,
          'app.launch': 3,
          'app.launch.web': 2,
          'app.launch.android': 1,
        }, {}),
        DayStats('2026-10-11', {
          'app.campaign.bakery.2.casual.lost': 1,
          'app.quick.3bots.won': 1,
          'app.quick.3bots.lost': 1,
        }, {}),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: AppUsageSection(model: model)),
        ),
      ),
    );
    expect(find.text('bakery.2 · casual'), findsOneWidget);
    expect(find.text('3 / 1  (75%)'), findsOneWidget);
    expect(find.text('10.0 min'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('web'), findsOneWidget, reason: 'launches by platform');
  });
}

/// An AWS that's never called.
class _NoAws implements AdminAws {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
