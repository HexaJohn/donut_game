import 'dart:convert';
import 'dart:math';

import 'brain.dart';
import 'cards.dart';
import 'table.dart';

/// The table as it stood at one moment while a move played out, and how
/// long after the previous frame to show it. Clients play frames back in
/// order, so a trick can be seen complete before it's cleared, and bots
/// seem to think.
class Frame {
  const Frame(this.delayMs, this.state);

  final int delayMs;
  final TableState state;
}

/// A move the table won't take, with an HTTP-style status: 400 malformed,
/// 403 not allowed, 409 not now, 429 too fast.
class Refusal implements Exception {
  const Refusal(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => 'Refusal($status): $message';
}

const _botNames = [
  'Glazed Gary',
  'Sprinkles',
  'Boston Creme',
  'Cruller',
  'Maple Bar',
  'Jelly Jo',
  'Old Fashioned',
  'Bear Claw',
  'Cinnamon Sue',
  'Powdered Pete',
];

/// Runs a Donut table one move at a time, the way a server needs: each call
/// takes the saved table, applies a move, plays any bots' turns until a
/// human has to decide, and returns the frames to show on the way. Nothing
/// waits on a timer, so it suits a function that runs per request.
class DonutEngine {
  DonutEngine({
    Random? random,
    this.botMs = 800,
    this.swapMs = 500,
    this.trickMs = 1400,
    this.dealMs = 250,
  }) : _random = random ?? Random();

  final Random _random;

  /// Pauses between frames, in milliseconds.
  final int botMs;
  final int swapMs;
  final int trickMs;
  final int dealMs;

  static const int maxNameLength = 20;
  static const int chatLimit = 200;
  static const int holeLimit = 80;
  static const int inkPointLimit = 20000;
  static const int flashCooldownMs = 10000;

  // --- Making and joining tables ---------------------------------------------

  /// A new table with its host seated.
  TableState create({
    required String code,
    required String hostId,
    required String hostName,
    required String secret,
    String? back,
    String? face,
    Map<String, dynamic>? emblem,
    bool public = false,
    required int now,
  }) {
    final table = TableState(code: code, hostId: hostId, createdAt: now)..public = public;
    table.deck = _freshDeck();
    join(table, id: hostId, name: hostName, secret: secret, back: back, face: face, emblem: emblem, now: now);
    return table;
  }

  /// Seats a player, or welcomes one back to their seat. Joining is only
  /// open before the first hand or after a match; coming back always is.
  List<Frame> join(
    TableState table, {
    required String id,
    required String name,
    required String secret,
    String? back,
    String? face,
    Map<String, dynamic>? emblem,
    required int now,
  }) {
    final frames = <Frame>[];
    final existing = table.seat(id);
    if (existing != null) {
      if (existing.secret != secret) throw const Refusal(403, 'That seat belongs to someone else.');
      // Reopening the app reconnects without ever having been missed
      final wasGone = !existing.connected;
      existing
        ..connected = true
        ..back = back ?? existing.back
        ..face = face ?? existing.face
        ..emblem = cleanEmblem(emblem) ?? existing.emblem;
      if (wasGone) _say(table, '', '${existing.name} is back.', now, system: true);
      _frame(table, frames, 0, now);
      return frames;
    }
    if (secret.length < 16) throw const Refusal(400, 'Missing secret.');
    if (!_canChangeSeats(table)) throw const Refusal(409, 'That game has already started.');
    if (table.seats.length >= maxSeats) throw const Refusal(409, 'That table is full.');
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const Refusal(400, 'Pick a name first.');
    if (trimmed.length > maxNameLength) trimmed = trimmed.substring(0, maxNameLength);
    final base = trimmed;
    for (var n = 2; table.seats.any((seat) => seat.name.toLowerCase() == trimmed.toLowerCase()); n++) {
      trimmed = '$base $n';
    }
    table.seats.add(
        Seat(id: id, name: trimmed, human: true, back: back, face: face, emblem: cleanEmblem(emblem), secret: secret)
          ..score = table.target);
    _say(table, '', '$trimmed joined the game.', now, system: true);
    _frame(table, frames, 0, now);
    return frames;
  }

