import 'dart:ui';

import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/ai/bot_brain.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/res/resources.dart';

/// What came of a player's request: [ok], or refused with an HTTP-style
/// [status] and a reason.
class ActionResult {
  const ActionResult.ok()
      : status = 200,
        message = null;
  const ActionResult.refused(this.status, [this.message]);

  /// 400 malformed, 409 not allowed right now, 429 cooling down.
  final int status;
  final String? message;

  bool get ok => status == 200;
}

/// The authoritative side of an online Donut table: seats players, applies
/// their moves and describes the table for everyone else. Shared by the HTTP
/// server and a Game Center match's host, so both play by the same rules.
///
/// Players are addressed by id: the HTTP server's is device id + nickname,
/// Game Center's is the player's gamePlayerID.
class TableHost {
  TableHost({this.onAllReady, this.checkSecrets = false, this.fixedHostId});

  final Game game = Game();

  /// Called when every human has voted to deal. Defaults to dealing.
  final void Function()? onAllReady;

  /// Players must prove who they are with the secret they joined with. The
  /// HTTP server needs this, since ids are visible to everyone at the table;
  /// a Game Center host doesn't, since Apple vouches for who sent what.
  final bool checkSecrets;

  /// Who may restart the match. Null means the first human to join.
  final String? fixedHostId;

  final Map<String, String> _secrets = {};
  final Map<String, Map<String, _Bucket>> _buckets = {};

  /// Longest name shown at the table.
  static const int maxNameLength = 20;

  GamePlayer? player(String id) => game.playerDB[id];

  String? get hostId =>
      fixedHostId ?? game.players.where((player) => player.human).map((player) => player.id).firstOrNull;

  /// Whether [secret] is the one player [id] joined with (always true when
  /// secrets aren't checked).
  bool verify(String id, Object? secret) =>
      !checkSecrets || (game.playerDB.containsKey(id) && _secrets[id] != null && _secrets[id] == secret);

  /// Seats a human, or updates their deck if they're back. Coming back to a
  /// seat needs the secret it was taken with.
  ActionResult join(String id, String name, {String? back, String? face, Emblem? emblem, String? secret}) {
    final existing = game.playerDB[id];
    if (existing != null) {
      if (!verify(id, secret)) return const ActionResult.refused(409, 'That seat belongs to someone else.');
      // Reconnecting keeps the seat, wearing whatever deck it brought
      if (back != null) existing.cardBack = back;
      if (face != null) existing.cardFace = face;
      if (emblem != null) existing.emblem = emblem;
      return const ActionResult.ok();
    }
    if (checkSecrets && (secret == null || secret.length < 16)) {
      return const ActionResult.refused(400, 'Missing secret');
    }
    var trimmed = name.trim();
    if (trimmed.isEmpty) return const ActionResult.refused(400, 'Pick a name');
    if (trimmed.length > maxNameLength) trimmed = trimmed.substring(0, maxNameLength);
    if (game.players.any((player) => player.name.toLowerCase() == trimmed.toLowerCase())) {
      return const ActionResult.refused(409, 'Someone at the table already has that name.');
    }
    if (secret != null) _secrets[id] = secret;
    final player = GamePlayer(trimmed, 0, true)..id = id;
    if (back != null) player.cardBack = back;
    if (face != null) player.cardFace = face;
    player.emblem = emblem;
    game.addLocalPlayer(player);
    game.say('', '$trimmed joined the game.', system: true);
    if (game.playerDB.length == 2) {
      game.protectedActive = 1;
      game.protectedDealer = 0;
      game.state.value = GameState.waitingToDeal;
    }
    return const ActionResult.ok();
  }

