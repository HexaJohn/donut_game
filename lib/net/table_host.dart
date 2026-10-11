import 'dart:ui';

import 'package:donut_game/ai/acrotron.dart';
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
  TableHost({this.onAllReady});

  final Game game = Game();

  /// Called when every human has voted to deal. Defaults to dealing.
  final void Function()? onAllReady;

  GamePlayer? player(String id) => game.playerDB[id];

  /// Seats a human, or updates their deck if they're back. Refuses
  /// Acrotron's name, which belongs to the house AI.
  ActionResult join(String id, String name, {String? back, String? face, bool agent = false}) {
    if (name.trim().toLowerCase() == acrotronName.toLowerCase()) {
      return const ActionResult.refused(409, 'That name belongs to the house AI. Pick another.');
    }
    final existing = game.playerDB[id];
    if (existing != null) {
      // Reconnecting keeps the seat, wearing whatever deck it brought
      if (back != null) existing.cardBack = back;
      if (face != null) existing.cardFace = face;
      return const ActionResult.ok();
    }
    final player = GamePlayer(name, 0, true)
      ..id = id
      ..agent = agent;
    if (back != null) player.cardBack = back;
    if (face != null) player.cardFace = face;
    game.addLocalPlayer(player);
    game.say('', '$name joined the game.', system: true);
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

  /// Everyone at the table, as clients see them.
  List<Map<String, dynamic>> playersJson() => [
        for (final player in game.players)
          {
            'username': player.name,
            'id': player.id + player.name,
            'pid': player.id,
            'human': player.human.toString(),
            'voteDeal': (player.voteToDeal || !player.human).toString(),
            'cards': player.hand.toJsonArray(),
            'swaps': player.swaps.value,
            'notReady': player.notReady.toString(),
            'score': player.score.value,
            'donuts': player.donuts.value,
            'winner': player.winner.value,
            'folds': player.folds,
            'tricks': player.tricks,
            'skip': player.skip.toString(),
            'awaitingCard': player.awaitingCard.toString(),
            'agent': player.agent,
            'back': player.cardBack,
            'face': player.cardFace,
          }
      ];

  /// The table itself. [inkRevision] is the drawing the client already has;
  /// the strokes are only included when the table has changed since.
  Map<String, dynamic> gameJson({int? inkRevision}) => {
        'state': gameStateToString[game.state.value]!,
        'table': GameCard.jsonArray(game.table.cards.value),
        'discard': GameCard.jsonArray(game.discard.cards.value),
        'deck': GameCard.jsonArray(game.deck.contents),
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
