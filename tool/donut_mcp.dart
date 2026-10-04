// An MCP server that lets an AI agent (by default "Fable") sit at a Donut
// table and play: join a server, see its own seat's view, wait for its turn,
// make moves and chat.
//
// Run by an MCP client over stdio (see .mcp.json):
//   dart run tool/donut_mcp.dart
//
// Plain Dart, no Flutter: it talks to the game server's HTTP API like the game
// app does. It only ever shows the agent what its own seat could see, even
// where the server sends more (Donut currently sends every hand to everyone).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _serverName = 'donut-game';
const _serverVersion = '2.1.0';
const _defaultName = 'Fable';

void main() async {
  final harness = Harness();
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) async {
    if (line.trim().isEmpty) return;
    Map<String, dynamic> request;
    try {
      request = jsonDecode(line);
    } catch (e) {
      _send({
        'jsonrpc': '2.0',
        'id': null,
        'error': {'code': -32700, 'message': 'Parse error'}
      });
      return;
    }
    final id = request['id'];
    try {
      final result = await harness.handle(request['method'] as String? ?? '', request['params'] ?? {});
      // Notifications (no id) get no reply
      if (id != null) _send({'jsonrpc': '2.0', 'id': id, 'result': result});
    } on _RpcError catch (e) {
      if (id != null) {
        _send({
          'jsonrpc': '2.0',
          'id': id,
          'error': {'code': e.code, 'message': e.message}
        });
      }
    } catch (e, stack) {
      _log('Error handling ${request['method']}: $e\n$stack');
      if (id != null) {
        _send({
          'jsonrpc': '2.0',
          'id': id,
          'error': {'code': -32603, 'message': '$e'}
        });
      }
    }
  });
}

void _send(Map<String, dynamic> message) => stdout.writeln(jsonEncode(message));

/// stdout is the protocol, so diagnostics go to stderr.
void _log(String message) => stderr.writeln('[donut-mcp] $message');

class _RpcError implements Exception {
  _RpcError(this.code, this.message);
  final int code;
  final String message;
}

/// A tool the agent can call: its description, input schema and handler.
class McpTool {
  const McpTool(this.description, this.schema, this.run);
  final String description;
  final Map<String, dynamic> schema;
  final Future<String> Function(Map<String, dynamic> args) run;
}

Map<String, dynamic> _object(Map<String, dynamic> properties, [List<String> required = const []]) =>
    {'type': 'object', 'properties': properties, 'required': required};

class Harness {
  // Game servers are on this machine or the LAN: always connect directly,
  // whatever proxy the environment asks for
  final _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..findProxy = (_) => 'DIRECT';

  String? _host;
  int _port = 27960;
  String _name = _defaultName;
  String _id = '';

  /// Chat already shown to the agent, so waits can report only what's new.
  int _chatSeen = 0;