  /// A player's connection dropped. A bot plays for them until they're back,
  /// so the table doesn't stall.
  List<Frame> disconnect(TableState table, String id, {required int now}) {
    final seat = table.seat(id);
    if (seat == null || !seat.connected) return const [];
    seat.connected = false;
    final frames = <Frame>[];
    _say(table, '', '${seat.name} lost connection. A bot plays for them until they\'re back.', now, system: true);
    _frame(table, frames, 0, now);
    _advance(table, frames, now);
    return frames;
  }

  bool _canChangeSeats(TableState table) =>
      table.phase == Phase.over || (table.phase == Phase.lobby && table.handNumber == 0);

  // --- Moves -----------------------------------------------------------------

  /// Applies [action] from seat [id] and plays on until a human must decide.
  /// Bodies match the app's online moves. Throws [Refusal] if not allowed.
  List<Frame> act(TableState table, String id, String action, Map<String, dynamic> body, {required int now}) {
    final seat = table.seat(id);
    if (seat == null) throw const Refusal(403, 'Not at this table.');
    final frames = <Frame>[];
    switch (action) {
      case 'vote':
        if (table.phase != Phase.lobby && table.phase != Phase.over) throw const Refusal(409, 'A hand is in play.');
        if (table.phase == Phase.over) throw const Refusal(409, 'The match is over. The host can start another.');
        seat.voteToDeal = '${body['vote']}' != 'false';
        _frame(table, frames, 0, now);
      case 'swap':
        _requireSwapTurn(table, seat);
        final index = body['swap'];
        if (index is! int || index < 0 || index >= seat.hand.length) throw const Refusal(400, 'No such card.');
        final card = seat.hand[index];
        if (card.state == CardState.swap) {
          card.state = CardState.held;
          seat.swaps++;
        } else if (seat.swaps > 0) {
          card.state = CardState.swap;
          seat.swaps--;
        } else {
          throw const Refusal(409, 'No swaps left.');
        }
        _frame(table, frames, 0, now);
        return frames;
      case 'swapvote':
        _requireSwapTurn(table, seat);
        seat.notReady = false;
      case 'fold':
        _requireSwapTurn(table, seat);
        if (!_canFold(table, seat)) throw const Refusal(409, 'You can\'t fold this hand.');
        _fold(table, seat, now);
      case 'play':
        if (!_awaitingCard(table, seat)) throw const Refusal(409, 'Not your turn to play.');
        final index = body['card'];
        if (index is! int || index < 0 || index >= seat.hand.length) throw const Refusal(400, 'No such card.');
        final card = seat.hand[index];
        if (!legalPlays(seat.hand, table.trick.isEmpty ? null : table.lead).contains(card)) {
          throw const Refusal(409, 'You must follow the lead suit.');
        }
        _play(table, seat, card, frames, now);
      case 'chat':
        final text = '${body['text'] ?? ''}'.trim();
        if (text.isEmpty) throw const Refusal(400, 'Nothing to say.');
        if (!_allow(seat.recentChat, now, count: 5, perMs: 10000)) throw const Refusal(429, 'Slow down.');
        _say(table, seat.name, text.length > 280 ? text.substring(0, 280) : text, now);
        _frame(table, frames, 0, now);
        return frames;
      case 'shoot':
        if (!_allow(seat.recentShots, now, count: 6, perMs: 6000)) throw const Refusal(429, 'Slow down.');
        _shoot(table, seat, body, now);
        _frame(table, frames, 0, now);
        return frames;
      case 'flashbang':
        if (body['x'] is! num || body['y'] is! num) throw const Refusal(400, 'Throw it somewhere.');
        if (table.lastFlashAt != null && now - table.lastFlashAt! < flashCooldownMs) {
          throw const Refusal(429, 'Flashbang cooling down.');
        }
        table
          ..lastFlashAt = now
          ..flashX = (body['x'] as num).toDouble().clamp(0.0, 1.0)
          ..flashY = (body['y'] as num).toDouble().clamp(0.0, 1.0)
          ..flashBy = seat.name
          ..flashSerial += 1;
        _say(table, '', '${seat.name} threw a flashbang!', now, system: true);
        _frame(table, frames, 0, now);
        return frames;
      case 'draw':
        _draw(table, seat, body);
        _frame(table, frames, 0, now);
        return frames;
      case 'newMatch':
        if (id != table.hostId) throw const Refusal(403, 'Only the host can start a new match.');
        _newMatch(table, now);
        _frame(table, frames, 0, now);
        return frames;
      case 'addBot':
        if (id != table.hostId) throw const Refusal(403, 'Only the host can add bots.');
        if (!_canChangeSeats(table)) throw const Refusal(409, 'Bots can join between matches.');
        if (table.seats.length >= maxSeats) throw const Refusal(409, 'The table is full.');
        _addBot(table, now);
        _frame(table, frames, 0, now);
        return frames;
      case 'removeBot':
        if (id != table.hostId) throw const Refusal(403, 'Only the host can remove bots.');
        if (!_canChangeSeats(table)) throw const Refusal(409, 'Bots can leave between matches.');
        final bot = table.seats.lastWhere((seat) => !seat.human, orElse: () => throw const Refusal(409, 'No bots.'));
        table.seats.remove(bot);
        _say(table, '', '${bot.name} left the table.', now, system: true);
        _frame(table, frames, 0, now);
        return frames;
      default:
        throw Refusal(400, 'Unknown move $action.');
    }
    _advance(table, frames, now);
    return frames;
  }

