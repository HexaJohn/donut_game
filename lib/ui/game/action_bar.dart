import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/ui/widget/table_options.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/board.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/widget/dialogs.dart';
import 'package:flutter/material.dart';

enum _MenuAction { rules, theme, sound, tableSettings, addBot, removeBot, restart, leave }

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
  Widget build(BuildContext context) =>
      ValueListenableBuilder(valueListenable: controller.autoReadyIn, builder: (context, _, __) => _bar(context));

  Widget _bar(BuildContext context) {
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
    if (local == null) return Text(tableSpectating(), style: theme.textTheme.bodyMedium);
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
          tooltip: chatOpen ? tableHideChat() : tableChat(),
          isSelected: chatOpen,
          onPressed: onToggleChat,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: const Icon(Icons.chat_bubble_rounded),
        ),
      );

  Widget _menu(BuildContext context) => PopupMenuButton<_MenuAction>(
        tooltip: tableMenu(),
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (action) => _onMenu(context, action),
        itemBuilder: (context) => [
          PopupMenuItem(
              value: _MenuAction.rules,
              child: ListTile(leading: const Icon(Icons.menu_book_rounded), title: Text(tableHowToPlay()))),
          PopupMenuItem(
              value: _MenuAction.theme,
              child: ListTile(leading: const Icon(Icons.palette_outlined), title: Text(tableTheme()))),
          PopupMenuItem(
              value: _MenuAction.sound,
              child: ListTile(leading: const Icon(Icons.tune_rounded), title: Text(tableSettings()))),
          if (controller.canManageBots) ...[
            PopupMenuItem(
                value: _MenuAction.tableSettings,
                child: ListTile(leading: const Icon(Icons.tune_rounded), title: Text(tableTableSettings()))),
            PopupMenuItem(
                value: _MenuAction.addBot,
                child: ListTile(leading: const Icon(Icons.smart_toy_rounded), title: Text(tableAddBot()))),
            if (game.players.any((player) => !player.human))
              PopupMenuItem(
                  value: _MenuAction.removeBot,
                  child: ListTile(leading: const Icon(Icons.person_remove_rounded), title: Text(tableRemoveBot()))),
          ],
          if (controller.canRestart)
            PopupMenuItem(
                value: _MenuAction.restart,
                child: ListTile(
                    leading: const Icon(Icons.restart_alt_rounded),
                    title: Text(controller.online && controller.partyCode == null
                        ? tableRestartServerGame()
                        : tableRestartMatch()))),
          const PopupMenuDivider(),
          PopupMenuItem(
              value: _MenuAction.leave,
              child: ListTile(leading: const Icon(Icons.logout_rounded), title: Text(tableLeaveGame()))),
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
      case _MenuAction.tableSettings:
        showTableSettings(context, controller);
      case _MenuAction.addBot:
        controller.addBot();
      case _MenuAction.removeBot:
        controller.removeBot();
      case _MenuAction.restart:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(controller.online ? tableRestartServerTitle() : tableRestartMatchTitle()),
            content: Text(controller.online
                ? tableRestartServerBody()
                : tableRestartMatchBody.of('target', controller.game.targetScore)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tableCancel())),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tableRestart())),
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
        return (tableWaitingToJoin(), false);
      case GameState.waitingToDeal:
        if (!controller.online) return (tableReadyWhenYouAre(), true);
        final humans = game.players.where((element) => element.human).toList();
        final ready = humans.where((element) => element.voteToDeal).length;
        final countdown = controller.autoReadyIn.value;
        if (countdown != null) {
          return (tableNextHandIn({'seconds': countdown, 'ready': ready, 'total': humans.length}), true);
        }
        if (local?.voteToDeal == false && game.handNumber > 0) {
          return (tableTapReady({'ready': ready, 'total': humans.length}), true);
        }
        return (tableWaitingForReady({'ready': ready, 'total': humans.length}), !(local?.voteToDeal ?? true));
      case GameState.dealing:
        return (tableDealing(), false);
      case GameState.waitingToSwap:
      case GameState.swapping:
      case GameState.waitingForPlayerToSwap:
        if (local?.skip == true && state != GameState.waitingForPlayerToSwap) return (tableYouFolded(), false);
        if (myTurn && state == GameState.waitingForPlayerToSwap && local.notReady) {
          final marked = local.hand.cards.value.where((element) => element.state == CardState.swap).length;
          return (tableYourSwapMove({'max': maxSwaps, 'picked': marked}), true);
        }
        if (local == null || local.skip || game.players.isEmpty) {
          return (tableChoosingSwaps.of('name', activeName), false);
        }
        final turns = game.swapTurnsUntil(local);
        final line = turns < 0
            ? tableChoosingSwapsYouSwapped
            : (turns == 1 ? tableChoosingSwapsYouNext : tableChoosingSwapsMoreBefore);
        return (line({'name': activeName, 'n': turns - 1}), false);
      case GameState.playing:
      case GameState.waitingForPlayer:
        if (local?.skip == true) return (tableYouFolded(), false);
        if (controller.canPlayNow) {
          return (game.leadingCard == null ? tableYourLead() : tableYourTurnFollow(), true);
        }
        if (myTurn) return (tableNextTrickComingUp(), false);
        return (tableWaitingFor.of('name', activeName), false);
      case GameState.waitingForNextRound:
        return (tableNextTrick(), false);
      case GameState.gameOver:
        final champion = game.champion.value;
        return (champion == null ? tableMatchOver() : tableWonTheMatch.of('name', champion.name), false);
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
          FilledButton.icon(onPressed: controller.deal, icon: const Icon(Icons.style_rounded), label: Text(tableDeal()))
        ];
      }
      return [
        // While the next hand counts down, a way to hold it
        if (!local.voteToDeal && controller.autoReadyIn.value != null)
          TextButton(onPressed: controller.holdNextHand, child: Text(tableWait())),
        local.voteToDeal
            ? OutlinedButton.icon(
                onPressed: controller.deal, icon: const Icon(Icons.check_rounded), label: Text(tableReady()))
            : FilledButton.icon(
                onPressed: controller.deal, icon: const Icon(Icons.style_rounded), label: Text(tableImReady())),
      ];
    }

    if (state == GameState.waitingForPlayerToSwap && controller.isLocalTurn && local.notReady && !local.skip) {
      final marked = local.hand.cards.value.where((element) => element.state == CardState.swap).length;
      final foldBlocked = !controller.canFold;
      return [
        Tooltip(
          message: foldBlocked
              ? (game.suddenDeath.isNotEmpty
                  ? tableNoFoldingSuddenDeath()
                  : tableFoldedLastHands.of('n', maxConsecutiveFolds))
              : tableFoldHint(),
          child: OutlinedButton.icon(
            onPressed: foldBlocked ? null : controller.fold,
            icon: const Icon(Icons.close_rounded),
            label: Text(tableFold()),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: controller.confirmSwap,
          icon: Icon(marked == 0 ? Icons.check_rounded : Icons.swap_horiz_rounded),
          label: Text(marked == 0 ? tableKeepHand() : tableSwapCount.of('n', marked)),
        ),
      ];
    }

    if (state == GameState.gameOver && !controller.online) {
      return [
        FilledButton.icon(
            onPressed: controller.newMatch, icon: const Icon(Icons.replay_rounded), label: Text(tableNewMatch()))
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
