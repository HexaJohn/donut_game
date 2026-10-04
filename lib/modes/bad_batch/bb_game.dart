import 'dart:math';

import 'package:donut_game/ai/acrotron.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/modes/bad_batch/bb_cards.dart';
import 'package:flutter/foundation.dart';

enum BbState { lobby, submitting, judging, roundOver, gameOver }

/// Bad Batch: each round the Card Czar reveals a prompt, everyone else plays
/// answer cards into its blanks, and the Czar picks the best one. First to
/// [pointsToWin] wins.
///
/// Seats and chat come from the shared [table] ([Game]), so bots added in the
/// server window and the table chat work the same in every mode.
class BadBatchGame {
  BadBatchGame(this.table);

  final Game table;

  static const int handSize = 10;
  static const int minPlayers = 3;
  static const int maxBlankLength = 80;

  BbState state = BbState.lobby;
  int round = 0;
  String? czar;
  PromptCard? prompt;
  int pointsToWin = 7;

  /// Blank cards shuffled into the answer pile, written by whoever plays them.
  int blankCards = 3;

  List<Deck> decks = [];
  final Map<String, List<ResponseCard>> hands = {};
  final Map<String, int> scores = {};

  /// This round's answers by player, and the shuffled order the Czar sees
  /// them in (authors stay hidden until the winner is picked).
  final Map<String, List<ResponseCard>> submissions = {};
  List<String> revealOrder = [];
  String? roundWinner;
  String? champion;

  /// Bumped on every change, so screens and the server know to refresh.
  final ValueNotifier<int> revision = ValueNotifier(0);

  List<PromptCard> _prompts = [];
  List<ResponseCard> _responses = [];
  final _random = Random();

  /// Cancels pending bot moves and round timers when the game restarts.
  int _epoch = 0;

  List<GamePlayer> get players => table.players;
  bool get running => state != BbState.lobby && state != BbState.gameOver;

  /// Players expected to answer this round. Anyone who joined mid-round has
  /// no hand yet and sits it out until the next one.
  Iterable<String> get answering => players.map((e) => e.name).where((name) => name != czar && hands.containsKey(name));

  void _changed() => revision.value++;
  void _announce(String text) => table.say('', text, system: true);

  /// Why the game can't start yet, or null if it can.
  String? get startProblem {
    if (players.length < minPlayers) return 'Bad Batch needs at least $minPlayers players.';
    final promptCount = decks.fold<int>(0, (sum, deck) => sum + deck.prompts.length);
    final answerCount = decks.fold<int>(0, (sum, deck) => sum + deck.responses.length) + blankCards;
    if (promptCount == 0) return 'The chosen decks have no prompt cards.';
    if (answerCount < players.length * handSize) return 'The chosen decks don\'t have enough answer cards.';
    return null;
  }

  /// Starts a new game with [decks]. Returns why not if it can't.
  String? start() {
    final problem = startProblem;
    if (problem != null) return problem;
    _epoch++;
    _prompts = decks.expand((deck) => deck.prompts).toList()..shuffle(_random);
    _responses = [
      ...decks.expand((deck) => deck.responses),
      for (var i = 0; i < blankCards; i++) const ResponseCard('', blank: true),
    ]..shuffle(_random);
    hands.clear();
    scores.clear();
    champion = null;
    round = 0;
    czar = null;
    _announce('Bad Batch! First to $pointsToWin points wins.');
    _newRound();
    return null;
  }

  /// Back to the lobby, dropping any game in progress.
  void stop() {
    _epoch++;
    state = BbState.lobby;
    submissions.clear();
    revealOrder = [];
    prompt = null;
    _changed();
  }

  void _newRound() {
    round++;
    // The Czar moves one seat round each round
    final names = players.map((e) => e.name).toList();
    final previous = czar == null ? -1 : names.indexOf(czar!);
    czar = names[(previous + 1) % names.length];
    if (_prompts.isEmpty) _prompts = decks.expand((deck) => deck.prompts).toList()..shuffle(_random);
    prompt = _prompts.removeLast();
    submissions.clear();
    revealOrder = [];
    roundWinner = null;
    for (final name in names) {
      scores.putIfAbsent(name, () => 0);
      final hand = hands.putIfAbsent(name, () => []);
      while (hand.length < handSize && _responses.isNotEmpty) {
        hand.add(_responses.removeLast());
      }
    }
    state = BbState.submitting;
    _announce('Round $round: $czar is the Card Czar.');
    _changed();
    _botsAnswer();
  }