  late final Map<String, McpTool> tools = {
    'join': McpTool(
      'Join a Donut game server and take a seat. Do this first. The name defaults to Fable.',
      _object({
        'host': {'type': 'string', 'description': 'Server address, e.g. 192.168.1.20 or 127.0.0.1'},
        'port': {'type': 'integer', 'description': 'Server port, default 27960'},
        'name': {'type': 'string', 'description': 'Nickname at the table, default Fable'},
      }, [
        'host'
      ]),
      _join,
    ),
    'get_state': McpTool(
      'Describe the table from your seat: which game, the phase, your cards (with indexes for moves), '
      'scores, recent chat and what you should do next.',
      _object({}),
      (_) async => _describe(await _update()),
    ),
    'wait_for_turn': McpTool(
      'Wait until you need to act, someone chats, or the timeout passes, then describe the table. '
      'Use this instead of polling get_state.',
      _object({
        'timeout_seconds': {'type': 'integer', 'description': 'How long to wait, 5-120, default 60'},
      }),
      _wait,
    ),
    'ready': McpTool(
      'Say you are ready to start the next hand or game (or take it back with ready=false).',
      _object({
        'ready': {'type': 'boolean', 'description': 'Default true'},
      }),
      (args) => _act('/vote', {'vote': '${args['ready'] ?? true}'}, 'Ready.'),
    ),
    'swap': McpTool(
      'Donut, your swap turn: discard up to 3 cards (by index in your hand) and draw replacements. '
      'An empty list keeps your hand.',
      _object({
        'cards': {
          'type': 'array',
          'items': {'type': 'integer'},
          'description': 'Indexes of cards in your hand to swap out',
        },
      }, [
        'cards'
      ]),
      _swap,
    ),
    'fold': McpTool(
      'Donut, your swap turn: sit this hand out. No tricks, but no donut penalty either. '
      'Not allowed after folding the last 2 hands, or in sudden death.',
      _object({}),
      (_) => _act('/fold', {}, 'Folded this hand.'),
    ),
    'play_card': McpTool(
      'Donut, your turn in a trick: play the card at this index of your hand. Follow the lead suit if you can.',
      _object({
        'card': {'type': 'integer', 'description': 'Index of the card in your hand'},
      }, [
        'card'
      ]),
      (args) => _act('/play', {'card': args['card']}, 'Played.'),
    ),
    'submit_answer': McpTool(
      'Bad Batch: play answer cards (by index in your hand) into the prompt\'s blanks, in order. '
      'If you play a blank card, give its text in blank_text.',
      _object({
        'cards': {
          'type': 'array',
          'items': {'type': 'integer'},
          'description': 'Hand indexes, one per blank, in blank order',
        },
        'blank_text': {'type': 'string', 'description': 'What to write on a blank card, if you play one'},
      }, [
        'cards'
      ]),
      _submitAnswer,
    ),
    'judge': McpTool(
      'Bad Batch, when you are the Card Czar: pick the winning answer by its index.',
      _object({
        'answer': {'type': 'integer', 'description': 'Index of the winning answer'},
      }, [
        'answer'
      ]),
      (args) => _act('/bb/judge', {'index': args['answer']}, 'Winner picked.'),
    ),
    'chat': McpTool(
      'Say something in the table chat. It appears as a speech bubble over your seat.',
      _object({
        'text': {'type': 'string', 'description': 'What to say (max 280 characters)'},
      }, [
        'text'
      ]),
      (args) => _act('/chat', {'text': '${args['text']}'}, 'Said.'),
    ),
    'shoot': McpTool(
      'Fire the table revolver: at a player\'s placard (spins it) or at the table (leaves a bullet hole).',
      _object({
        'target': {'type': 'string', 'description': 'A player\'s name, or "table"'},
      }, [
        'target'
      ]),
      _shoot,
    ),
    'throw_flashbang': McpTool(
      'Throw a flashbang onto the table: everyone\'s screen goes white and their ears ring. 10 second cooldown.',
      _object({}),
      (_) => _act('/flashbang', {'x': 0.5, 'y': 0.5}, 'Flashbang thrown!'),
    ),
  };

