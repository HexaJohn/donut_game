import 'dart:async';

import 'package:donut_game/audio/flashbang.dart';
import 'package:donut_game/audio/music_player.dart';
import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/data/model/chat_message.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/modes/bad_batch/bb_screen.dart';
import 'package:donut_game/modes/game_mode.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/action_bar.dart';
import 'package:donut_game/ui/game/announcer.dart';
import 'package:donut_game/ui/game/board.dart';
import 'package:donut_game/ui/game/chat_panel.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:donut_game/ui/widget/game_clock.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:donut_game/ui/widget/suit_icon.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller, this.onModeSwitch});

  final GameController controller;

  /// Called when an online server switches the table to another game.
  final ModeSwitcher? onModeSwitch;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final Timer _ticker;
  final _announcer = Announcer();

  /// Bumped when the game changes; only the board and action bar listen, so
  /// the title bar, clock and chat panel aren't rebuilt with every move.
  final _revision = ValueNotifier(0);

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

  GameController get controller => widget.controller;
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
    controller.switchedTo.addListener(_onSwitch);
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
    controller.switchedTo.removeListener(_onSwitch);
    _sources?.removeListener(_onModelChanged);
    _announcer.dispose();
    _revision.dispose();
    _fuse.dispose();
    _whiteout.dispose();
    // Never leave the game deafened if we leave mid-bang
    audioDuck.value = 1;
    controller.dispose();
    // Back to the menus
    MusicPlayer.instance.playMenu();
    super.dispose();
  }

  void _onSwitch() {
    final mode = controller.switchedTo.value;
    if (mode != null && mode != GameMode.donut && mounted) widget.onModeSwitch?.call(context, mode);
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
    return Scaffold(
      body: Column(
        children: [
          DonutTitleBar(
            title: controller.label,
            trailing: GameClock(elapsed: () => game.matchElapsed),
          ),
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
            child: Row(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: _revision,
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
                                child: champion == null ? const SizedBox() : _MatchOverOverlay(controller: controller),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ChatPanel(
                  chat: game.chat,
                  localName: controller.localPlayer?.name,
                  onSend: controller.sendChat,
                  open: _chatOpen,
                  onClose: () => setState(() => _chatOpen = false),
                ),
              ],
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
  const _MatchOverOverlay({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    final game = controller.game;
    final champion = game.champion.value!;
    final youWon = champion.name == controller.localPlayer?.name;
    final standings = [...game.players]..sort((a, b) => a.score.value.compareTo(b.score.value));

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: colors.accent.withValues(alpha: 0.4), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DonutLogo(size: 84, frosting: colors.accent),
              const SizedBox(height: 12),
              Text(youWon ? 'You win!' : '${champion.name} wins!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Match time ${formatDuration(game.matchElapsed)}',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 20),
              for (var i = 0; i < standings.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child:
                            Text('${i + 1}.', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
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
              const SizedBox(height: 20),
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}