  /// Plays [indexes] from [player]'s hand into the prompt's blanks, in order.
  /// [written] fills in any blank cards. Returns why not if it's refused.
  String? submit(String player, List<int> indexes, {Map<int, String> written = const {}}) {
    if (state != BbState.submitting) return 'Answers aren\'t open right now.';
    if (player == czar) return 'The Card Czar doesn\'t answer.';
    if (submissions.containsKey(player)) return 'You\'ve already answered.';
    final hand = hands[player];
    if (hand == null) return 'You\'re not in this round.';
    if (indexes.length != prompt!.pick) return 'This prompt needs ${prompt!.pick} card(s).';
    if (indexes.toSet().length != indexes.length || indexes.any((i) => i < 0 || i >= hand.length)) {
      return 'Those cards aren\'t in your hand.';
    }
    final cards = <ResponseCard>[];
    for (final i in indexes) {
      final card = hand[i];
      if (card.blank) {
        final text = (written[i] ?? '').trim();
        if (text.isEmpty) return 'Write something on your blank card first.';
        cards.add(card.written(text.length > maxBlankLength ? text.substring(0, maxBlankLength) : text));
      } else {
        cards.add(card);
      }
    }
    // Remove from the highest index down so the others don't shift
    for (final i in [...indexes]..sort((a, b) => b.compareTo(a))) {
      hand.removeAt(i);
    }
    submissions[player] = cards;
    _changed();
    _checkAllAnswered();
    return null;
  }

  /// Moves to judging once everyone still seated has answered.
  void _checkAllAnswered() {
    if (state != BbState.submitting) return;
    final seated = answering.toSet();
    if (seated.isEmpty || !seated.every(submissions.containsKey)) return;
    revealOrder = submissions.keys.where(seated.contains).toList()..shuffle(_random);
    state = BbState.judging;
    _changed();
    _botJudges();
  }

  /// The Czar picks answer [index] (in reveal order).
  String? judge(String player, int index) {
    if (state != BbState.judging) return 'There\'s nothing to judge yet.';
    if (player != czar) return 'Only the Card Czar picks the winner.';
    if (index < 0 || index >= revealOrder.length) return 'No such answer.';
    final winner = revealOrder[index];
    roundWinner = winner;
    scores[winner] = (scores[winner] ?? 0) + 1;
    _announce('$winner wins the round: "${prompt!.fill(submissions[winner]!.map((e) => e.text).toList())}"');
    if (scores[winner]! >= pointsToWin) {
      champion = winner;
      state = BbState.gameOver;
      _announce('$winner wins Bad Batch!');
      _changed();
      return null;
    }
    state = BbState.roundOver;
    _changed();
    final epoch = _epoch;
    Future.delayed(const Duration(seconds: 6), () {
      if (epoch == _epoch && state == BbState.roundOver) _newRound();
    });
    return null;
  }

  /// Keeps the round moving when players come and go: a missing Czar means a
  /// fresh round, and someone leaving can complete the set of answers.
  void rosterChanged() {
    if (!running) return;
    final names = players.map((e) => e.name).toSet();
    if (names.length < minPlayers) {
      _announce('Not enough players left. Back to the lobby.');
      stop();
      return;
    }
    if (czar != null && !names.contains(czar)) {
      _announce('The Card Czar left. New round.');
      _newRound();
      return;
    }
    _checkAllAnswered();
  }

  // --- Bots ---

  void _botsAnswer() {
    final epoch = _epoch;
    for (final bot in players.where((e) => !e.human && e.name != czar)) {
      if (bot.name == acrotronName) {
        _acrotronAnswers(epoch);
        continue;
      }
      Future.delayed(Duration(milliseconds: 1200 + _random.nextInt(3500)), () {
        if (epoch == _epoch && state == BbState.submitting) _randomAnswer(bot.name);
      });
    }
  }

  void _randomAnswer(String bot) {
    final hand = hands[bot];
    if (hand == null || submissions.containsKey(bot)) return;
    // Bots prefer printed cards; if they must play a blank, they write in an
    // answer borrowed from the decks
    final printed = [
      for (var i = 0; i < hand.length; i++)
        if (!hand[i].blank) i
    ]..shuffle(_random);
    final blanks = [
      for (var i = 0; i < hand.length; i++)
        if (hand[i].blank) i
    ];
    final picks = [...printed, ...blanks].take(prompt!.pick).toList();
    if (picks.length < prompt!.pick) return;
    final borrowed = decks.expand((deck) => deck.responses).toList();
    submit(bot, picks, written: {
      for (final i in picks)
        if (hand[i].blank)
          i: borrowed.isEmpty ? 'Something unspeakable.' : borrowed[_random.nextInt(borrowed.length)].text,
    });
  }

