import 'dart:async';
import 'dart:math';

import 'package:donut_game/ai/acrotron.dart';
import 'package:donut_game/audio/music_player.dart';
import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/modes/bad_batch/bb_cards.dart';
import 'package:donut_game/modes/bad_batch/bb_controller.dart';
import 'package:donut_game/modes/bad_batch/bb_game.dart';
import 'package:donut_game/modes/bad_batch/bb_widgets.dart';
import 'package:donut_game/modes/game_mode.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/chat_panel.dart';
import 'package:donut_game/ui/widget/dialogs.dart';
import 'package:donut_game/ui/widget/fable_mark.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/material.dart';

/// Called when an online server switches the table to another game, to put
/// the matching screen in this one's place.
typedef ModeSwitcher = void Function(BuildContext context, GameMode mode);

class BbScreen extends StatefulWidget {
  const BbScreen({super.key, required this.controller, this.onModeSwitch});

  final BbController controller;
  final ModeSwitcher? onModeSwitch;

  @override
  State<BbScreen> createState() => _BbScreenState();
}

class _BbScreenState extends State<BbScreen> {
  BbController get controller => widget.controller;

  /// Your picks, in blank order, and anything written on blank cards.
  final List<int> _selected = [];
  final Map<int, String> _written = {};
  bool _chatOpen = false;
  int _seenChat = 0;
  bool _sending = false;

  // For spotting changes worth a sound
  BbState? _lastState;
  int _lastRound = 0;
  int _lastChat = 0;

  @override
  void initState() {
    super.initState();
    controller.view.addListener(_onView);
    controller.switchedTo.addListener(_onSwitch);
    controller.chat.addListener(_onChat);
    controller.start();
    SoundEffects.instance.preload();
    MusicPlayer.instance.playGame();
    _lastChat = controller.chat.value.length;
  }

  @override
  void dispose() {
    controller.view.removeListener(_onView);
    controller.switchedTo.removeListener(_onSwitch);
    controller.chat.removeListener(_onChat);
    controller.dispose();
    MusicPlayer.instance.playMenu();
    super.dispose();
  }

  void _onSwitch() {
    final mode = controller.switchedTo.value;
    if (mode != null && mode != GameMode.badBatch && mounted) widget.onModeSwitch?.call(context, mode);
  }

  void _onChat() {
    final messages = controller.chat.value;
    if (messages.length > _lastChat && messages.skip(_lastChat).any((m) => !m.system)) {
      SoundEffects.instance.play(Sfx.cough);
    }
    _lastChat = messages.length;
    if (_chatOpen) _seenChat = messages.length;
    setState(() {});
  }

  void _onView() {
    final view = controller.view.value;
    if (view == null) return;
    // A new round wipes any half-made selection
    if (view.round != _lastRound) {
      _selected.clear();
      _written.clear();
      if (view.state == BbState.submitting) {
        if (_lastRound == 0) SoundEffects.instance.play(Sfx.shuffle);
        if (view.czar != controller.localName) SoundEffects.instance.play(Sfx.yourTurn);
      }
    }
    if (view.state != _lastState) {
      if (view.state == BbState.judging) {
        for (var i = 0; i < min(view.answers.length, 4); i++) {
          Future.delayed(Duration(milliseconds: 120 * i), () => SoundEffects.instance.play(Sfx.slide));
        }
        if (controller.isCzar) SoundEffects.instance.play(Sfx.yourMove);
      }
      if (view.state == BbState.roundOver || view.state == BbState.gameOver) {
        SoundEffects.instance.play(Sfx.place);
      }
    }
    _lastRound = view.round;
    _lastState = view.state;
    setState(() {});
  }

  bool get _canAnswer {
    final view = controller.view.value;
    return view != null &&
        view.state == BbState.submitting &&
        !controller.isCzar &&
        !view.answered.contains(controller.localName) &&
        view.hand.isNotEmpty;
  }

  Future<void> _tapCard(int index, ResponseCard card) async {
    if (!_canAnswer) return;
    final pick = controller.view.value!.prompt!.pick;
    if (_selected.contains(index)) {
      setState(() {
        _selected.remove(index);
        _written.remove(index);
      });
      return;
    }
    if (_selected.length >= pick) {
      // Swap out the last pick rather than refusing
      setState(() {
        _written.remove(_selected.removeLast());
      });
    }
    if (card.blank) {
      final text = await _writeBlank(_written[index]);
      if (text == null || text.trim().isEmpty) return;
      _written[index] = text.trim();
    }
    SoundEffects.instance.play(Sfx.click);
    setState(() => _selected.add(index));
  }

