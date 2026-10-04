import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/board.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/widget/dialogs.dart';
import 'package:flutter/material.dart';

enum _MenuAction { rules, theme, sound, restart, leave }

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

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    final theme = Theme.of(context);
    final local = controller.localPlayer;
    final (status, needsYou) = _status();

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.chrome,
        border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          // You
          SizedBox(
            width: 230,
            child: local == null
                ? Text('Spectating', style: theme.textTheme.bodyMedium)
                : AnimatedRotation(
                    turns: (game.spins.value[local.name] ?? 0).toDouble(),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutBack,
                    child: Row(
                      children: [
                        PlayerAvatar(
                            player: local, size: 40, dealer: game.players.isNotEmpty && game.dealer.value == local),
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
                  ),
          ),
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
          // Chat and menu
          Badge(
            isLabelVisible: unread > 0 && !chatOpen,
            label: Text('$unread'),
            child: IconButton.filledTonal(
              tooltip: chatOpen ? 'Hide chat' : 'Chat',
              isSelected: chatOpen,
              onPressed: onToggleChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: const Icon(Icons.chat_bubble_rounded),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<_MenuAction>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => _onMenu(context, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: _MenuAction.rules,
                  child: ListTile(leading: Icon(Icons.menu_book_rounded), title: Text('How to play'))),
              const PopupMenuItem(
                  value: _MenuAction.theme,
                  child: ListTile(leading: Icon(Icons.palette_outlined), title: Text('Theme'))),
              const PopupMenuItem(
                  value: _MenuAction.sound,
                  child: ListTile(leading: Icon(Icons.volume_up_rounded), title: Text('Sound'))),
              PopupMenuItem(
                  value: _MenuAction.restart,
                  child: ListTile(
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: Text(controller.online ? 'Restart server game' : 'Restart match'))),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: _MenuAction.leave,
                  child: ListTile(leading: Icon(Icons.logout_rounded), title: Text('Leave game'))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, _MenuAction action) async {
    switch (action) {
      case _MenuAction.rules:
        showRulesDialog(context);
      case _MenuAction.theme:
        showThemePicker(context);
      case _MenuAction.sound:
        showSoundSettings(context);
      case _MenuAction.restart:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(controller.online ? 'Restart the server game?' : 'Restart the match?'),
            content: Text(controller.online
                ? 'Everyone on the server goes back to the lobby and scores are wiped.'
                : 'Scores go back to $startingScore and a new match starts.'),
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
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

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
