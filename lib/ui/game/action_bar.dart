import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/board.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/widget/dialogs.dart';
import 'package:flutter/material.dart';

enum _MenuAction { rules, theme, sound, addBot, removeBot, restart, leave }

class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.controller,
    required this.chatOpen,
    required this.unread,
    required this.onToggleChat,
    required this.onLeave,
  });

  final GameController controller;
  final bool chatOpen;
  final int unread;
  final VoidCallback onToggleChat;
  final VoidCallback onLeave;

  Game get game => controller.game;

  /// Below this width the bar splits into two rows.
  static const double compactWidth = 620;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    final theme = Theme.of(context);
    final (status, needsYou) = _status();
    final decoration = BoxDecoration(
      color: colors.chrome,
      border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < compactWidth) {
        // Phone: what's happening on top, you and your moves underneath
        final buttons = _buttons(context);
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
          decoration: decoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chat and menu up here, so the moves get the whole row below
              Row(children: [
                Expanded(child: _StatusPill(text: status, needsYou: needsYou)),
                _chatButton(),
                _menu(context),
              ]),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    _you(context, compact: true),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Buttons shrink rather than push off the edge
                          for (final button in buttons)
                            button is SizedBox
                                ? button
                                : Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: button)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      // Slimmer on short screens, where every row of the table counts
      final short = MediaQuery.sizeOf(context).height < 480;
      return Container(
        height: short ? 60 : 76,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: decoration,
        child: Row(
          children: [
            SizedBox(width: 230, child: _you(context)),
            const SizedBox(width: 16),
            // What's happening
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: _StatusPill(text: status, needsYou: needsYou)),
                  const SizedBox(width: 12),
                  ..._buttons(context),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _chatButton(),
            const SizedBox(width: 4),
            _menu(context),
          ],
        ),
      );
    });
  }

  /// Your avatar, name, tricks and score. [compact] keeps just the avatar
  /// and score.
  Widget _you(BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context);
    final local = controller.localPlayer;
    if (local == null) return Text('Spectating', style: theme.textTheme.bodyMedium);
    final avatar = PlayerAvatar(
        player: local, size: compact ? 34 : 40, dealer: game.players.isNotEmpty && game.dealer.value == local);
    return AnimatedRotation(
      turns: (game.spins.value[local.name] ?? 0).toDouble(),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutBack,
      child: compact
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScoreText(score: local.score.value, size: 22),
                    TrickPips(tricks: local.tricks, donuts: local.donuts.value),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(local.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      TrickPips(tricks: local.tricks, donuts: local.donuts.value),
                    ],
                  ),
                ),
                ScoreText(score: local.score.value, size: 26),
              ],
            ),
    );
  }

  Widget _chatButton() => Badge(
        isLabelVisible: unread > 0 && !chatOpen,
        label: Text('$unread'),
        child: IconButton.filledTonal(
          tooltip: chatOpen ? 'Hide chat' : 'Chat',
          isSelected: chatOpen,
          onPressed: onToggleChat,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: const Icon(Icons.chat_bubble_rounded),
        ),
      );

  Widget _menu(BuildContext context) => PopupMenuButton<_MenuAction>(
        tooltip: 'Menu',
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (action) => _onMenu(context, action),
        itemBuilder: (context) => [
          const PopupMenuItem(
              value: _MenuAction.rules,
              child: ListTile(leading: Icon(Icons.menu_book_rounded), title: Text('How to play'))),
          const PopupMenuItem(
              value: _MenuAction.theme, child: ListTile(leading: Icon(Icons.palette_outlined), title: Text('Theme'))),
          const PopupMenuItem(
              value: _MenuAction.sound, child: ListTile(leading: Icon(Icons.tune_rounded), title: Text('Settings'))),
          if (controller.canManageBots) ...[
            const PopupMenuItem(
                value: _MenuAction.addBot,
                child: ListTile(leading: Icon(Icons.smart_toy_rounded), title: Text('Add a bot'))),
            if (game.players.any((player) => !player.human))
              const PopupMenuItem(
                  value: _MenuAction.removeBot,
                  child: ListTile(leading: Icon(Icons.person_remove_rounded), title: Text('Remove a bot'))),
          ],
          if (controller.canRestart)
            PopupMenuItem(
                value: _MenuAction.restart,
                child: ListTile(
                    leading: const Icon(Icons.restart_alt_rounded),
                    title: Text(controller.online && controller.partyCode == null ? 'Restart server game' : 'Restart match'))),
          const PopupMenuDivider(),
          const PopupMenuItem(
              value: _MenuAction.leave,
              child: ListTile(leading: Icon(Icons.logout_rounded), title: Text('Leave game'))),
        ],
      );

  Future<void> _onMenu(BuildContext context, _MenuAction action) async {
    switch (action) {
      case _MenuAction.rules:
        showRulesDialog(context);
      case _MenuAction.theme:
        showThemePicker(context);
      case _MenuAction.sound:
        showSoundSettings(context);
      case _MenuAction.addBot:
        controller.addBot();
      case _MenuAction.removeBot:
        controller.removeBot();
      case _MenuAction.restart:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(controller.online ? 'Restart the server game?' : 'Restart the match?'),
            content: Text(controller.online
                ? 'Everyone at the table goes back to the lobby and scores are wiped.'
                : 'Scores go back to ${controller.game.targetScore} and a new match starts.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restart')),
            ],
          ),
        );
        if (confirmed == true) {
          if (!controller.online) controller.game.abort();
          controller.newMatch();
        }
      case _MenuAction.leave:
        onLeave();
    }
  }

  (String, bool) _status() {
    final local = controller.localPlayer;
    final state = game.state.value;
    final myTurn = controller.isLocalTurn && local != null && !local.skip;
    final activeName = game.players.isEmpty ? '' : game.activePlayerLazy.name;
    switch (state) {
      case GameState.waitingForPlayers:
        return ('Waiting for players to join', false);
      case GameState.waitingToDeal:
        if (!controller.online) return ('Ready when you are', true);
        final humans = game.players.where((element) => element.human).toList();
        final ready = humans.where((element) => element.voteToDeal).length;
        return ('Waiting for players to be ready ($ready/${humans.length})', !(local?.voteToDeal ?? true));
      case GameState.dealing:
        return ('Dealing', false);
      case GameState.waitingToSwap:
      case GameState.swapping:
      case GameState.waitingForPlayerToSwap:
        if (local?.skip == true && state != GameState.waitingForPlayerToSwap) return ('You folded this hand', false);
        if (myTurn && state == GameState.waitingForPlayerToSwap && local.notReady) {
          final marked = local.hand.cards.value.where((element) => element.state == CardState.swap).length;
          return ('Your move: pick up to $maxSwaps cards to swap ($marked picked)', true);
        }
        return ('$activeName is choosing swaps', false);
      case GameState.playing:
      case GameState.waitingForPlayer:
        if (local?.skip == true) return ('You folded this hand', false);
        if (controller.canPlayNow) {
          return (game.leadingCard == null ? 'Your lead: play any card' : 'Your turn: follow suit if you can', true);
        }
        if (myTurn) return ('Next trick coming up', false);
        return ('Waiting for $activeName', false);
      case GameState.waitingForNextRound:
        return ('Next trick', false);
      case GameState.gameOver:
        final champion = game.champion.value;
        return (champion == null ? 'Match over' : '${champion.name} won the match', false);
      default:
        return ('', false);
    }
  }

  List<Widget> _buttons(BuildContext context) {
    final local = controller.localPlayer;
    final state = game.state.value;
    if (local == null) return [];

    if (state == GameState.waitingToDeal) {
      if (!controller.online) {
        return [
          FilledButton.icon(
              onPressed: controller.deal, icon: const Icon(Icons.style_rounded), label: const Text('Deal'))
        ];
      }
      return [
        local.voteToDeal
            ? OutlinedButton.icon(
                onPressed: controller.deal, icon: const Icon(Icons.check_rounded), label: const Text('Ready'))
            : FilledButton.icon(
                onPressed: controller.deal, icon: const Icon(Icons.style_rounded), label: const Text("I'm ready")),
      ];
    }

    if (state == GameState.waitingForPlayerToSwap && controller.isLocalTurn && local.notReady && !local.skip) {
      final marked = local.hand.cards.value.where((element) => element.state == CardState.swap).length;
      final foldBlocked = !controller.canFold;
      return [
        Tooltip(
          message: foldBlocked
              ? (game.suddenDeath.isNotEmpty
                  ? 'No folding in sudden death'
                  : 'You folded the last $maxConsecutiveFolds hands')
              : 'Sit this hand out. No tricks, but no donut either.',
          child: OutlinedButton.icon(
            onPressed: foldBlocked ? null : controller.fold,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Fold'),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: controller.confirmSwap,
          icon: Icon(marked == 0 ? Icons.check_rounded : Icons.swap_horiz_rounded),
          label: Text(marked == 0 ? 'Keep hand' : 'Swap $marked'),
        ),
      ];
    }

    if (state == GameState.gameOver && !controller.online) {
      return [
        FilledButton.icon(
            onPressed: controller.newMatch, icon: const Icon(Icons.replay_rounded), label: const Text('New match'))
      ];
    }
    return [];
  }
}

