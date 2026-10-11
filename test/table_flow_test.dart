import 'package:donut_engine/donut_engine.dart' as engine;
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// A table run by the engine, applied the way an online client applies it,
/// with its moves recorded instead of sent.
class _RecordingTable extends RemoteTableController {
  final List<String> sent = [];

  @override
  String get label => 'test';

  @override
  GamePlayer? get localPlayer => game.players.where((player) => player.id == 'alice').firstOrNull;

  @override
  Future<bool> send(String action, Map<String, dynamic> body) async {
    sent.add(action);
    return true;
  }
}

/// Alice and Bob between the first and second hands.
Map<String, dynamic> _betweenHands() {
  final donut = engine.DonutEngine();
  final table = donut.create(code: 'ABC234', hostId: 'alice', hostName: 'Alice', secret: 'alice-secret-0123456789', now: 0);
  donut.join(table, id: 'bob', name: 'Bob', secret: 'bob-secret-0123456789ab', now: 0);
  table
    ..handNumber = 1
    ..status = engine.GameState.waitingToDeal;
  return donut.view(table, 'alice', now: 1);
}

void main() {
  test('the swap round runs from the dealer\'s left, skipping anyone who folded', () {
    final controller = OfflineGameController(nickname: 'You', bots: 3);
    final game = controller.game;
    final you = controller.localPlayer;
    // Seats 0 (you) to 3; seat 0 deals, so seat 1 swaps first and you last
    game
      ..protectedDealer = 0
      ..protectedActive = 1;
    expect(game.swapTurnsUntil(you), 3);
    expect(game.swapTurnsUntil(game.players[2]), 1, reason: 'up next');
    game.players[2].skip = true;
    expect(game.swapTurnsUntil(you), 2, reason: 'a folded seat takes no time');
    game.protectedActive = 3;
    expect(game.swapTurnsUntil(you), 1);
    expect(game.swapTurnsUntil(game.players[1]), -1, reason: 'already swapped');
    game.protectedActive = 0;
    expect(game.swapTurnsUntil(you), 0, reason: 'choosing now');
    game.players[2].skip = false;
  });

  testWidgets('between hands online, you\'re marked ready after a countdown unless you wait', (tester) async {
    final table = _RecordingTable()..applySnapshot(_betweenHands());
    expect(table.autoReadyIn.value, RemoteTableController.autoReadySeconds);
    await tester.pump(const Duration(seconds: 4));
    expect(table.autoReadyIn.value, RemoteTableController.autoReadySeconds - 4);
    expect(table.sent, isEmpty);
    await tester.pump(const Duration(seconds: 7));
    expect(table.sent, ['vote'], reason: 'the countdown ran out');
    expect(table.autoReadyIn.value, isNull);

    final waiting = _RecordingTable()..applySnapshot(_betweenHands());
    waiting.holdNextHand();
    await tester.pump(const Duration(seconds: 15));
    expect(waiting.sent, isEmpty, reason: 'they asked to wait');
    // A fresh snapshot of the same break doesn't restart it
    waiting.applySnapshot(_betweenHands());
    await tester.pump(const Duration(seconds: 15));
    expect(waiting.sent, isEmpty);
    Game().abort();
  });
}
