import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:donut_game/ai/acrotron.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/net/match_link.dart';
import 'package:donut_game/net/table_host.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/ui/game/game_controller.dart';

/// A Game Center match is hosted by one of the players' devices: it runs the
/// real game, the way the server does for online play, and every device
/// (its own included) plays through it.
///
/// Messages, all JSON maps with a kind "k":
///   client -> host  hello {back, face}: my deck
///                   act {a: action, b: body, n: serial}: a move
///   host -> client  snap {mode, players, game}: the whole table
///                   ack {n, ok, status, message}: the answer to a move
class MatchHostController extends GameController {
  MatchHostController(this.link) {
    _seat();
    _subscription = link.events.listen(_onEvent);
    // Changes go out as they happen; a heartbeat covers anything missed
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _broadcast());
  }

  final MatchLink link;
  final TableHost table = TableHost();
  late final StreamSubscription<LinkEvent> _subscription;
  late final Timer _ticker;

  @override
  Game get game => table.game;

  @override
  GamePlayer? get localPlayer => table.player(link.localId);

  @override
  bool get online => true;

  @override
  String get label => 'Game Center';

  /// Seats everyone in the match under unique names, with bots to make up
  /// the three players Donut needs.
  void _seat() {
    game.abort();
    game.playerDB.clear();
    game.chat.value = [];
    game.targetScore = startingScore;
    final taken = {acrotronName.toLowerCase()};
    for (final peer in link.peers) {
      final base = peer.name.trim().isEmpty ? 'Player' : peer.name.trim();
      var name = base;
      for (var n = 2; taken.contains(name.toLowerCase()); n++) {
        name = '$base $n';
      }
      taken.add(name.toLowerCase());
      final local = peer.id == link.localId;
      table.join(peer.id, name,
          back: local ? PlayerProfile.instance.cardPattern : null,
          face: local ? PlayerProfile.instance.cardFace : null);
    }
    while (game.players.length < 3) {
      game.addBot();
    }
    game.protectedDealer = 0;
    game.protectedActive = 1;
    game.newMatch();
  }

  void _onEvent(LinkEvent event) {
    switch (event) {
      case LinkMessage(:final from, :final message):
        _onMessage(from, message);
      case LinkPeerLeft(:final id):
        table.replaceWithBot(id);
        _broadcast(force: true);
      case LinkFailed(:final message):
        error.value = message;
    }
  }

  void _onMessage(String from, Map<String, dynamic> message) {
    switch (message['k']) {
      case 'hello':
        final player = table.player(from);
        if (player != null) {
          table.join(from, player.name,
              back: message['back'] is String ? message['back'] : null,
              face: message['face'] is String ? message['face'] : null);
        }
        _broadcast(force: true);
      case 'act':
        final body = message['b'] is Map ? Map<String, dynamic>.from(message['b']) : <String, dynamic>{};
        final result = table.act(from, '${message['a']}', body);
        link.send({'k': 'ack', 'n': message['n'], 'ok': result.ok, 'status': result.status, 'message': result.message},
            to: from);
        _broadcast(force: true);
    }
  }

  String _lastSent = '';
  DateTime _sentAt = DateTime(0);
  int _sentInk = -1;

  /// Sends the table to everyone if it's changed, or every couple of seconds
  /// regardless so a missed message can't leave anyone stuck.
  void _broadcast({bool force = false}) {
    final players = table.playersJson();
    final g = table.gameJson(inkRevision: _sentInk);
    // The clock fields tick on their own; they don't count as a change
    final key = jsonEncode({
      'p': players,
      'g': {...g}
        ..remove('now_ms')
        ..remove('elapsed_ms'),
    });
    final now = DateTime.now();
    if (!force && key == _lastSent && now.difference(_sentAt) < const Duration(seconds: 2)) return;
    _lastSent = key;
    _sentAt = now;
    _sentInk = game.inkRevision;
    link.send({'k': 'snap', 'mode': 'donut', 'players': players, 'game': g}).catchError((_) {});
  }

  /// Applies one of this device's own moves, as the host would anyone's.
  ActionResult _act(String action, [Map<String, dynamic> body = const {}]) {
    final result = table.act(link.localId, action, body);
    _broadcast(force: true);
    return result;
  }

  int _indexOf(GameCard card) => localPlayer?.hand.cards.value.indexOf(card) ?? -1;

  @override
  Future<void> deal() async {
    final local = localPlayer;
    if (local != null) _act('vote', {'vote': '${!local.voteToDeal}'});
  }

  @override
  Future<void> toggleSwap(GameCard card) async => _act('swap', {'swap': _indexOf(card)});

  @override
  Future<void> confirmSwap() async {
    localPlayer?.notReady = false;
    _broadcast(force: true);
  }

  @override
  Future<void> fold() async => _act('fold');

  @override
  Future<void> play(GameCard card) async => _act('play', {'card': _indexOf(card)});

  @override
  Future<void> sendChat(String text) async => _act('chat', {'text': text});

  @override
  Future<void> shootTable(double x, double y) async =>
      _act('shoot', {'x': x, 'y': y, 'seed': Random().nextInt(1 << 30)});

  @override
  Future<void> shootSeat(String name) async => _act('shoot', {'seat': name});

  @override
  Future<void> throwFlashbang(double x, double y) async => _act('flashbang', {'x': x, 'y': y});

  @override
  void draw(String strokeId,
      {required Color color, required double width, required bool erase, required List<Offset> points}) {
    final local = localPlayer;
    if (local == null) return;
    game.draw(local.name, strokeId, color: color.toARGB32(), width: width, erase: erase, points: points);
  }

  @override
  Future<void> newMatch() async => _act('newMatch');

  @override
  void dispose() {
    _ticker.cancel();
    _subscription.cancel();
    link.close();
    game.abort();
  }
}