class _StatusPill extends StatefulWidget {
  const _StatusPill({required this.text, required this.needsYou});

  final String text;
  final bool needsYou;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900), value: 1);

  @override
  void initState() {
    super.initState();
    if (widget.needsYou) _startPulse();
  }

  @override
  void didUpdateWidget(_StatusPill old) {
    super.didUpdateWidget(old);
    if (widget.needsYou && !old.needsYou) _startPulse();
    if (!widget.needsYou && old.needsYou) _pulse.value = 1;
  }

  /// A few pulses to catch the eye, then the dot holds steady. A pulse left
  /// running would redraw the whole screen every frame for as long as the
  /// game waits on you, which heats a phone until it slows down.
  void _startPulse() {
    _pulse.repeat(reverse: true, count: 6).whenCompleteOrCancel(() {
      if (mounted) _pulse.value = 1;
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    final color = widget.needsYou ? colors.accent : theme.colorScheme.onSurface.withValues(alpha: 0.45);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.needsYou ? colors.accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: widget.needsYou ? Tween(begin: 0.3, end: 1.0).animate(_pulse) : const AlwaysStoppedAnimation(1),
            child: Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                widget.text,
                key: ValueKey(widget.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: widget.needsYou ? FontWeight.w700 : FontWeight.w500,
                  color: widget.needsYou ? colors.accent : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
