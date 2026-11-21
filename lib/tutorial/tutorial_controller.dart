import 'dart:async';

import 'package:donut_copy/donut_copy.dart';
import 'package:donut_engine/donut_engine.dart' show BotSkill, scoreFor, valueToScore;
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_card/game_card_deck.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:flutter/foundation.dart';

/// The tutorial: one hand against two bots, dealt from a stacked deck with
/// every card face up, and a line of coaching for whatever is happening.
///
/// The bots play at the regular skill, which never guesses: it swaps every
/// card that isn't trump, leads its first card and follows by rule. So with
/// the deck in a fixed order the hand goes the same way every time, apart
/// from what the player chooses, which the coaching follows.
class TutorialController extends OfflineGameController {
  TutorialController()
      : super(
          nickname: Settings.instance.nickname,
          bots: 2,
          opponents: [
            for (final name in [announceBotNames[0](), announceBotNames[1]()])
              GamePlayer(name, 0, false)..skill = BotSkill.regular,
          ],
        ) {
    _coachTimer = Timer.periodic(const Duration(milliseconds: 150), (_) => _update());
    _update();
  }

  /// One line on what's happening and what to do; null once the hand is over.
  final ValueNotifier<String?> coach = ValueNotifier(null);

  /// Whether the practice hand has been played out.
  final ValueNotifier<bool> done = ValueNotifier(false);

  late final Timer _coachTimer;

  @override
  String get label => dialogsTutorialLabel();

  @override
  String get kind => 'tutorial';

  @override
  bool get revealHands => true;

  @override
  void dispose() {
    _coachTimer.cancel();
    super.dispose();
  }

  /// Deals the stacked hand. After it there's nothing more to deal.
  @override
  Future<void> deal() async {
    if (game.handNumber > 0) return;
    game.deck = GameCardDeck()..contents = [for (final (suit, value) in stackedDeck) GameCard(suit, value)];
    // Like any offline deal, this returns at once; the hand plays out on its own
    unawaited(game.deal(shuffle: false));
  }

  /// The deck, top first: [_stacked], then every other card in suit order.
  @visibleForTesting
  static final List<(Suit, Value)> stackedDeck = [
    ..._stacked,
    for (final suit in Suit.values)
      for (final value in Value.values)
        if (!_stacked.contains((suit, value))) (suit, value),
  ];

  /// The player deals, so the cards go round starting with the first bot;
  /// the player's last card is turned up for trump; and swapping, then the
  /// first trick, start with the first bot.
  ///
  /// - Spades are trump. The player holds the king and the seven.
  /// - The player has two low cards to swap (4♣, 3♦) and draws 10♦ and 5♣:
  ///   no better, so they'll lose a trick or two and the bots lead again.
  /// - The first bot leads the queen of hearts; the player's ace of hearts
  ///   has to follow, and takes it.
  static const List<(Suit, Value)> _stacked = [
    // Dealt round: first bot, second bot, player; five times
    (Suit.clubs, Value.eight), (Suit.diamonds, Value.two), (Suit.hearts, Value.ace),
    (Suit.diamonds, Value.six), (Suit.clubs, Value.three), (Suit.clubs, Value.four),
    (Suit.clubs, Value.nine), (Suit.hearts, Value.ten), (Suit.spades, Value.king),
    (Suit.hearts, Value.queen), (Suit.clubs, Value.six), (Suit.diamonds, Value.three),
    (Suit.hearts, Value.five), (Suit.hearts, Value.eight), (Suit.spades, Value.seven),
    // Swaps, in turn: the first bot's three, the second bot's three, then the
    // player's
    (Suit.diamonds, Value.king), (Suit.clubs, Value.two), (Suit.spades, Value.four),
    (Suit.diamonds, Value.nine), (Suit.clubs, Value.queen), (Suit.hearts, Value.four),
    (Suit.diamonds, Value.ten), (Suit.clubs, Value.five), (Suit.diamonds, Value.queen),
  ];