  /// Acrotron asks its model; if that fails or takes too long it plays
  /// like any other bot, so the round never waits on Ollama.
  Future<void> _acrotronAnswers(int epoch) async {
    final hand = List.of(hands[acrotronName] ?? <ResponseCard>[]);
    final choice =
        await Acrotron.instance.chooseAnswer(prompt!, hand).timeout(const Duration(seconds: 25), onTimeout: () => null);
    if (epoch != _epoch || state != BbState.submitting) return;
    if (choice == null || submit(acrotronName, choice.cards, written: choice.written) != null) {
      _randomAnswer(acrotronName);
    }
  }

  void _botJudges() {
    final czarPlayer = players.where((e) => e.name == czar);
    if (czarPlayer.isEmpty || czarPlayer.first.human) return;
    final epoch = _epoch;
    if (czar == acrotronName) {
      _acrotronJudges(epoch);
      return;
    }
    Future.delayed(Duration(milliseconds: 2500 + _random.nextInt(2500)), () {
      if (epoch == _epoch && state == BbState.judging) judge(czar!, _random.nextInt(revealOrder.length));
    });
  }

  Future<void> _acrotronJudges(int epoch) async {
    final answers = [
      for (final name in revealOrder) prompt!.fill(submissions[name]!.map((e) => e.text).toList()),
    ];
    final verdict =
        await Acrotron.instance.judge(prompt!, answers).timeout(const Duration(seconds: 25), onTimeout: () => null);
    if (epoch != _epoch || state != BbState.judging) return;
    judge(acrotronName, verdict?.choice ?? _random.nextInt(revealOrder.length));
    if (verdict != null) Acrotron.instance.say(verdict.quip);
  }

  // --- What each player is allowed to see ---

  /// Everything a client needs to draw the game for [viewer]. Only their own
  /// hand is included, and answers stay anonymous until the round is decided.
  Map<String, dynamic> toJson({String? viewer}) {
    final decided = state == BbState.roundOver || state == BbState.gameOver;
    return {
      'state': state.name,
      'round': round,
      'czar': czar,
      'prompt': prompt?.toJson(),
      'pointsToWin': pointsToWin,
      'scores': scores,
      'answered': submissions.keys.toList(),
      'answers': (state == BbState.submitting || state == BbState.lobby)
          ? <dynamic>[]
          : [
              for (final name in revealOrder)
                if (submissions[name] != null) submissions[name]!.map((e) => e.toJson()).toList(),
            ],
      'authors': decided ? revealOrder : null,
      'winner': roundWinner,
      'champion': champion,
      'hand': viewer == null ? <dynamic>[] : (hands[viewer] ?? []).map((e) => e.toJson()).toList(),
      'decks': decks.map((e) => e.name).toList(),
    };
  }
}

/// One player's view of a Bad Batch game, as sent by the server (or built
/// the same way offline), for the screen to draw.
class BbView {
  BbView.fromJson(Map<String, dynamic> json)
      : state = BbState.values.firstWhere((e) => e.name == json['state'], orElse: () => BbState.lobby),
        round = json['round'] ?? 0,
        czar = json['czar'],
        prompt = json['prompt'] == null ? null : PromptCard.fromJson(json['prompt']),
        pointsToWin = json['pointsToWin'] ?? 7,
        scores = Map<String, int>.from(json['scores'] ?? {}),
        answered = Set<String>.from(json['answered'] ?? []),
        answers = [
          for (final answer in json['answers'] ?? []) [for (final card in answer) ResponseCard.fromJson(card)]
        ],
        authors = json['authors'] == null ? null : List<String>.from(json['authors']),
        winner = json['winner'],
        champion = json['champion'],
        hand = [for (final card in json['hand'] ?? []) ResponseCard.fromJson(card)],
        decks = List<String>.from(json['decks'] ?? []);

  final BbState state;
  final int round;
  final String? czar;
  final PromptCard? prompt;
  final int pointsToWin;
  final Map<String, int> scores;
  final Set<String> answered;
  final List<List<ResponseCard>> answers;
  final List<String>? authors;
  final String? winner;
  final String? champion;
  final List<ResponseCard> hand;
  final List<String> decks;

  /// Index of the winning answer in [answers], once decided.
  int? get winningIndex {
    if (winner == null || authors == null) return null;
    final index = authors!.indexOf(winner!);
    return index < 0 ? null : index;
  }
}