/// A guest in a Game Center match: mirrors the host's table and sends moves
/// to it.
class MatchClientController extends RemoteTableController {
  MatchClientController(this.link) {
    _subscription = link.events.listen(_onEvent);
  }

  final MatchLink link;
  late final StreamSubscription<LinkEvent> _subscription;
  final Map<int, Completer<bool>> _pending = {};
  int _serial = 0;
  bool _synced = false;
  Timer? _hello;

  @override
  String get label => 'Game Center';

  @override
  GamePlayer? get localPlayer {
    for (final player in game.players) {
      if (player.id == link.localId) return player;
    }
    return null;
  }

  @override
  void start() {
    resetTable();
    // Say hello until the host answers: it may still be setting up
    _sayHello();
    _hello = Timer.periodic(const Duration(seconds: 1), (_) => _synced ? _hello?.cancel() : _sayHello());
  }

  void _sayHello() => link.send({
        'k': 'hello',
        'back': PlayerProfile.instance.cardPattern,
        'face': PlayerProfile.instance.cardFace,
      }, to: link.hostId).catchError((_) {});

  @override
  Future<bool> send(String action, Map<String, dynamic> body) async {
    final serial = _serial++;
    final answer = _pending[serial] = Completer<bool>();
    try {
      await link.send({'k': 'act', 'a': action, 'b': body, 'n': serial}, to: link.hostId);
    } catch (e) {
      _pending.remove(serial);
      error.value = 'Lost touch with the host.';
      return false;
    }
    return answer.future.timeout(const Duration(seconds: 4), onTimeout: () {
      _pending.remove(serial);
      return false;
    });
  }

  void _onEvent(LinkEvent event) {
    switch (event) {
      case LinkMessage(:final from, :final message) when from == link.hostId:
        switch (message['k']) {
          case 'snap':
            applySnapshot(message);
            _synced = true;
            error.value = null;
          case 'ack':
            _pending.remove(message['n'])?.complete(message['ok'] == true);
        }
      case LinkMessage():
        break;
      case LinkPeerLeft(:final id) when id == link.hostId:
        error.value = 'The host left, so this game is over.';
      case LinkPeerLeft():
        break;
      case LinkFailed(:final message):
        error.value = message;
    }
  }

  @override
  void dispose() {
    _hello?.cancel();
    _subscription.cancel();
    link.close();
  }
}