  void _requireSwapTurn(TableState table, Seat seat) {
    final turn = table.phase == Phase.swap && table.seats[table.active] == seat && seat.notReady && !seat.skip;
    if (!turn) throw const Refusal(409, 'Not your turn to swap.');
  }

  bool _canFold(TableState table, Seat seat) => table.suddenDeath.isEmpty && seat.folds < maxConsecutiveFolds;

  bool _awaitingCard(TableState table, Seat seat) =>
      table.phase == Phase.play &&
      table.seats[table.active] == seat &&
      !seat.skip &&
      !seat.autoplay &&
      table.trick.length < _inHand(table);

  static bool _allow(List<int> recent, int now, {required int count, required int perMs}) {
    recent.removeWhere((at) => now - at > perMs);
    if (recent.length >= count) return false;
    recent.add(now);
    return true;
  }

  // --- Playing on ------------------------------------------------------------

  /// Plays every turn that doesn't need a human, until one does or the hand
  /// or match ends.
  void _advance(TableState table, List<Frame> frames, int now) {
    _playOn(table, frames, now);
    // Players only ever see frames, so the last must be the table as saved,
    // even when the final steps (handing a human their turn) made none
    if (frames.isEmpty || jsonEncode(frames.last.state.toJson()) != jsonEncode(table.toJson())) {
      _frame(table, frames, frames.isEmpty ? 0 : 300, now);
    }
  }

  void _playOn(TableState table, List<Frame> frames, int now) {
    for (var guard = 0; guard < 1000; guard++) {
      switch (table.phase) {
        case Phase.lobby:
          if (!_everyoneReady(table)) {
            table.status = GameState.waitingToDeal;
            return;
          }
          _deal(table, frames, now);
        case Phase.swap:
          if (!_swapStep(table, frames, now)) return;
        case Phase.play:
          if (!_playStep(table, frames, now)) return;
        case Phase.over:
          table.status = GameState.gameOver;
          return;
      }
    }
  }

  bool _everyoneReady(TableState table) {
    final humans = table.seats.where((seat) => seat.human && seat.connected);
    return humans.isNotEmpty && humans.every((seat) => seat.voteToDeal);
  }

  Iterable<Seat> _seated(TableState table) =>
      table.suddenDeath.isEmpty ? table.seats : table.seats.where((seat) => table.suddenDeath.contains(seat.id));

  /// Seats playing this hand: dealt in, not folded.
  int _inHand(TableState table) => table.seats.where((seat) => !seat.skip).length;

  void _deal(TableState table, List<Frame> frames, int now) {
    // Donut needs three at the table
    while (table.seats.length < 3) {
      _addBot(table, now);
    }
    final n = table.seats.length;
    table
      ..handNumber += 1
      ..matchStartedAt ??= now
      ..status = GameState.dealing
      ..trick = []
      ..lead = null;
    final dealer = table.seats[table.dealer % n];
    _say(
        table,
        '',
        table.suddenDeath.isEmpty
            ? 'Hand ${table.handNumber}: ${dealer.name} deals.'
            : 'Sudden death hand: ${_seated(table).map((s) => s.name).join(', ')}.',
        now,
        system: true);
    _shuffle(table.deck);
    final seated = _seated(table).toSet();
    for (final seat in table.seats) {
      seat
        ..tricks = 0
        ..hand = []
        ..winner = false
        ..voteToDeal = false
        ..swaps = maxSwaps;
      if (seated.contains(seat)) {
        seat
          ..skip = false
          ..donut = true
          ..notReady = true;
      } else {
        // Sitting out a sudden death hand
        seat
          ..skip = true
          ..donut = false
          ..notReady = false;
      }
    }
    TableCard? last;
    for (var round = 0; round < cardsPerHand; round++) {
      for (var i = 0; i < n; i++) {
        final seat = table.seats[(table.dealer + 1 + i) % n];
        if (seat.skip) continue;
        last = _dealCard(table, seat);
      }
      _frame(table, frames, round == 0 ? 0 : dealMs, now);
    }
    table
      ..trump = last!.suit
      ..status = GameState.waitingToSwap;
    _say(table, '', 'Trump is ${suitToString[table.trump]}.', now, system: true);
    _frame(table, frames, 600, now);
    table
      ..phase = Phase.swap
      ..active = (table.dealer + 1) % n
      ..swapTurns = 0;
  }