  void _update() {
    final finished = game.handNumber > 0 &&
        (game.state.value == GameState.waitingToDeal || game.state.value == GameState.gameOver);
    if (finished && !done.value) done.value = true;
    final line = finished ? null : coachLine();
    if (line != coach.value) coach.value = line;
  }

  /// The coaching for the table as it is now.
  @visibleForTesting
  String? coachLine() {
    final local = localPlayer;
    final trump = game.trumpSuit.value;
    switch (game.state.value) {
      case GameState.waitingToDeal:
      case GameState.waitingForPlayers:
        return dialogsCoachDeal();
      case GameState.dealing:
        return dialogsCoachDealing.of('n', cardsPerHand);
      case GameState.waitingForPlayerToSwap:
        final junk = local.hand.cards.value
            .where((card) => card.suit != trump && valueToScore[card.value]! < valueToScore[Value.jack]!)
            .toList()
          ..sort((a, b) => valueToScore[a.value]!.compareTo(valueToScore[b.value]!));
        // The swap button's own label, as it reads once those cards are marked
        if (junk.isEmpty) return dialogsCoachKeep.of('button', tableKeepHand());
        final cards = junk.take(maxSwaps).toList();
        return dialogsCoachSwap({
          'n': maxSwaps,
          'button': tableSwapCount.of('n', cards.length),
          'cards': cards.map(cardName).join(', '),
        });
      case GameState.waitingToSwap:
      case GameState.swapping:
        final active = game.activePlayerLazy;
        if (active == local) return null;
        return dialogsCoachBotSwap({'suit': suitToString[trump], 'name': active.name});
      default:
        return _playLine(local, trump);
    }
  }

  String? _playLine(GamePlayer local, Suit trump) {
    final table = game.table.cards.value;
    final inPlay = game.players.where((player) => !player.skip).length;
    final winner = game.lastTrickWinner;
    if (table.isNotEmpty && table.length >= inPlay && winner != null) {
      return winner == local
          ? dialogsCoachYouTook.of('score', local.score.value)
          : dialogsCoachBotTook.of('name', winner.name);
    }
    if (local.skip) return dialogsCoachFolded();
    if (!canPlayNow) {
      final active = game.activePlayerLazy;
      return active == local ? null : dialogsCoachBotPlays.of('name', active.name);
    }
    final lead = game.leadingCard?.suit;
    if (table.isEmpty || lead == null) return dialogsCoachLead();
    final hand = local.hand.cards.value;
    int score(GameCard card) => scoreFor(card, lead: lead, trump: trump);
    final best = table.reduce((a, b) => score(a) >= score(b) ? a : b);
    final leadName = _capitalise(suitToString[lead]!);
    final following = hand.where((card) => card.suit == lead).toList();
    final options = following.isNotEmpty ? following : hand;
    final winners = options.where((card) => score(card) > score(best)).toList()
      ..sort((a, b) => score(a).compareTo(score(b)));
    if (following.isNotEmpty) {
      return winners.isNotEmpty
          ? dialogsCoachFollowWin({'suit': leadName, 'card': cardName(winners.first)})
          : dialogsCoachFollowLose({'suit': leadName, 'best': cardName(best)});
    }
    return winners.isNotEmpty
        ? dialogsCoachTrump({'suit': suitToString[lead], 'card': cardName(winners.first)})
        : dialogsCoachDiscard.of('suit', suitToString[lead]);
  }

  static String _capitalise(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  /// A card as it's printed: J♥, 10♠.
  static String cardName(GameCard card) {
    final rank = switch (card.value) {
      Value.ace => 'A',
      Value.king => 'K',
      Value.queen => 'Q',
      Value.jack => 'J',
      _ => '${valueToScore[card.value]}',
    };
    final suit = switch (card.suit) {
      Suit.spades => '♠',
      Suit.hearts => '♥',
      Suit.diamonds => '♦',
      Suit.clubs => '♣',
    };
    return '$rank$suit';
  }
}