  Future<Map<String, dynamic>> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'initialize':
        return {
          'protocolVersion': params['protocolVersion'] ?? '2025-06-18',
          'capabilities': {'tools': {}},
          'serverInfo': {'name': _serverName, 'version': _serverVersion},
          'instructions': 'Play Donut (a trick-taking card game) or Bad Batch (a fill-in-the-blank party game) '
              'at a friends\' table. Call join, then loop: wait_for_turn, read the state, make your move. '
              'Chat and banter between moves; other players can see everything you say.',
        };
      case 'ping':
      case 'notifications/initialized':
      case 'notifications/cancelled':
        return {};
      case 'tools/list':
        return {
          'tools': [
            for (final entry in tools.entries)
              {'name': entry.key, 'description': entry.value.description, 'inputSchema': entry.value.schema},
          ],
        };
      case 'tools/call':
        final tool = tools[params['name']];
        if (tool == null) throw _RpcError(-32602, 'Unknown tool ${params['name']}');
        try {
          final text = await tool.run(Map<String, dynamic>.from(params['arguments'] ?? {}));
          return {
            'content': [
              {'type': 'text', 'text': text},
            ],
          };
        } catch (e) {
          // Tool failures are reported to the agent as results, not protocol errors
          return {
            'content': [
              {'type': 'text', 'text': '$e'},
            ],
            'isError': true,
          };
        }
      default:
        throw _RpcError(-32601, 'Method not found: $method');
    }
  }

  // --- HTTP ---

  Uri _uri(String path, [Map<String, String>? query]) {
    if (_host == null) throw 'Not at a table yet. Call join first.';
    return Uri(scheme: 'http', host: _host, port: _port, path: path, queryParameters: query);
  }

  Future<(int, String)> _request(String method, Uri uri, [Map<String, dynamic>? body]) async {
    try {
      final request = await _http.openUrl(method, uri).timeout(const Duration(seconds: 5));
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(const Duration(seconds: 10));
      return (response.statusCode, await response.transform(utf8.decoder).join());
    } on TimeoutException {
      throw 'The server at $_host:$_port did not answer.';
    } on SocketException {
      throw 'Could not reach the server at $_host:$_port.';
    }
  }

  Future<Map<String, dynamic>> _update() async {
    final (status, body) = await _request('GET', _uri('/update', {'id': _id, 'ink_rev': '999999999'}));
    if (status != 200) throw 'The server returned $status.';
    return jsonDecode(body)[0];
  }

  /// Posts a move. Returns [done] plus a short look at the table, or the
  /// server's reason for refusing.
  Future<String> _act(String path, Map<String, dynamic> body, String done) async {
    final (status, reply) = await _request('POST', _uri(path), {'id': _id, ...body});
    if (status != 200) throw 'Refused ($status): ${reply.isEmpty ? 'not allowed right now' : reply}';
    await Future.delayed(const Duration(milliseconds: 300));
    return '$done\n\n${_describe(await _update())}';
  }

  // --- Tools ---

  Future<String> _join(Map<String, dynamic> args) async {
    _host = '${args['host']}'.trim();
    _port = args['port'] is int ? args['port'] : 27960;
    _name = ('${args['name'] ?? ''}'.trim().isEmpty) ? _defaultName : '${args['name']}'.trim();
    const device = 'mcp-agent-';
    final (status, reply) = await _request('POST', _uri('/connect'), {'username': _name, 'id': device, 'agent': true});
    if (status != 200) throw 'Could not join ($status): $reply';
    // The server keys players by the id it was given plus the name
    _id = '$device$_name';
    final state = await _update();
    _chatSeen = (state['game']?['chat'] as List? ?? []).length;
    return 'Joined $_host:$_port as $_name.\n\n${_describe(state)}';
  }

  Future<String> _wait(Map<String, dynamic> args) async {
    final timeout =
        Duration(seconds: (args['timeout_seconds'] is int ? args['timeout_seconds'] as int : 60).clamp(5, 120));
    final end = DateTime.now().add(timeout);
    final startState = _signature(await _update());
    while (DateTime.now().isBefore(end)) {
      final state = await _update();
      final chat = (state['game']?['chat'] as List? ?? []);
      final fresh = chat.skip(_chatSeen.clamp(0, chat.length)).where((m) => m['author'] != _name).toList();
      final needed = _actionNeeded(state);
      final heard = fresh.any((m) => m['system'] != true);
      final matchEnded = _signature(state) != startState && _isOver(state);
      if (needed != null || heard || matchEnded) {
        final reason = [
          if (needed != null) 'Your move: $needed',
          if (heard) 'New chat.',
          if (matchEnded && needed == null) 'The game is over.',
        ].join(' ');
        return '$reason\n\n${_describe(state)}';
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return 'Nothing needed from you yet (waited ${timeout.inSeconds}s).\n\n${_describe(await _update())}';
  }

  Future<String> _swap(Map<String, dynamic> args) async {
    final wanted = {
      for (final c in args['cards'] ?? [])
        if (c is int) c
    };
    if (wanted.length > 3) throw 'You can swap at most 3 cards.';
    final me = _me(await _update());
    if (me == null) throw 'You are not at this table.';
    final hand = me['cards'] as List;
    if (wanted.any((i) => i < 0 || i >= hand.length)) throw 'Those cards are not in your hand.';
    // Marking a card toggles it, so only touch the ones that need changing
    for (var i = 0; i < hand.length; i++) {
      final marked = hand[i]['state'] == 'swap';
      if (marked != wanted.contains(i)) {
        final (status, reply) = await _request('POST', _uri('/swap'), {'id': _id, 'swap': i});
        if (status != 200) throw 'Refused: $reply';
      }
    }
    return _act('/swapvote', {}, wanted.isEmpty ? 'Kept your hand.' : 'Swapped ${wanted.length} card(s).');
  }

  Future<String> _submitAnswer(Map<String, dynamic> args) async {
    final cards = [
      for (final c in args['cards'] ?? [])
        if (c is int) c
    ];
    final bb = (await _update())['bb'];
    final hand = (bb?['hand'] as List? ?? []);
    final blankText = '${args['blank_text'] ?? ''}'.trim();
    final written = {
      for (final i in cards)
        if (i >= 0 && i < hand.length && hand[i]['blank'] == true) '$i': blankText,
    };
    if (written.isNotEmpty && blankText.isEmpty) throw 'You played a blank card: give its text in blank_text.';
    return _act('/bb/submit', {'cards': cards, 'written': written}, 'Answer in.');
  }

  Future<String> _shoot(Map<String, dynamic> args) async {
    final target = '${args['target'] ?? ''}'.trim();
    if (target.toLowerCase() == 'table') {
      return _act(
          '/shoot',
          {'x': 0.2 + 0.6 * (DateTime.now().millisecond / 1000), 'y': 0.3 + 0.4 * (DateTime.now().microsecond / 1000)},
          'Bang! Hole in the table.');
    }
    return _act('/shoot', {'seat': target}, 'Bang! $target\'s placard is spinning.');
  }

  // --- Reading the table ---

  Map<String, dynamic>? _me(Map<String, dynamic> state) {
    for (final p in state['players'] ?? []) {
      if (p['username'] == _name) return p;
    }
    return null;
  }

  bool _isOver(Map<String, dynamic> state) {
    final phase = state['mode'] == 'badBatch' ? (state['bb'] ?? {})['state'] : (state['game'] ?? {})['state'];
    return phase == 'gameOver';
  }

  String _signature(Map<String, dynamic> state) =>
      '${state['mode']}|${state['game']?['state']}|${state['bb']?['state']}|${state['bb']?['round']}';

  /// What the agent needs to do right now, or null.
  String? _actionNeeded(Map<String, dynamic> state) {
    final me = _me(state);
    if (me == null) return null;
    if (state['mode'] == 'badBatch') {
      final bb = state['bb'] ?? {};
      final czar = bb['czar'] == _name;
      switch (bb['state']) {
        case 'lobby' || 'gameOver':
          return me['voteDeal'] == 'true' ? null : 'say you are ready (ready) to start.';
        case 'submitting':
          final answered = (bb['answered'] as List? ?? []).contains(_name);
          return czar || answered ? null : 'play answer cards (submit_answer).';
        case 'judging':
          return czar ? 'you are the Card Czar: pick the best answer (judge).' : null;
      }
      return null;
    }
    final game = state['game'] ?? {};
    final players = state['players'] as List? ?? [];
    final active =
        game['active'] is int && game['active'] < players.length ? players[game['active']]['username'] : null;
    switch (game['state']) {
      case 'waitingToDeal' || 'waitingForPlayers':
        return me['voteDeal'] == 'true' ? null : 'say you are ready (ready) for the next hand.';
      case 'waitingForPlayerToSwap':
        return active == _name && me['notReady'] == 'true' && me['skip'] != 'true'
            ? 'swap up to 3 cards, keep your hand (swap with []), or fold.'
            : null;
      case 'playing' || 'waitingForPlayer':
        return me['awaitingCard'] == 'true' ? 'play a card (play_card).' : null;
    }
    return null;
  }

  static const _ranks = {
    'two': '2',
    'three': '3',
    'four': '4',
    'five': '5',
    'six': '6',
    'seven': '7',
    'eight': '8',
    'nine': '9',
    'ten': '10',
    'jack': 'J',
    'queen': 'Q',
    'king': 'K',
    'ace': 'A',
  };
  static const _suits = {'spades': '♠', 'hearts': '♥', 'diamonds': '♦', 'clubs': '♣'};

  String _card(Map card) => '${_ranks[card['value']] ?? card['value']}${_suits[card['suit']] ?? card['suit']}';

  String _describe(Map<String, dynamic> state) {
    final out = StringBuffer();
    final me = _me(state);
    if (me == null) return 'You are not seated at this table (were you removed?). Call join again.';
    final needed = _actionNeeded(state);
    if (state['mode'] == 'badBatch') {
      _describeBadBatch(state, out);
    } else {
      _describeDonut(state, me, out);
    }
    out.writeln();
    out.writeln(needed == null ? 'Nothing needed from you right now.' : 'YOUR MOVE: $needed');
    _describeChat(state, out);
    return out.toString().trim();
  }

  void _describeDonut(Map<String, dynamic> state, Map me, StringBuffer out) {
    final game = state['game'] ?? {};
    final players = (state['players'] as List? ?? []);
    final active = game['active'] is int && game['active'] < players.length ? players[game['active']]['username'] : '?';
    final dealer = game['dealer'] is int && game['dealer'] < players.length ? players[game['dealer']]['username'] : '?';
    out.writeln('Game: Donut (trick-taking). Lowest score wins; reach 0 to win. Each trick won is -1; '
        'taking no tricks in a hand (a "donut") is +5. Follow the lead suit if you can; trump beats other suits.');
    out.writeln('Phase: ${game['state']}. Hand ${game['hand']}. Dealer: $dealer. Whose turn: $active. '
        'Trump: ${_suits[game['trump']] ?? game['trump']} ${game['trump']}.');
    if (game['champion'] != null) out.writeln('Match winner: ${game['champion']}.');
    if ((game['sudden_death'] as List? ?? []).isNotEmpty) {
      out.writeln('Sudden death: ${game['sudden_death'].join(', ')}.');
    }
    out.writeln('Players (score, tricks this hand):');
    for (final p in players) {
      final flags = [
        if (p['username'] == _name) 'you',
        if (p['human'] != 'true') 'bot',
        if (p['agent'] == true && p['username'] != _name) 'AI agent',
        if (p['skip'] == 'true') 'folded',
        if (p['voteDeal'] == 'true' && game['state'] == 'waitingToDeal') 'ready',
      ];
      out.writeln('  ${p['username']}: ${p['score']} pts, ${p['tricks']} tricks, ${p['donuts']} donuts'
          '${flags.isEmpty ? '' : ' (${flags.join(', ')})'}, ${(p['cards'] as List? ?? []).length} cards');
    }
    final table = (game['table'] as List? ?? []);
    if (table.isNotEmpty) {
      out.writeln('This trick: ${table.map((c) => '${c['belongsTo']} ${_card(c)}').join(', ')}');
    }
    final hand = (me['cards'] as List? ?? []);
    final lead = game['leading_card']?['suit'];
    final hasLead = lead != null && table.isNotEmpty && hand.any((c) => c['suit'] == lead);
    out.writeln('Your hand:');
    for (var i = 0; i < hand.length; i++) {
      final c = hand[i];
      final legal = !hasLead || c['suit'] == lead;
      out.writeln('  [$i] ${_card(c)}'
          '${c['suit'] == game['trump'] ? ' (trump)' : ''}'
          '${c['state'] == 'swap' ? ' (marked to swap)' : ''}'
          '${me['awaitingCard'] == 'true' && !legal ? ' (can\'t play: must follow ${_suits[lead]})' : ''}');
    }
    if (game['state'] == 'waitingForPlayerToSwap' && active == _name) {
      out.writeln('Swaps left: ${me['swaps']}. Folds in a row: ${me['folds']}.');
    }
  }

  void _describeBadBatch(Map<String, dynamic> state, StringBuffer out) {
    final bb = state['bb'] ?? {};
    out.writeln('Game: Bad Batch (adult fill-in-the-blank). The Card Czar reveals a prompt; everyone else plays '
        'answer cards into its blanks; the Czar picks the funniest. First to ${bb['pointsToWin']} points wins.');
    out.writeln('Phase: ${bb['state']}. Round ${bb['round']}. Card Czar: ${bb['czar'] ?? '-'}.');
    final scores = Map<String, dynamic>.from(bb['scores'] ?? {});
    out.writeln('Scores: ${scores.entries.map((e) => '${e.key} ${e.value}').join(', ')}');
    final prompt = bb['prompt']?['pieces'] as List?;
    if (prompt != null) {
      out.writeln('Prompt (${prompt.length - 1} blank${prompt.length > 2 ? 's' : ''}): "${prompt.join('_____')}"');
    }
    final answered = (bb['answered'] as List? ?? []);
    if (bb['state'] == 'submitting') {
      out.writeln('Answered so far: ${answered.isEmpty ? 'nobody' : answered.join(', ')}');
    }
    final answers = (bb['answers'] as List? ?? []);
    if (answers.isNotEmpty && prompt != null) {
      out.writeln('Answers:');
      final authors = bb['authors'] as List?;
      for (var i = 0; i < answers.length; i++) {
        final texts = [for (final c in answers[i]) '${c['text']}'];
        out.writeln('  [$i] ${_fill(prompt, texts)}${authors == null ? '' : ' (by ${authors[i]})'}');
      }
    }
    if (bb['winner'] != null) out.writeln('Round winner: ${bb['winner']}.');
    if (bb['champion'] != null) out.writeln('Game winner: ${bb['champion']}.');
    final hand = (bb['hand'] as List? ?? []);
    if (hand.isNotEmpty) {
      out.writeln('Your answer cards:');
      for (var i = 0; i < hand.length; i++) {
        out.writeln('  [$i] ${hand[i]['blank'] == true ? '(BLANK: write your own with blank_text)' : hand[i]['text']}');
      }
    }
  }

  String _fill(List pieces, List<String> answers) {
    final b = StringBuffer();
    for (var i = 0; i < pieces.length; i++) {
      b.write(pieces[i]);
      if (i < answers.length && i < pieces.length - 1) {
        final piece = '${pieces[i]}';
        b.write(piece.isEmpty || piece.endsWith(' ') ? '' : ' ');
        b.write(answers[i]);
      }
    }
    return b.toString().trim();
  }

  void _describeChat(Map<String, dynamic> state, StringBuffer out) {
    final chat = (state['game']?['chat'] as List? ?? []);
    final recent = chat.skip(chat.length > 12 ? chat.length - 12 : 0).toList();
    if (recent.isEmpty) return;
    out.writeln();
    out.writeln('Recent chat (newest last; [game] lines are events):');
    final firstNew = _chatSeen;
    for (var i = 0; i < recent.length; i++) {
      final m = recent[i];
      final index = chat.length - recent.length + i;
      final isNew = index >= firstNew && m['author'] != _name;
      out.writeln(
          '  ${isNew ? '* ' : ''}${m['system'] == true ? '[game] ${m['text']}' : '${m['author']}: ${m['text']}'}');
    }
    _chatSeen = chat.length;
  }
}