  TableCard _dealCard(TableState table, Seat seat) {
    if (table.deck.isEmpty) {
      table
        ..deck = table.discard
        ..discard = []
        ..revealed = {};
      _shuffle(table.deck);
    }
    final card = table.deck.removeAt(0)
      ..state = CardState.held
      ..owner = seat.id;
    seat.hand.add(card);
    return card;
  }

  void _shuffle(List<TableCard> cards) {
    cards.shuffle(_random);
    for (final card in cards) {
      card.retag();
    }
  }

  /// Takes the swap turn of the seat whose turn it is. False when that seat
  /// is a human who hasn't decided yet.
  bool _swapStep(TableState table, List<Frame> frames, int now) {
    final n = table.seats.length;
    if (table.swapTurns >= n) {
      table
        ..phase = Phase.play
        ..active = (table.dealer + 1) % n
        ..tricksLeft = table.seats.any((seat) => !seat.skip) ? cardsPerHand : 0
        ..status = GameState.playing;
      return true;
    }
    final seat = table.seats[table.active];
    if (seat.skip && seat.hand.isEmpty) {
      // Sitting out a sudden death hand
      _nextSwapTurn(table);
      return true;
    }
    if (seat.autoplay && seat.notReady && !seat.skip) {
      final brain = Brain<TableCard>(seat.skill, random: _random);
      final view = _SeatView(table, seat);
      if (brain.shouldFold(seat.hand, view) && _canFold(table, seat)) {
        _fold(table, seat, now);
      } else {
        for (final card in brain.chooseSwaps(seat.hand, table.trump, seat.swaps)) {
          card.state = CardState.swap;
          seat.swaps--;
        }
        seat.notReady = false;
      }
      table.status = GameState.swapping;
      _frame(table, frames, swapMs, now);
    }
    if (seat.notReady && !seat.skip) {
      table.status = GameState.waitingForPlayerToSwap;
      return false;
    }
    // Swapped, kept or folded: settle it and move on
    _resolveSwap(table, seat, now);
    table.status = GameState.swapping;
    _frame(table, frames, 300, now);
    _nextSwapTurn(table);
    return true;
  }

  void _nextSwapTurn(TableState table) {
    table
      ..active = (table.active + 1) % table.seats.length
      ..swapTurns += 1;
  }

  void _fold(TableState table, Seat seat, int now) {
    seat
      ..skip = true
      ..donut = false
      ..notReady = false;
    _say(table, '', '${seat.name} folds.', now, system: true);
  }

  void _resolveSwap(TableState table, Seat seat, int now) {
    if (seat.skip) {
      // Folded: the whole hand goes to the discard pile, face down
      seat.folds++;
      for (final card in seat.hand) {
        card.state = CardState.folded;
        table.discard.add(card);
      }
      seat.hand = [];
      return;
    }
    seat.folds = 0;
    final swapped = seat.hand.where((card) => card.state == CardState.swap).toList();
    _say(
        table,
        '',
        swapped.isEmpty
            ? '${seat.name} keeps their hand.'
            : '${seat.name} swaps ${swapped.length} card${swapped.length == 1 ? '' : 's'}.',
        now,
        system: true);
    for (final card in swapped) {
      seat.hand.remove(card);
      card.state = CardState.folded;
      table.discard.add(card);
    }
    for (var i = 0; i < swapped.length; i++) {
      _dealCard(table, seat);
    }
  }