  Future<String?> _writeBlank(String? current) {
    final input = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write your answer'),
        content: TextField(
          controller: input,
          autofocus: true,
          maxLength: BadBatchGame.maxBlankLength,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(hintText: 'Something terrible...'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, input.text), child: const Text('Use it')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _sending = true);
    final problem = await controller.submit(List.of(_selected), Map.of(_written));
    if (!mounted) return;
    setState(() => _sending = false);
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    SoundEffects.instance.play(Sfx.place);
    setState(() {
      _selected.clear();
      _written.clear();
    });
  }

  Future<void> _judge(int index) async {
    final problem = await controller.judge(index);
    if (problem != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
  }

  Future<void> _leave() async {
    final view = controller.view.value;
    final leave = view == null ||
        view.state == BbState.lobby ||
        view.state == BbState.gameOver ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Leave the game?'),
                content: Text(controller.online ? 'You can rejoin with the same nickname.' : 'This game will be lost.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
                ],
              ),
            ) ==
            true;
    if (leave && mounted) Navigator.pop(context);
  }

  int get _unread {
    final messages = controller.chat.value;
    var count = 0;
    for (var i = _seenChat.clamp(0, messages.length); i < messages.length; i++) {
      if (!messages[i].system && messages[i].author != controller.localName) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final view = controller.view.value;
    return Scaffold(
      body: Column(
        children: [
          DonutTitleBar(
            title: controller.label,
            trailing: view == null || view.round == 0 ? null : _Chip(text: 'Round ${view.round}'),
          ),
          ValueListenableBuilder(
            valueListenable: controller.error,
            builder: (context, String? error, _) => error == null
                ? const SizedBox.shrink()
                : Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.errorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                  ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: view == null ? const Center(child: CircularProgressIndicator()) : _table(view)),
                ChatPanel(
                  chat: controller.chat,
                  localName: controller.localName,
                  onSend: controller.sendChat,
                  open: _chatOpen,
                  onClose: () => setState(() => _chatOpen = false),
                ),
              ],
            ),
          ),
          _actionBar(view),
        ],
      ),
    );
  }

  Widget _table(BbView view) {
    final colors = DonutColors.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final handWidth = min(132.0, (constraints.maxWidth - 32 - 9 * 8) / 10);
      final promptWidth = min(220.0, constraints.maxWidth * 0.22);
      return Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              _Seats(view: view, seats: controller.seats.value, localName: controller.localName),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.felt,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colors.feltEdge, width: 6),
                  ),
                  child: _feltContents(view, promptWidth),
                ),
              ),
              SizedBox(height: handWidth / bbCardAspect + 28, child: _hand(view, handWidth)),
            ],
          ),
          if (view.state == BbState.gameOver) Positioned.fill(child: _GameOver(view: view, controller: controller)),
        ],
      );
    });
  }

  Widget _feltContents(BbView view, double promptWidth) {
    final onFelt = ThemeData.estimateBrightnessForColor(DonutColors.of(context).felt) == Brightness.dark
        ? Colors.white
        : Colors.black;
    if (view.state == BbState.lobby || view.prompt == null) {
      final humans = controller.seats.value.where((s) => s.human).toList();
      final ready = humans.where((s) => s.ready).length;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DonutLogo(size: 72),
            const SizedBox(height: 12),
            Text('Bad Batch',
                style:
                    Theme.of(context).textTheme.headlineMedium?.copyWith(color: onFelt, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              controller.error.value ??
                  (controller.online
                      ? 'Waiting for everyone to be ready ($ready/${humans.length})'
                      : 'Shuffling the deck...'),
              style: TextStyle(color: onFelt.withValues(alpha: 0.8)),
            ),
            if (view.decks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Decks: ${view.decks.join(', ')}',
                    style: TextStyle(color: onFelt.withValues(alpha: 0.6), fontSize: 12)),
              ),
          ],
        ),
      );
    }

    final decided = view.state == BbState.roundOver || view.state == BbState.gameOver;
    final winning = view.winningIndex;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BbPromptCard(
          prompt: view.prompt!,
          width: promptWidth,
          answers: decided && winning != null ? view.answers[winning].map((e) => e.text).toList() : null,
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_feltHeadline(view), style: TextStyle(color: onFelt, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(child: SingleChildScrollView(child: _answers(view, promptWidth * 0.62, onFelt))),
            ],
          ),
        ),
      ],
    );
  }

  String _feltHeadline(BbView view) {
    final me = controller.localName;
    final waiting = controller.seats.value.length - 1 - view.answered.length;
    return switch (view.state) {
      BbState.submitting => controller.isCzar
          ? 'You\'re the Card Czar. Waiting for answers ($waiting to go)'
          : view.answered.contains(me)
              ? 'Your answer is in. Waiting for $waiting more'
              : 'Pick ${view.prompt!.pick == 1 ? 'your best answer' : '${view.prompt!.pick} cards, in order'}',
      BbState.judging =>
        controller.isCzar ? 'You\'re the Czar: tap the best answer' : '${view.czar} is picking the winner...',
      BbState.roundOver => view.winner == me ? 'You won the round!' : '${view.winner} wins the round',
      BbState.gameOver => '${view.champion} wins the game!',
      BbState.lobby => '',
    };
  }

  Widget _answers(BbView view, double width, Color onFelt) {
    if (view.state == BbState.submitting) {
      // Face down until everyone's in
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < view.answered.length; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.scale(scale: t, child: child),
              child: BbAnswerCard(card: const ResponseCard(''), width: width, faceDown: true),
            ),
        ],
      );
    }
    final decided = view.state == BbState.roundOver || view.state == BbState.gameOver;
    final canJudge = view.state == BbState.judging && controller.isCzar;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (var i = 0; i < view.answers.length; i++)
          _AnswerGroup(
            cards: view.answers[i],
            width: width,
            highlighted: decided && i == view.winningIndex,
            dimmed: decided && i != view.winningIndex,
            author: decided && view.authors != null ? view.authors![i] : null,
            onFelt: onFelt,
            onTap: canJudge ? () => _judge(i) : null,
          ),
      ],
    );
  }

  Widget _hand(BbView view, double width) {
    final canAnswer = _canAnswer;
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            for (var i = 0; i < view.hand.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: MouseRegion(
                  cursor: canAnswer ? SystemMouseCursors.click : MouseCursor.defer,
                  child: GestureDetector(
                    onTap: canAnswer ? () => _tapCard(i, view.hand[i]) : null,
                    child: AnimatedSlide(
                      offset: Offset(0, _selected.contains(i) ? -0.08 : 0),
                      duration: const Duration(milliseconds: 180),
                      child: BbAnswerCard(
                        card: view.hand[i],
                        width: width,
                        order: _selected.contains(i) ? _selected.indexOf(i) + 1 : null,
                        writtenText: _written[i],
                        dimmed: !canAnswer && view.state == BbState.submitting,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionBar(BbView? view) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    final me = controller.localName;
    final pick = view?.prompt?.pick ?? 1;
    final buttons = <Widget>[];
    if (view != null) {
      if (_canAnswer) {
        buttons.add(FilledButton.icon(
          onPressed: _selected.length == pick && !_sending ? _submit : null,
          icon: const Icon(Icons.send_rounded),
          label: Text(pick == 1 ? 'Play card' : 'Play ${_selected.length}/$pick cards'),
        ));
      }
      if (view.state == BbState.lobby || view.state == BbState.gameOver) {
        if (controller.online) {
          buttons.add(controller.readied
              ? OutlinedButton.icon(
                  onPressed: controller.ready, icon: const Icon(Icons.check_rounded), label: const Text('Ready'))
              : FilledButton.icon(
                  onPressed: controller.ready,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(view.state == BbState.gameOver ? 'Ready for another' : 'I\'m ready')));
        } else {
          buttons.add(FilledButton.icon(
              onPressed: controller.ready,
              icon: const Icon(Icons.replay_rounded),
              label: Text(view.state == BbState.gameOver ? 'Play again' : 'Start')));
        }
      }
    }
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.chrome,
        border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 230,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.accent,
                  child: Text(me.isEmpty ? '?' : me.characters.first.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(me, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      if (view != null)
                        Text('${view.scores[me] ?? 0} of ${view.pointsToWin} points'
                            '${controller.isCzar ? ' · Card Czar' : ''}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final button in buttons)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: button),
              ],
            ),
          ),
          Badge(
            isLabelVisible: _unread > 0 && !_chatOpen,
            label: Text('$_unread'),
            child: IconButton.filledTonal(
              tooltip: _chatOpen ? 'Hide chat' : 'Chat',
              isSelected: _chatOpen,
              onPressed: () => setState(() {
                _chatOpen = !_chatOpen;
                _seenChat = controller.chat.value.length;
              }),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: const Icon(Icons.chat_bubble_rounded),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) => switch (value) {
              'rules' => showBadBatchRules(context),
              'theme' => showThemePicker(context),
              'sound' => showSoundSettings(context),
              _ => _leave(),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: 'rules', child: ListTile(leading: Icon(Icons.menu_book_rounded), title: Text('How to play'))),
              PopupMenuItem(
                  value: 'theme', child: ListTile(leading: Icon(Icons.palette_outlined), title: Text('Theme'))),
              PopupMenuItem(
                  value: 'sound', child: ListTile(leading: Icon(Icons.volume_up_rounded), title: Text('Sound'))),
              PopupMenuDivider(),
              PopupMenuItem(
                  value: 'leave', child: ListTile(leading: Icon(Icons.logout_rounded), title: Text('Leave game'))),
            ],
          ),
        ],
      ),
    );
  }
}