  /// Applies [action] from player [id]. Bodies are the same JSON maps the
  /// HTTP endpoints take.
  ActionResult act(String id, String action, Map<String, dynamic> body) {
    final player = game.playerDB[id];
    if (player == null) return const ActionResult.refused(400, 'Not at this table');
    if (!verify(id, body['secret'])) return const ActionResult.refused(403, 'Not your seat');
    if (!_allow(id, action)) return const ActionResult.refused(429, 'Slow down');
    switch (action) {
      case 'vote':
        // "vote": "false" takes a ready back
        player.voteToDeal = '${body['vote']}' != 'false';
        evaluateDeal();
        return const ActionResult.ok();
      case 'swap':
        return _swap(player, body['swap']);
      case 'swapvote':
        player.notReady = !player.notReady;
        return const ActionResult.ok();
      case 'play':
        return _play(player, body['card']);
      case 'fold':
        if (game.state.value != GameState.waitingForPlayerToSwap ||
            game.activePlayerLazy != player ||
            !game.fold(player)) {
          return const ActionResult.refused(400);
        }
        return const ActionResult.ok();
      case 'chat':
        final text = '${body['text'] ?? ''}'.trim();
        if (text.isEmpty) return const ActionResult.refused(400);
        game.say(player.name, text.length > 280 ? text.substring(0, 280) : text);
        return const ActionResult.ok();
      case 'shoot':
        if (body['seat'] is String) {
          game.shootSeat(player.name, body['seat']);
        } else if (body['x'] is num && body['y'] is num) {
          game.shootTable(player.name, (body['x'] as num).toDouble(), (body['y'] as num).toDouble(),
              seed: body['seed'] is int ? body['seed'] : null);
        } else {
          return const ActionResult.refused(400);
        }
        return const ActionResult.ok();
      case 'flashbang':
        if (body['x'] is! num || body['y'] is! num) return const ActionResult.refused(400);
        final thrown = game.throwFlashbang(player.name, (body['x'] as num).toDouble(), (body['y'] as num).toDouble());
        return thrown ? const ActionResult.ok() : const ActionResult.refused(429, 'Flashbang cooling down');
      case 'draw':
        return _draw(player, body);
      case 'newMatch':
        if (id != hostId) return const ActionResult.refused(403, 'Only the host can restart');
        game.abort();
        game.newMatch();
        return const ActionResult.ok();
    }
    return ActionResult.refused(400, 'Unknown action $action');
  }

  ActionResult _swap(GamePlayer player, Object? index) {
    final hand = player.hand.cards.value;
    if (index is! int || index < 0 || index >= hand.length) return const ActionResult.refused(400);
    final card = hand[index];
    if (card.state == CardState.held && player.swaps.value > 0) {
      card.state = CardState.swap;
      player.swaps.value--;
      return const ActionResult.ok();
    }
    if (card.state == CardState.swap) {
      card.state = CardState.held;
      player.swaps.value++;
      return const ActionResult.ok();
    }
    return const ActionResult.refused(400);
  }

  /// Only accepted while the game is waiting for this player's card. Anything
  /// earlier (say, during the pause after winning a trick) would be wiped when
  /// the turn really starts, so it's refused and the client un-marks the card.
  ActionResult _play(GamePlayer player, Object? index) {
    final hand = player.hand.cards.value;
    if (index is! int) return const ActionResult.refused(400);
    if (!player.awaitingCard || index < 0 || index >= hand.length) {
      return const ActionResult.refused(409, 'Not your turn to play');
    }
    if (!BotBrain.legal(hand, game).contains(hand[index])) {
      return const ActionResult.refused(409, 'You must follow the lead suit');
    }
    player.cardToPlay = hand[index];
    return const ActionResult.ok();
  }

  /// Markers and eraser: {"stroke", "color", "width", "erase", "points"} with
  /// points flattened as [x1, y1, x2, y2...], all 0..1 across the felt.
  /// Repeated calls with the same stroke id extend it.
  ActionResult _draw(GamePlayer player, Map<String, dynamic> body) {
    final flat = body['points'];
    if (body['stroke'] is! String || flat is! List) return const ActionResult.refused(400);
    final points = <Offset>[];
    for (var i = 0; i + 1 < flat.length && points.length < 500; i += 2) {
      if (flat[i] is num && flat[i + 1] is num) {
        points.add(Offset((flat[i] as num).toDouble(), (flat[i + 1] as num).toDouble()));
      }
    }
    game.draw(
      player.name,
      body['stroke'],
      color: body['color'] is int ? body['color'] : 0xFF000000,
      width: ((body['width'] as num?) ?? 0.004).toDouble().clamp(0.001, 0.06),
      erase: body['erase'] == true,
      points: points,
    );
    return const ActionResult.ok();
  }

  /// Deals once every human is ready; bots always are.
  void evaluateDeal() {
    for (final player in game.players) {
      if (!player.human) player.voteToDeal = true;
    }
    if (game.players.any((player) => !player.voteToDeal)) return;
    if (onAllReady != null) {
      onAllReady!();
    } else {
      game.deal(shuffle: true);
    }
  }