  /// Plays the turn of whoever's up. False when that's a human to wait for.
  bool _playStep(TableState table, List<Frame> frames, int now) {
    if (table.tricksLeft <= 0) {
      _endHand(table, frames, now);
      return true;
    }
    if (table.trick.isNotEmpty && table.trick.length >= _inHand(table)) {
      _takeTrick(table, frames, now);
      return true;
    }
    final seat = table.seats[table.active];
    if (seat.skip) {
      table.active = (table.active + 1) % table.seats.length;
      return true;
    }
    if (!seat.autoplay) {
      table.status = GameState.playing;
      return false;
    }
    final card = Brain<TableCard>(seat.skill, random: _random).chooseCard(seat.hand, _SeatView(table, seat));
    _play(table, seat, card, frames, now, delay: botMs);
    return true;
  }

  void _play(TableState table, Seat seat, TableCard card, List<Frame> frames, int now, {int delay = 0}) {
    seat.hand.remove(card);
    card
      ..state = CardState.played
      ..owner = seat.id;
    if (table.trick.isEmpty) table.lead = card.suit;
    table.trick.add(card);
    table.revealed.add(card.faceId);
    table
      ..active = (table.active + 1) % table.seats.length
      ..status = GameState.playing;
    _frame(table, frames, delay, now);
  }

  void _takeTrick(TableState table, List<Frame> frames, int now) {
    // The highest score takes it; a tie goes to the later card
    var best = table.trick.first;
    for (final card in table.trick.skip(1)) {
      if (scoreFor(card, lead: table.lead!, trump: table.trump) >=
          scoreFor(best, lead: table.lead!, trump: table.trump)) {
        best = card;
      }
    }
    final winner = table.seat(best.owner!)!;
    winner
      ..tricks += 1
      ..matchTricks += 1
      ..score -= 1
      ..donut = false
      ..winner = true;
    table
      ..trickWinner = winner.id
      ..trickSerial += 1
      ..tricksLeft -= 1
      ..status = GameState.waitingForNextRound;
    _say(table, '', '${winner.name} takes the trick.', now, system: true);
    _frame(table, frames, 0, now);
    table.discard.addAll(table.trick);
    table
      ..trick = []
      ..lead = null
      ..active = table.seats.indexOf(winner);
    winner.winner = false;
    _frame(table, frames, trickMs, now);
  }

  void _endHand(TableState table, List<Frame> frames, int now) {
    for (final seat in table.seats.where((seat) => seat.donut && !seat.skip)) {
      seat
        ..score += donutPenalty
        ..donuts += 1;
      _say(table, '', '${seat.name} got a donut! +$donutPenalty', now, system: true);
    }
    for (final seat in table.seats) {
      seat
        ..voteToDeal = false
        ..winner = false
        ..hand = [];
    }
    final wasSuddenDeath = table.suddenDeath.isNotEmpty;
    _checkForChampion(table);
    final champion = table.champion == null ? null : table.seat(table.champion!);
    if (champion != null) {
      champion.winner = true;
      table
        ..phase = Phase.over
        ..matchEndedAt = now
        ..status = GameState.gameOver;
      _say(table, '', '${champion.name} wins the match!', now, system: true);
      _frame(table, frames, 400, now);
      return;
    }
    if (table.suddenDeath.isNotEmpty && !wasSuddenDeath) {
      final names = table.suddenDeath.map((id) => table.seat(id)!.name).join(', ');
      _say(table, '', 'Tie! Sudden death between $names.', now, system: true);
    }
    final n = table.seats.length;
    table
      ..dealer = (table.dealer + 1) % n
      ..active = (table.dealer + 1) % n
      ..phase = Phase.lobby
      ..status = GameState.waitingToDeal;
    _frame(table, frames, 400, now);
  }

  void _checkForChampion(TableState table) {
    if (table.suddenDeath.isEmpty) {
      final finishers = table.seats.where((seat) => seat.score <= 0).toList();
      if (finishers.length == 1) {
        table.champion = finishers.single.id;
      } else if (finishers.length > 1) {
        table.suddenDeath = [for (final seat in finishers) seat.id];
      }
      return;
    }
    // Sudden death: whoever took the fewest tricks is out, unless everyone
    // tied, in which case the hand is replayed
    final contenders = [for (final id in table.suddenDeath) table.seat(id)!];
    final fewest = contenders.map((seat) => seat.tricks).reduce(min);
    final out = contenders.where((seat) => seat.tricks == fewest).toList();
    if (out.length < contenders.length) {
      table.suddenDeath.removeWhere((id) => out.any((seat) => seat.id == id));
    }
    if (table.suddenDeath.length == 1) {
      table
        ..champion = table.suddenDeath.single
        ..suddenDeath = [];
    }
  }