/// One player's answer: one card, or several in blank order.
class _AnswerGroup extends StatefulWidget {
  const _AnswerGroup({
    required this.cards,
    required this.width,
    required this.highlighted,
    required this.dimmed,
    required this.onFelt,
    this.author,
    this.onTap,
  });

  final List<ResponseCard> cards;
  final double width;
  final bool highlighted;
  final bool dimmed;
  final Color onFelt;
  final String? author;
  final VoidCallback? onTap;

  @override
  State<_AnswerGroup> createState() => _AnswerGroupState();
}

class _AnswerGroupState extends State<_AnswerGroup> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: widget.highlighted ? 1.06 : (_hover && widget.onTap != null ? 1.04 : 1),
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final card in widget.cards)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        builder: (context, t, child) => Opacity(opacity: t, child: child),
                        child: BbAnswerCard(
                          card: card,
                          width: widget.width,
                          highlighted: widget.highlighted || (_hover && widget.onTap != null),
                          dimmed: widget.dimmed,
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.author != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.highlighted) Icon(Icons.emoji_events_rounded, size: 16, color: colors.accent),
                      if (widget.highlighted) const SizedBox(width: 4),
                      Text(
                        widget.author!,
                        style: TextStyle(
                          color: widget.highlighted ? colors.accent : widget.onFelt.withValues(alpha: 0.7),
                          fontWeight: widget.highlighted ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seats extends StatelessWidget {
  const _Seats({required this.view, required this.seats, required this.localName});

  final BbView view;
  final List<BbSeat> seats;
  final String localName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final seat in seats)
          Builder(builder: (context) {
            final czar = seat.name == view.czar;
            final answered = view.answered.contains(seat.name);
            final status = czar
                ? 'Card Czar'
                : view.state == BbState.submitting
                    ? (answered ? 'Answered' : 'Thinking...')
                    : (view.state == BbState.lobby && seat.ready ? 'Ready' : null);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.seat,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: czar ? colors.accent : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    width: czar ? 2.5 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!czar && seat.agent && seat.name == fableName)
                    const FableMark(size: 20)
                  else
                    Icon(
                      czar
                          ? Icons.gavel_rounded
                          : seat.name == acrotronName
                              ? Icons.memory_rounded
                              : seat.agent
                                  ? Icons.auto_awesome_rounded
                                  : (seat.human ? Icons.person_rounded : Icons.smart_toy_rounded),
                      size: 18,
                      color: czar ? colors.accent : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(seat.name == localName ? '${seat.name} (you)' : seat.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (status != null)
                        Text(status,
                            style:
                                theme.textTheme.labelSmall?.copyWith(color: czar || answered ? colors.accent : null)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text('${view.scores[seat.name] ?? 0}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _GameOver extends StatelessWidget {
  const _GameOver({required this.view, required this.controller});

  final BbView view;
  final BbController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    final standings = view.scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
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
            DonutLogo(size: 72, frosting: colors.accent),
            const SizedBox(height: 12),
            Text(view.champion == controller.localName ? 'You win!' : '${view.champion} wins!',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            for (final entry in standings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Main menu'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: controller.ready,
                    child: Text(controller.online ? (controller.readied ? 'Ready ✓' : 'Ready again') : 'Play again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: scheme.onSurface.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