  /// Hands a departed player's seat to a bot, so the table carries on
  /// without waiting for them.
  void replaceWithBot(String id) {
    final player = game.playerDB[id];
    if (player == null || !player.human) return;
    player.human = false;
    player.voteToDeal = true;
    game.say('', '${player.name} left. A bot takes their seat.', system: true);
    // Unstick anything the game was waiting on them for
    if (player.notReady && game.state.value == GameState.waitingForPlayerToSwap) {
      player.botSwap(game.trumpSuit.value);
      player.notReady = false;
    }
    if (player.awaitingCard && player.cardToPlay == null) {
      player.cardToPlay = player.brain.chooseCard(player, game);
    }
    evaluateDeal();
  }

  /// Throttles the moves that could flood everyone else's screen.
  bool _allow(String id, String action) {
    final (burst, perSecond) = switch (action) {
      'chat' => (5, 0.5),
      'shoot' => (6, 1.0),
      'draw' => (40, 20.0),
      _ => (0, 0.0),
    };
    if (burst == 0) return true;
    final bucket = _buckets.putIfAbsent(id, () => {}).putIfAbsent(action, () => _Bucket(burst, perSecond));
    return bucket.take();
  }

  /// Everyone at the table as player [viewer] may see them: their own hand,
  /// face down for everyone else. A spectator (null) sees no hands.
  List<Map<String, dynamic>> playersJson({String? viewer}) => [
        for (final player in game.players)
          {
            'username': player.name,
            'id': player.id + player.name,
            'pid': player.id,
            'human': player.human.toString(),
            'voteDeal': (player.voteToDeal || !player.human).toString(),
            'cards': player.hand.toJsonArray(hide: player.id != viewer || viewer == null),
            'swaps': player.swaps.value,
            'notReady': player.notReady.toString(),
            'score': player.score.value,
            'donuts': player.donuts.value,
            'winner': player.winner.value,
            'folds': player.folds,
            'tricks': player.tricks,
            'skip': player.skip.toString(),
            'awaitingCard': player.awaitingCard.toString(),
            'back': player.cardBack,
            'face': player.cardFace,
            if (player.human && player.emblem != null) 'emblem': player.emblem!.toJson(),
          }
      ];

  /// The table itself. [inkRevision] is the drawing the client already has;
  /// the strokes are only included when the table has changed since.
  Map<String, dynamic> gameJson({int? inkRevision}) => {
        'state': gameStateToString[game.state.value]!,
        'table': GameCard.jsonArray(game.table.cards.value),
        // Face down for everyone: only tracking ids, so cards can be animated
        'discard': GameCard.jsonArray(game.discard.cards.value, hide: true),
        'deck': GameCard.jsonArray(game.deck.contents, hide: true),
        'active': game.protectedActive,
        'dealer': game.protectedDealer,
        'trump': suitToString[game.trumpSuit.value],
        'leading_card': game.leadingCard?.toJson(),
        'sudden_death': game.suddenDeath.map((e) => e.name).toList(),
        'champion': game.champion.value?.name,
        'elapsed_ms': game.matchElapsed.inMilliseconds,
        'clock_running': game.matchStarted != null && game.matchEnded == null,
        'hand': game.handNumber,
        'trick_serial': game.trickSerial,
        'trick_winner': game.lastTrickWinner?.name,
        'chat': game.chat.value.map((e) => e.toJson()).toList(),
        'holes': game.holes.value.map((e) => e.toJson()).toList(),
        'spins': game.spins.value,
        'ink_rev': game.inkRevision,
        'target': game.targetScore,
        'host': game.playerDB[hostId]?.name,
        'flash': {
          'serial': game.flashSerial,
          'x': game.flashAt.dx,
          'y': game.flashAt.dy,
          'by': game.flashBy,
          'ready': game.flashReady,
        },
        if (inkRevision != game.inkRevision) 'ink': game.ink.value.map((e) => e.toJson()).toList(),
        'now_ms': DateTime.now().millisecondsSinceEpoch,
      };
}

/// A token bucket: [burst] at once, refilled at [perSecond].
class _Bucket {
  _Bucket(this.burst, this.perSecond) : _tokens = burst.toDouble();

  final int burst;
  final double perSecond;
  double _tokens;
  DateTime _at = DateTime.now();

  bool take() {
    final now = DateTime.now();
    _tokens = (_tokens + now.difference(_at).inMicroseconds / 1e6 * perSecond).clamp(0, burst.toDouble());
    _at = now;
    if (_tokens < 1) return false;
    _tokens -= 1;
    return true;
  }
}