  void _newMatch(TableState table, int now) {
    for (final seat in table.seats) {
      seat
        ..score = table.target
        ..donuts = 0
        ..folds = 0
        ..matchTricks = 0
        ..tricks = 0
        ..winner = false
        ..skip = false
        ..voteToDeal = false
        ..hand = [];
    }
    table
      ..deck = _freshDeck()
      ..discard = []
      ..trick = []
      ..lead = null
      ..suddenDeath = []
      ..champion = null
      ..handNumber = 0
      ..trickWinner = null
      ..holes = []
      ..spins = {}
      ..ink = []
      ..inkRevision += 1
      ..matchStartedAt = null
      ..matchEndedAt = null
      ..revealed = {}
      ..phase = Phase.lobby
      ..status = GameState.waitingToDeal;
    _say(table, '', 'New match! Everyone starts on ${table.target}.', now, system: true);
  }

  List<TableCard> _freshDeck() {
    final deck = [
      for (final suit in Suit.values)
        for (final value in Value.values) TableCard(suit, value),
    ];
    _shuffle(deck);
    return deck;
  }

  void _addBot(TableState table, int now) {
    final taken = table.seats.map((seat) => seat.name).toSet();
    final free = _botNames.where((name) => !taken.contains(name)).toList()..shuffle(_random);
    final name = free.isNotEmpty ? free.first : 'Bot ${table.seats.length + 1}';
    var id = 'bot:${table.seats.length}';
    for (var n = 0; table.seat(id) != null; n++) {
      id = 'bot:${table.seats.length}-$n';
    }
    table.seats.add(Seat(id: id, name: name, human: false, score: table.target));
    _say(table, '', '$name joined the table.', now, system: true);
  }

  // --- The fun stuff -----------------------------------------------------------

  void _say(TableState table, String author, String text, int now, {bool system = false}) {
    table.chat.add({'author': author, 'text': text, 'system': system, 'time': now});
    if (table.chat.length > chatLimit) table.chat.removeRange(0, table.chat.length - chatLimit);
  }

  void _shoot(TableState table, Seat seat, Map<String, dynamic> body, int now) {
    if (body['seat'] is String) {
      final target = body['seat'] as String;
      if (!table.seats.any((s) => s.name == target)) throw const Refusal(400, 'Nobody by that name.');
      table.spins[target] = (table.spins[target] ?? 0) + 1;
      _say(table, '',
          seat.name == target ? '${seat.name} shot their own placard.' : '${seat.name} shot $target\'s placard!', now,
          system: true);
    } else if (body['x'] is num && body['y'] is num) {
      table.holes.add({
        'x': (body['x'] as num).toDouble().clamp(0.0, 1.0),
        'y': (body['y'] as num).toDouble().clamp(0.0, 1.0),
        'shooter': seat.name,
        'seed': body['seed'] is int ? body['seed'] : _random.nextInt(1 << 30),
      });
      if (table.holes.length > holeLimit) table.holes.removeRange(0, table.holes.length - holeLimit);
    } else {
      throw const Refusal(400, 'Shoot something.');
    }
  }

  void _draw(TableState table, Seat seat, Map<String, dynamic> body) {
    final flat = body['points'];
    final id = body['stroke'];
    if (id is! String || flat is! List) throw const Refusal(400, 'Draw something.');
    final points = <double>[];
    for (var i = 0; i + 1 < flat.length && points.length < 1000; i += 2) {
      if (flat[i] is num && flat[i + 1] is num) {
        points
          ..add((flat[i] as num).toDouble().clamp(0.0, 1.0))
          ..add((flat[i + 1] as num).toDouble().clamp(0.0, 1.0));
      }
    }
    if (points.isEmpty) return;
    var stroke = table.ink.where((s) => s['id'] == id).lastOrNull;
    if (stroke == null) {
      stroke = {
        'id': id,
        'author': seat.name,
        'color': body['color'] is int ? body['color'] : 0xFF000000,
        'width': ((body['width'] as num?) ?? 0.004).toDouble().clamp(0.001, 0.06),
        'erase': body['erase'] == true,
        'points': <double>[],
      };
      table.ink.add(stroke);
    } else if (stroke['author'] != seat.name) {
      return;
    }
    stroke['points'] = [...(stroke['points'] as List), ...points];
    // The oldest strokes go first once the table gets crowded
    var total = table.ink.fold<int>(0, (sum, s) => sum + (s['points'] as List).length ~/ 2);
    while (total > inkPointLimit && table.ink.length > 1) {
      total -= (table.ink.removeAt(0)['points'] as List).length ~/ 2;
    }
    table.inkRevision++;
  }

