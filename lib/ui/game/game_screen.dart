import 'dart:async';

import 'package:donut_game/audio/flashbang.dart';
import 'package:donut_game/audio/music_player.dart';
import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/campaign/campaign.dart';
import 'package:donut_game/campaign/campaign_controller.dart';
import 'package:donut_game/data/model/chat_message.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/progression/rewards.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/campaign/campaign_screen.dart';
import 'package:donut_game/ui/career/match_rewards.dart';
import 'package:donut_game/ui/game/action_bar.dart';
import 'package:donut_game/ui/game/announcer.dart';
import 'package:donut_game/ui/game/board.dart';
import 'package:donut_game/ui/game/chat_panel.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/home/routes.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:donut_game/ui/widget/game_clock.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:donut_game/ui/widget/suit_icon.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final Timer _ticker;
  final _announcer = Announcer();

  /// Bumped when the game changes; only the board and action bar listen, so
  /// the title bar, clock and chat panel aren't rebuilt with every move.
  final _revision = ValueNotifier(0);

  /// The board also redraws when campaign scenery is switched, which can
  /// happen mid-match from the theme picker while nothing else moves.
  late final Listenable _boardChanges = Listenable.merge([_revision, Settings.instance.venueScenery]);

  /// Flashbang: where it's fizzing before it goes off, and the white-out.
  final ValueNotifier<Offset?> _fuse = ValueNotifier(null);
  late final AnimationController _whiteout = AnimationController(vsync: this, duration: FlashbangAudio.length);
  int _lastFlashSerial = 0;
  static const _fuseTime = Duration(milliseconds: 900);
  String _fingerprint = '';
  bool _chatOpen = false;
  int _seenChat = 0;

  // Previous values, to spot what just changed
  GameState? _lastState;
  int _lastTrick = 0;
  bool _lastSwapTurn = false;
  bool _lastPlayTurn = false;
  bool _lastSuddenDeath = false;
  int _trumpShownForHand = -1;
  Map<String, int> _lastDonuts = {};

  /// Career rewards for the match just finished, banked once per match.
  MatchOutcome? _outcome;
  bool _awarded = false;
  bool _inSuddenDeath = false;

  /// Set when this screen gives way straight to another game.
  bool _handedOff = false;

  GameController get controller => widget.controller;
  CampaignGameController? get _campaign => switch (controller) { CampaignGameController c => c, _ => null };
  Game get game => controller.game;

  /// Notifiers in the model that fire the moment something moves, so the
  /// board reacts on the same frame instead of waiting for the next poll.
  Listenable? _sources;
  List<GamePlayer> _sourcePlayers = [];
  bool _tickQueued = false;

  void _subscribe() {
    _sources?.removeListener(_onModelChanged);
    _sourcePlayers = game.players;
    _sources = Listenable.merge([
      game.state,
      game.table.cards,
      game.discard.cards,
      game.trumpSuit,
      game.champion,
      game.chat,
      game.holes,
      game.spins,
      for (final player in _sourcePlayers) ...[player.hand.cards, player.score, player.winner],
    ])
      ..addListener(_onModelChanged);
  }

  void _onModelChanged() {
    // Several notifiers can fire for one move; check once they're all done
    if (_tickQueued) return;
    _tickQueued = true;
    scheduleMicrotask(() {
      _tickQueued = false;
      if (mounted) _tick();
    });
  }

  @override
  void initState() {
    super.initState();
    controller.start();
    SoundEffects.instance.preload();
    FlashbangAudio.instance.preload();
    // Only bangs from now on; joining mid-game doesn't replay old ones
    _lastFlashSerial = game.flashSerial;
    MusicPlayer.instance.playGame();
    _lastMessage = game.chat.value.isEmpty ? null : game.chat.value.last;
    _lastTrick = game.trickSerial;
    _seenChat = game.chat.value.length;
    _subscribe();
    // Some model fields are plain values with no notifier, so also poll
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker.cancel();
    _sources?.removeListener(_onModelChanged);
    _announcer.dispose();
    _revision.dispose();
    _fuse.dispose();
    _whiteout.dispose();
    // Never leave the game deafened if we leave mid-bang
    audioDuck.value = 1;
    controller.dispose();
    // Back to the menus, unless the next campaign stage is already playing
    if (!_handedOff) MusicPlayer.instance.playMenu();
    super.dispose();
  }

  void _tick() {
    final players = game.players;
    if (players.length != _sourcePlayers.length ||
        [for (var i = 0; i < players.length; i++) identical(players[i], _sourcePlayers[i])].contains(false)) {
      _subscribe();
    }
    final fingerprint = _snapshot();
    if (fingerprint == _fingerprint) return;
    _fingerprint = fingerprint;
    _detectEvents();
    if (_chatOpen) _seenChat = game.chat.value.length;
    _revision.value++;
  }

  String _snapshot() {
    final buffer = StringBuffer()
      ..write(game.state.value.index)
      ..write('|${game.players.isEmpty ? -1 : game.protectedActive}|${game.protectedDealer}')
      ..write('|${game.trumpSuit.value.index}|${game.trickSerial}|${game.handNumber}')
      ..write('|${game.champion.value?.name}|${game.suddenDeath.length}|${game.chat.value.length}')
      ..write('|${game.leadingCard}|${game.deck.contents.length}|F${game.flashSerial}${controller.flashReady}')
      ..write(
          '|H${game.holes.value.length}${game.holes.value.isEmpty ? '' : game.holes.value.last.seed}|S${game.spins.value}');
    for (final card in game.deck.contents.take(3)) {
      buffer.write(card);
    }
    for (final card in game.table.cards.value) {
      buffer.write('T$card${card.belongsTo?.name}');
    }
    final discard = game.discard.cards.value;
    buffer.write('|D${discard.length}');
    for (final card in discard.skip(discard.length > 3 ? discard.length - 3 : 0)) {
      buffer.write(card);
    }
    for (final player in game.players) {
      buffer.write('|P${player.name}${player.score.value},${player.tricks},${player.donuts.value},'
          '${player.skip},${player.folds},${player.voteToDeal},${player.notReady},${player.swaps.value},'
          '${player.winner.value},${player.cardToPlay}');
      for (final card in player.hand.cards.value) {
        buffer.write('$card${card.state.index}');
      }
    }
    // Chat bubbles expire, so count the ones still showing
    final now = DateTime.now();
    buffer.write('|B${game.chat.value.where((m) => !m.system && now.difference(m.time) < chatBubbleLife).length}');
    buffer.write(controller.error.value);
    return buffer.toString();
  }

  void _detectEvents() {
    final state = game.state.value;
    final local = controller.localPlayer;

    _detectChat();
    _detectFlashbang();
    _detectMatchEnd();

    if (state != _lastState) {
      if (state == GameState.dealing) {
        SoundEffects.instance.play(Sfx.shuffle);
        final dealer = game.players.isEmpty ? null : game.dealer.value;
        _announcer.announce(Announcement(
          game.suddenDeath.isNotEmpty ? 'Sudden death' : 'Hand ${game.handNumber}',
          subtitle: dealer == null ? null : (dealer == local ? 'You deal' : '${dealer.name} deals'),
          icon: DonutLogo(size: 34, frosting: DonutColors.of(context).accent, shadow: false),
        ));
      }
      final pastDeal =
          state == GameState.waitingToSwap || state == GameState.swapping || state == GameState.waitingForPlayerToSwap;
      if (pastDeal && _trumpShownForHand != game.handNumber) {
        _trumpShownForHand = game.handNumber;
        final suit = game.trumpSuit.value;
        final colors = DonutColors.of(context);
        _announcer.announce(Announcement(
          'Trump is ${_capitalise(suitToString[suit]!)}',
          subtitle: 'Beats every other suit this hand',
          icon: SuitIcon(suit, size: 32, color: isRed(suit) ? colors.cardRed : colors.cardInk),
        ));
      }
      if (state == GameState.waitingToDeal &&
          _lastState != null &&
          _lastState != GameState.waitingToDeal &&
          _lastState != GameState.waitingForPlayers &&
          _lastState != GameState.gameOver) {
        final donuts = game.players.where((element) => element.donuts.value > (_lastDonuts[element.name] ?? 0));
        _announcer.announce(Announcement(
          'Hand over',
          subtitle: donuts.isEmpty
              ? 'No donuts this hand'
              : '\u{1F369} ${donuts.map((e) => e == local ? 'You' : e.name).join(', ')} got a donut',
        ));
      }
      if (state == GameState.dealing || state == GameState.waitingToDeal) {
        _lastDonuts = {for (final player in game.players) player.name: player.donuts.value};
      }
      _lastState = state;
    }

    final suddenDeath = game.suddenDeath.isNotEmpty;
    if (suddenDeath && !_lastSuddenDeath) {
      _announcer.announce(Announcement('Sudden death!',
          subtitle: '${game.suddenDeath.join(' vs ')}. Fewest tricks is out.', urgent: true));
    }
    _lastSuddenDeath = suddenDeath;

    if (game.trickSerial > _lastTrick && game.lastTrickWinner != null) {
      final winner = game.lastTrickWinner!;
      _announcer.announce(Announcement(winner.name == local?.name ? 'You take the trick!' : '${winner.name} takes it'));
    }
    _lastTrick = game.trickSerial;

    final myTurn = local != null && !local.skip && controller.isLocalTurn;
    final swapTurn = myTurn && state == GameState.waitingForPlayerToSwap && local.notReady;
    if (swapTurn && !_lastSwapTurn) {
      SoundEffects.instance.play(Sfx.yourMove);
      _announcer
          .announce(Announcement('Your move', subtitle: 'Tap up to $maxSwaps cards to swap, or fold', urgent: true));
    }
    _lastSwapTurn = swapTurn;

    final playTurn = myTurn && controller.canPlayNow;
    if (playTurn && !_lastPlayTurn) {
      SoundEffects.instance.play(Sfx.yourTurn);
      final lead = game.leadingCard?.suit;
      _announcer.announce(Announcement('Your turn',
          subtitle: lead == null ? 'Lead with any card' : 'Follow ${suitToString[lead]} if you can', urgent: true));
    }
    _lastPlayTurn = playTurn;
  }

  /// Banks XP and currency the moment an offline match is decided.
  void _detectMatchEnd() {
    final local = controller.localPlayer;
    final champion = game.champion.value;
    if (local != null && game.suddenDeath.contains(local)) _inSuddenDeath = true;
    if (champion == null) {
      // A new match: ready to pay out again
      if (_awarded && game.state.value != GameState.gameOver) {
        _awarded = false;
        _outcome = null;
        _inSuddenDeath = false;
      }
      return;
    }
    if (_awarded || controller.online || local == null) return;
    _awarded = true;
    final standings = [...game.players]..sort((a, b) => a.score.value.compareTo(b.score.value));
    standings
      ..remove(champion)
      ..insert(0, champion);
    final profile = PlayerProfile.instance;
    final campaign = _campaign;
    final won = champion == local;
    _outcome = MatchOutcome.awardDonut(
      profile,
      DonutMatchSummary(
        placement: standings.indexOf(local) + 1,
        players: game.players.length,
        tricks: local.matchTricks,
        donuts: local.donuts.value,
        hands: game.handNumber,
        suddenDeath: _inSuddenDeath,
        duration: game.matchElapsed,
        firstWinToday: profile.firstWinTodayAvailable,
      ),
      extra: campaign != null && won
          ? stageClearRewards(campaign.stage, campaign.difficulty, profile.bestClear(campaign.stage))
          : const [],
    );
    if (campaign != null) {
      if (won) {
        profile.recordStageClear(campaign.stage, campaign.difficulty);
      } else {
        campaign.gloat(champion.name);
      }
    }
  }

  /// Opens [stage] in place of this match.
  void _playStage(Stage stage, Difficulty difficulty) {
    _handedOff = true;
    Navigator.pushReplacement(
        context, gameRoute(GameScreen(controller: CampaignGameController(stage: stage, difficulty: difficulty))));
  }

  void _detectFlashbang() {
    if (game.flashSerial == _lastFlashSerial) return;
    _lastFlashSerial = game.flashSerial;
    final serial = game.flashSerial;
    _fuse.value = game.flashAt;
    Future.delayed(_fuseTime, () {
      // A newer throw takes over this one
      if (!mounted || serial != game.flashSerial) return;
      _fuse.value = null;
      FlashbangAudio.instance.detonate();
      _whiteout.forward(from: 0);
    });
  }

  ChatMessage? _lastMessage;

  /// Coughs once when a player, human or bot, sends a chat message.
  void _detectChat() {
    final messages = game.chat.value;
    if (messages.isEmpty || identical(messages.last, _lastMessage)) return;
    // Everything after the last message we saw is new; the log is capped, so
    // look it up rather than trusting the length
    final seenAt = _lastMessage == null ? -1 : messages.lastIndexWhere((m) => identical(m, _lastMessage));
    final fresh = seenAt < 0 && _lastMessage != null ? [messages.last] : messages.skip(seenAt + 1);
    // Any player's message, bots' quips included; game event lines stay quiet
    if (_lastMessage != null && fresh.any((m) => !m.system)) SoundEffects.instance.play(Sfx.cough);
    _lastMessage = messages.last;
  }

  String _capitalise(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  int get _unread {
    final local = controller.localPlayer?.name;
    final messages = game.chat.value;
    var count = 0;
    for (var i = _seenChat.clamp(0, messages.length); i < messages.length; i++) {
      if (!messages[i].system && messages[i].author != local) count++;
    }
    return count;
  }

  Future<void> _leave() async {
    final finished = game.state.value == GameState.gameOver;
    final leave = finished ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Leave the game?'),
                content:
                    Text(controller.online ? 'You can rejoin with the same nickname.' : 'This match will be lost.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
                ],
              ),
            ) ==
            true;
    if (leave && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Pure white for a moment, then it slowly comes back
    final whiteness = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1), weight: 24),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 76),
    ]).animate(_whiteout);
    return Stack(
      children: [
        _buildScreen(context),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _whiteout,
              builder: (context, _) => _whiteout.isAnimating
                  ? ColoredBox(color: Colors.white.withValues(alpha: whiteness.value))
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreen(BuildContext context) {
    // The system back button asks first, like Leave in the menu
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DonutTitleBar(
            title: controller.label,
            trailing: GameClock(elapsed: () => game.matchElapsed),
          ),
          PartyCodeBanner(controller: controller),
          ValueListenableBuilder(
            valueListenable: controller.error,
            builder: (context, String? error, _) => AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: error == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.errorContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 18, color: Theme.of(context).colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Text(error, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                        ],
                      ),
                    ),
            ),
          ),
          Expanded(
            child: ChatLayout(
              table: ListenableBuilder(
                listenable: _boardChanges,
                builder: (context, _) {
                  final champion = game.champion.value;
                  return Stack(
                    children: [
                      Positioned.fill(child: GameBoard(controller: controller, announcer: _announcer, fuse: _fuse)),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: champion == null,
                          child: AnimatedOpacity(
                            opacity: champion == null ? 0 : 1,
                            duration: const Duration(milliseconds: 500),
                            child: champion == null
                                ? const SizedBox()
                                : _MatchOverOverlay(controller: controller, outcome: _outcome, onPlayStage: _playStage),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              panel: (width) => ChatPanel(
                chat: game.chat,
                localName: controller.localPlayer?.name,
                onSend: controller.sendChat,
                open: _chatOpen,
                onClose: () => setState(() => _chatOpen = false),
                width: width,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _revision,
            builder: (context, _) => ActionBar(
              controller: controller,
              chatOpen: _chatOpen,
              unread: _unread,
              onToggleChat: () => setState(() {
                _chatOpen = !_chatOpen;
                _seenChat = game.chat.value.length;
              }),
              onLeave: _leave,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchOverOverlay extends StatelessWidget {
  const _MatchOverOverlay({required this.controller, required this.outcome, required this.onPlayStage});

  final GameController controller;
  final void Function(Stage stage, Difficulty difficulty) onPlayStage;

  /// Null online, where there's nothing to pay.
  final MatchOutcome? outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    final game = controller.game;
    final champion = game.champion.value!;
    final youWon = champion.name == controller.localPlayer?.name;
    final campaign = switch (controller) { CampaignGameController c => c, _ => null };
    final next = campaign == null ? null : nextStage(campaign.stage);
    final standings = [...game.players]..sort((a, b) => a.score.value.compareTo(b.score.value));

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: colors.accent.withValues(alpha: 0.4), blurRadius: 40)],
            ),
            child: MatchOverFlow(
              outcome: outcome,
              header: Column(
                children: [
                  DonutLogo(size: 84, frosting: colors.accent),
                  const SizedBox(height: 12),
                  Text(youWon ? 'You win!' : '${champion.name} wins!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  if (campaign != null) ...[
                    _StageResult(campaign: campaign, cleared: youWon),
                    const SizedBox(height: 4),
                  ],
                  Text('Match time ${formatDuration(game.matchElapsed)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
              standings: Column(
                children: [
                  for (var i = 0; i < standings.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text('${i + 1}.',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          PlayerAvatar(player: standings[i], size: 28),
                          const SizedBox(width: 10),
                          Expanded(child: Text(standings[i].name, overflow: TextOverflow.ellipsis)),
                          if (standings[i].donuts.value > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text('\u{1F369}${standings[i].donuts.value}'),
                            ),
                          Text('${standings[i].score.value}',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
              actions: campaign != null
                  ? _StageActions(
                      onCampaign: () => Navigator.pop(context),
                      onRetry: controller.newMatch,
                      onNext: youWon && next != null ? () => onPlayStage(next, campaign.difficulty) : null,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Main menu'),
                          ),
                        ),
                        if (!controller.online) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(onPressed: controller.newMatch, child: const Text('Play again')),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Under the headline after a campaign match: the stage, the difficulty and
/// the stars it earned.
class _StageResult extends StatelessWidget {
  const _StageResult({required this.campaign, required this.cleared});

  final CampaignGameController campaign;
  final bool cleared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficulty = campaign.difficulty;
    return Column(
      children: [
        Text(
          cleared
              ? '${campaign.stage.boss ? 'Boss defeated' : 'Stage cleared'} on ${difficulty.label}'
              : '${campaign.stage.name} on ${difficulty.label}',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
        ),
        if (cleared) ...[
          const SizedBox(height: 4),
          StageStars(stars: difficulty.stars, size: 22),
        ],
      ],
    );
  }
}

/// Campaign, Retry and, after a win, Next stage: three buttons in a narrow
/// panel, so labels stay on one line and shrink rather than wrap.
class _StageActions extends StatelessWidget {
  const _StageActions({required this.onCampaign, required this.onRetry, this.onNext});

  final VoidCallback onCampaign;
  final VoidCallback onRetry;

  /// Null when there's no next stage to go to.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 10);
    Widget label(String text) => FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1, softWrap: false));
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: padding), onPressed: onCampaign, child: label('Campaign')),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: onNext != null
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: padding), onPressed: onRetry, child: label('Retry'))
              : FilledButton(
                  style: FilledButton.styleFrom(padding: padding), onPressed: onRetry, child: label('Retry')),
        ),
        if (onNext != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
                style: FilledButton.styleFrom(padding: padding), onPressed: onNext, child: label('Next stage')),
          ),
        ],
      ],
    );
  }
}

/// The party's code, shown in the lobby so the host can pass it on.
class PartyCodeBanner extends StatelessWidget {
  const PartyCodeBanner({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([controller.party, controller.game.state]),
      builder: (context, _) {
        final code = controller.partyCode;
        final game = controller.game;
        final lobby = game.handNumber == 0 || game.champion.value != null;
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: code == null || !lobby
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  color: theme.colorScheme.secondaryContainer,
                  padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                  child: Row(
                    children: [
                      Text('Party code', style: theme.textTheme.labelLarge),
                      const SizedBox(width: 10),
                      Text(code,
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.maybeOf(context)
                              ?.showSnackBar(const SnackBar(content: Text('Copied. Send it to your friends.')));
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