  void _frame(TableState table, List<Frame> frames, int delayMs, int now) {
    table.updatedAt = now;
    frames.add(Frame(delayMs, table.clone()));
  }

  // --- What each player sees -----------------------------------------------------

  /// The table as seat [viewer] may see it, in the format the app's online
  /// tables read: their own hand face up, everyone else's cards face down.
  /// [withInk] includes the drawing, which is large, only when it's needed.
  Map<String, dynamic> view(TableState table, String? viewer, {required int now, bool withInk = false}) {
    String nameOf(String? id) => id == null ? 'nobody' : (table.seat(id)?.name ?? 'nobody');
    return {
      'players': [
        for (final seat in table.seats)
          {
            'username': seat.name,
            'id': seat.id,
            'pid': seat.id,
            'human': '${seat.human}',
            'voteDeal': '${seat.voteToDeal || !seat.human}',
            'cards': [for (final card in seat.hand) card.clientJson(hide: seat.id != viewer, ownerName: seat.name)],
            'swaps': seat.swaps,
            'notReady': '${seat.notReady}',
            'score': seat.score,
            'donuts': seat.donuts,
            'winner': seat.winner,
            'folds': seat.folds,
            'tricks': seat.tricks,
            'skip': '${seat.skip}',
            'awaitingCard': '${_awaitingCard(table, seat)}',
            'back': seat.human ? seat.back : null,
            'emblem': seat.human ? seat.emblem : null,
            'face': seat.human ? seat.face : null,
          }
      ],
      'game': {
        'state': gameStateToString[table.status],
        'table': [for (final card in table.trick) card.clientJson(hide: false, ownerName: nameOf(card.owner))],
        'discard': [for (final card in table.discard) card.clientJson(hide: true, ownerName: nameOf(card.owner))],
        'deck': [for (final card in table.deck) card.clientJson(hide: true, ownerName: 'nobody')],
        'active': table.active,
        'dealer': table.dealer,
        'trump': suitToString[table.trump],
        'leading_card': table.trick.isEmpty
            ? null
            : table.trick.first.clientJson(hide: false, ownerName: nameOf(table.trick.first.owner)),
        'sudden_death': [for (final id in table.suddenDeath) nameOf(id)],
        'champion': table.champion == null ? null : nameOf(table.champion),
        'elapsed_ms': table.matchStartedAt == null ? 0 : (table.matchEndedAt ?? now) - table.matchStartedAt!,
        'clock_running': table.matchStartedAt != null && table.matchEndedAt == null,
        'hand': table.handNumber,
        'trick_serial': table.trickSerial,
        'trick_winner': table.trickWinner == null ? null : nameOf(table.trickWinner),
        'chat': table.chat,
        'holes': table.holes,
        'spins': table.spins,
        'ink_rev': table.inkRevision,
        if (withInk) 'ink': table.ink,
        'target': table.target,
        'host': nameOf(table.hostId),
        'code': table.code,
        'public': table.public,
        'flash': {
          'serial': table.flashSerial,
          'x': table.flashX,
          'y': table.flashY,
          'by': table.flashBy,
          'ready': table.lastFlashAt == null || now - table.lastFlashAt! >= flashCooldownMs,
        },
        'now_ms': now,
      },
    };
  }
}

/// A seat's view of the table, for its bot.
class _SeatView implements BrainTable<TableCard> {
  _SeatView(this.table, this.seat);

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
  Iterable<PlayingCard> get revealed => [
        for (final id in table.revealed) TableCard(Suit.values[id ~/ 13], Value.values[id % 13], tid: ''),
      ];

  @override
  bool playedByHuman(TableCard card) => table.seat(card.owner ?? '')?.human == true;

  @override
  bool get humanStillToPlay {
    final played = table.trick.map((card) => card.owner).toSet();
    return table.seats.any((s) => s.human && !s.skip && !played.contains(s.id));
  }
}
