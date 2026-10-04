import 'dart:async';
import 'dart:math';

import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/data/model/chat_message.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/announcer.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:donut_game/ui/widget/revolver.dart';
import 'package:donut_game/ui/widget/suit_icon.dart';
import 'package:donut_game/ui/widget/table_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A card thrown from one place to another (deck to hand, hand to table...):
/// fast launch, soft landing.
const Duration _throw = Duration(milliseconds: 420);
const Curve _throwCurve = Curves.easeOutCubic;

/// A card nudged within the same place (hand re-centring, trick row sliding).
const Duration _shuffle = Duration(milliseconds: 320);
const Curve _shuffleCurve = Curves.easeInOutCubic;

/// How long a chat message stays up as a bubble by its sender.
const Duration chatBubbleLife = Duration(seconds: 5);

/// Display order of suits in your hand: alternating colours.
const _suitOrder = [Suit.spades, Suit.hearts, Suit.clubs, Suit.diamonds];

/// The table. Every card on screen is a child of one [Stack], keyed by the
/// card itself, so when a card moves between deck, hand, table and discard
/// its [AnimatedPositioned] flies it across the screen.
class GameBoard extends StatefulWidget {
  const GameBoard({super.key, required this.controller, required this.announcer, required this.fuse});

  final GameController controller;
  final Announcer announcer;

  /// Where a thrown flashbang is sitting before it goes off (0..1 across the
  /// felt), or null.
  final ValueListenable<Offset?> fuse;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  String? _hovered;

  /// Where each card was last drawn and when it last changed place, so a card
  /// moving between places gets the throw curve for the whole of its flight.
  final Map<String, (String, DateTime)> _zones = {};

  // Table tools: the revolver, markers and eraser. Each player has their own;
  // what they do to the table and the placards is shared through the game.
  static const int _chambers = 6;
  _Tool? _held;
  Color _markerColor = markerColors.first;
  int _ammo = _chambers;

  /// Stroke being drawn with a marker or the eraser, and its last point.
  String? _strokeId;
  Offset? _lastInk;
  bool _flash = false;
  int _recoil = 0;
  final ValueNotifier<Offset?> _aim = ValueNotifier(null);
  final FocusNode _gunFocus = FocusNode(debugLabel: 'table tool');

  /// Where things were drawn last build, to work out what a shot hit.
  Rect _feltRect = Rect.zero;
  final Map<String, Rect> _seatRects = {};

  @override
  void dispose() {
    _aim.dispose();
    _gunFocus.dispose();
    super.dispose();
  }

  void _pickUp(_Tool tool, Offset at, {Color? color}) {
    SoundEffects.instance.play(tool == _Tool.revolver ? Sfx.revolverLoaded : Sfx.click);
    setState(() {
      _held = tool;
      if (color != null) _markerColor = color;
      if (tool == _Tool.revolver) _ammo = _chambers;
    });
    _aim.value = at;
    _gunFocus.requestFocus();
  }

  /// Puts the tool back in the tray. Putting the revolver down reloads it.
  void _putDown() {
    setState(() => _held = null);
    _aim.value = null;
    _strokeId = null;
  }

  /// [at] as a fraction of the felt, or null if it's off the table.
  Offset? _onFelt(Offset at, {bool allowOutside = false}) {
    if (!allowOutside && !_feltRect.contains(at)) return null;
    return Offset((at.dx - _feltRect.left) / _feltRect.width, (at.dy - _feltRect.top) / _feltRect.height);
  }

  void _throwFlashbang(Offset at) {
    final point = _onFelt(at);
    if (point == null) return;
    controller.throwFlashbang(point.dx, point.dy);
    _putDown();
  }

  void _inkDown(Offset at) {
    _aim.value = at;
    final point = _onFelt(at);
    if (point == null) return;
    _strokeId = '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
    _lastInk = at;
    _drawTo([point]);
  }

  void _inkMove(Offset at) {
    _aim.value = at;
    if (_strokeId == null || _lastInk == null) return;
    // Skip tiny moves; they add points without changing the line
    if ((at - _lastInk!).distance < 2) return;
    _lastInk = at;
    _drawTo([_onFelt(at, allowOutside: true)!]);
  }

  void _drawTo(List<Offset> points) {
    final erasing = _held == _Tool.eraser;
    controller.draw(
      _strokeId!,
      color: _markerColor,
      width: erasing ? eraserWidth : markerWidth,
      erase: erasing,
      points: points,
    );
  }

  void _fire(Offset at) {
    _aim.value = at;
    if (_ammo == 0) {
      // Dry fire
      SoundEffects.instance.play(Sfx.click);
      return;
    }
    SoundEffects.instance.play(Sfx.gunshot);
    setState(() {
      _ammo--;
      _flash = true;
      _recoil++;
    });
    Future.delayed(const Duration(milliseconds: 70), () {
      if (mounted) setState(() => _flash = false);
    });
    for (final seat in _seatRects.entries) {
      if (seat.value.contains(at)) {
        controller.shootSeat(seat.key);
        return;
      }
    }
    if (_feltRect.contains(at)) {
      controller.shootTable(
        (at.dx - _feltRect.left) / _feltRect.width,
        (at.dy - _feltRect.top) / _feltRect.height,
      );
    }
  }

  GameController get controller => widget.controller;
  Game get game => controller.game;

  /// Sounds for cards that changed place in this build, played once the
  /// frame is out so they line up with the flight starting.
  final List<(Sfx, double)> _sounds = [];

  void _queueMoveSound(String from, String to, GamePlayer? local) {
    if (to == 'deck') return;
    if (to == 'table') {
      _sounds.add((Sfx.place, 1));
    } else if (to == 'discard') {
      _sounds.add((Sfx.slide, 0.6));
    } else if (from == 'deck') {
      // Your own cards a little louder than everyone else's
      _sounds.add((Sfx.slide, to == 'hand:${local?.name}' ? 1 : 0.5));
    }
    if (_sounds.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final (sfx, volume) in _sounds) {
          SoundEffects.instance.play(sfx, volume: volume);
        }
        _sounds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) => _build(context, constraints.biggest));
  }

  Widget _build(BuildContext context, Size size) {
    final colors = DonutColors.of(context);
    final local = controller.localPlayer;
    final players = game.players;
    final opponents = _opponentsInOrder(players, local);
    final n = max(opponents.length, 1);

    // Sizing
    final cw = (min(size.width / 11, (size.height - 200) / 5.1)).clamp(44.0, 104.0);
    final ch = cw * 1.4;
    const seatH = 70.0;
    const seatTop = 12.0;
    const seatGap = 12.0;
    final seatW = min(210.0, (size.width - 32 - (n - 1) * seatGap) / n);
    final seatsWidth = n * seatW + (n - 1) * seatGap;
    final seatsLeft = (size.width - seatsWidth) / 2;
    final miniW = min(cw * 0.5, seatW / 4);
    final miniH = miniW * 1.4;
    final miniTop = seatTop + seatH + 6;

    final handW = cw * 1.12;
    final handH = handW * 1.4;
    final feltTop = miniTop + miniH + 14;
    final feltBottom = size.height - handH - 30;
    final felt = Rect.fromLTRB(16, feltTop, size.width - 16, max(feltBottom, feltTop + ch * 2));
    final pileW = cw * 0.9;
    final pileH = pileW * 1.4;
    final deckPos = Offset(felt.left + 28, felt.center.dy - pileH / 2);
    final discardPos = Offset(felt.right - 28 - pileW, felt.center.dy - pileH / 2);
    final tableW = cw * 0.95;
    final tableH = tableW * 1.4;
    final playLeft = deckPos.dx + pileW + 24;
    final playRight = discardPos.dx - 24;

    Rect seatRect(int i) => Rect.fromLTWH(seatsLeft + i * (seatW + seatGap), seatTop, seatW, seatH);

    final children = <Widget>[];
    final cards = <Widget>[];
    final overlays = <Widget>[];
    final used = <String>{};

    final now = DateTime.now();

    void addCard(GameCard card, Rect rect,
        {required String zone,
        double angle = 0,
        bool faceUp = false,
        bool trump = false,
        Widget Function(Widget)? wrap}) {
      final key = card.toString();
      if (!used.add(key)) return;
      final previous = _zones[key];
      // A card seen for the first time just appears where it belongs
      final movedAt = previous == null ? DateTime(0) : (previous.$1 == zone ? previous.$2 : now);
      if (previous != null && previous.$1 != zone) _queueMoveSound(previous.$1, zone, local);
      _zones[key] = (zone, movedAt);
      // Small margin so the curve never switches while the flight is still running
      final throwing = now.difference(movedAt) < _throw + const Duration(milliseconds: 150);
      final duration = throwing ? _throw : _shuffle;
      final curve = throwing ? _throwCurve : _shuffleCurve;
      Widget child = _FlipCard(
        faceUp: faceUp,
        // Turn face up as the card lands rather than mid-air
        delay: throwing && faceUp ? _throw * 0.55 : Duration.zero,
        front: RepaintBoundary(child: PlayingCardWidget(card: card, trump: trump)),
        back: RepaintBoundary(child: PlayingCardWidget(card: card, faceUp: false)),
      );
      if (wrap != null) child = wrap(child);
      // Every card is laid out at hand size and scaled with a transform, so a
      // flying card never relayouts or repaints, it is only recomposited
      cards.add(AnimatedPositioned(
        key: ValueKey(key),
        duration: duration,
        curve: curve,
        left: rect.center.dx - handW / 2,
        top: rect.center.dy - handH / 2,
        width: handW,
        height: handH,
        child: AnimatedScale(
          scale: rect.width / handW,
          duration: duration,
          curve: curve,
          child: AnimatedRotation(
            turns: angle / (2 * pi),
            duration: duration,
            curve: curve,
            child: RepaintBoundary(child: child),
          ),
        ),
      ));
    }

    // Felt
    children.add(Positioned.fromRect(
        key: const ValueKey('felt'),
        rect: felt,
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Color.lerp(colors.felt, Colors.white, 0.06)!, colors.felt],
                radius: 1.2,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.feltEdge, width: 6),
              boxShadow: [
                if (colors.glow) BoxShadow(color: colors.feltEdge.withValues(alpha: 0.5), blurRadius: 18),
                const BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
          ),
        )));

    // Ink on the felt, then bullet holes punched through it
    _feltRect = felt;
    children.add(Positioned.fromRect(
      key: const ValueKey('ink'),
      rect: felt.deflate(6),
      child: IgnorePointer(child: InkLayer(ink: game.ink, radius: 22)),
    ));
    final holeSize = (cw * 0.42).clamp(18.0, 40.0);
    for (final hole in game.holes.value) {
      children.add(Positioned(
        key: ValueKey('hole-${hole.seed}'),
        left: felt.left + hole.x * felt.width - holeSize / 2,
        top: felt.top + hole.y * felt.height - holeSize / 2,
        child: IgnorePointer(
          child: RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.scale(scale: t, child: child),
              child: BulletHoleMark(seed: hole.seed, size: holeSize, surface: colors.felt),
            ),
          ),
        ),
      ));
    }

    // Tool tray in the corner of the table: whatever isn't in your hand
    final gunScale = cw * 1.4 / revolverSize.width;
    final toolScale = cw * 0.95 / markerSize.width;
    Widget trayItem(String tip, _Tool tool, Widget child, {Color? color}) => Tooltip(
          message: tip,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox?;
                _pickUp(tool, box?.globalToLocal(details.globalPosition) ?? details.localPosition, color: color);
              },
              child: child,
            ),
          ),
        );
    children.add(Positioned(
      key: const ValueKey('tool-tray'),
      // Left of the discard pile, so its label stays readable
      right: size.width - discardPos.dx + 20,
      bottom: size.height - felt.bottom + 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final color in markerColors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Opacity(
                    // The marker you're holding leaves an empty slot
                    opacity: _held == _Tool.marker && _markerColor == color ? 0 : 1,
                    child: trayItem(
                      'Marker',
                      _Tool.marker,
                      SizedBox.fromSize(
                        size: markerSize * toolScale,
                        child: FittedBox(child: MarkerPen(color: color)),
                      ),
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: cw * 0.25),
          Opacity(
            opacity: _held == _Tool.eraser ? 0 : 1,
            child: trayItem(
              'Eraser',
              _Tool.eraser,
              SizedBox.fromSize(
                size: eraserSize * toolScale,
                child: Transform.rotate(angle: 0.12, child: const FittedBox(child: EraserBlock())),
              ),
            ),
          ),
          SizedBox(width: cw * 0.25),
          Opacity(
            opacity: _held == _Tool.flashbang ? 0 : (controller.flashReady ? 1 : 0.35),
            child: IgnorePointer(
              ignoring: !controller.flashReady,
              child: trayItem(
                controller.flashReady ? 'Flashbang' : 'Flashbang (cooling down)',
                _Tool.flashbang,
                SizedBox.fromSize(
                  size: flashbangSize * toolScale * 0.9,
                  child: Transform.rotate(angle: 0.3, child: const FittedBox(child: FlashbangGrenade())),
                ),
              ),
            ),
          ),
          SizedBox(width: cw * 0.25),
          Opacity(
            opacity: _held == _Tool.revolver ? 0 : 1,
            child: trayItem(
              'Revolver',
              _Tool.revolver,
              SizedBox.fromSize(
                size: revolverSize * gunScale,
                child: Transform.rotate(angle: -0.25, child: const FittedBox(child: Revolver())),
              ),
            ),
          ),
        ],
      ),
    ));

    // Pile labels and trump chip
    final onFelt = ThemeData.estimateBrightnessForColor(colors.felt) == Brightness.dark ? Colors.white : Colors.black;
    children.add(Positioned(
      key: const ValueKey('deck-label'),
      left: deckPos.dx - 8,
      width: pileW + 16,
      top: deckPos.dy + pileH + 10,
      child: _PileLabel('Deck · ${game.deck.contents.length}', onFelt),
    ));
    children.add(Positioned(
      key: const ValueKey('discard-label'),
      left: discardPos.dx - 8,
      width: pileW + 16,
      top: discardPos.dy + pileH + 10,
      child: _PileLabel('Discard · ${game.discard.cards.value.length}', onFelt),
    ));
    final showTrump = game.state.value != GameState.waitingToDeal &&
        game.state.value != GameState.waitingForPlayers &&
        game.state.value != GameState.dealing &&
        game.state.value != GameState.gameOver;
    children.add(Positioned(
      key: const ValueKey('trump'),
      left: felt.left + 20,
      top: felt.top + 16,
      child: AnimatedOpacity(
        opacity: showTrump ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: _TrumpChip(suit: game.trumpSuit.value),
      ),
    ));

    // Deck: only the top card is a real card. The thickness below it is
    // static, so dealing never nudges the cards underneath before they fly.
    final deck = game.deck.contents;
    for (var i = min(2, deck.length - 1); i >= 1; i--) {
      children.add(Positioned(
        key: ValueKey('deck-under-$i'),
        left: deckPos.dx + i * 1.5,
        top: deckPos.dy + i * 1.5,
        width: pileW,
        height: pileH,
        child: const RepaintBoundary(child: FittedBox(child: SizedBox(width: 100, height: 140, child: CardBack()))),
      ));
    }
    if (deck.isNotEmpty) addCard(deck.first, Rect.fromLTWH(deckPos.dx, deckPos.dy, pileW, pileH), zone: 'deck');

    // While cards are being dealt into a hand, lay it out as a full hand of
    // fixed slots in deal order, so cards already there or on their way are
    // never redirected. It re-centres and sorts once, when the dealing stops.
    final state = game.state.value;
    bool fillingSlots(GamePlayer player) =>
        state == GameState.dealing ||
        (state == GameState.swapping && game.players.isNotEmpty && game.activePlayerLazy == player);

    // Opponent hands, face down under each seat
    for (var i = 0; i < opponents.length; i++) {
      final seat = seatRect(i);
      final hand = opponents[i].hand.cards.value;
      final slots = fillingSlots(opponents[i]) ? max(hand.length, cardsPerHand) : hand.length;
      final spacing = miniW * 0.42;
      final total = spacing * (slots - 1) + miniW;
      for (var j = 0; j < hand.length; j++) {
        final x = seat.center.dx - total / 2 + j * spacing;
        addCard(hand[j], Rect.fromLTWH(x, miniTop, miniW, miniH),
            zone: 'hand:${opponents[i].name}', angle: (j - (slots - 1) / 2) * 0.06);
      }
    }

    // Discard: the newest few, face down, scattered a little
    final discard = game.discard.cards.value;
    final shown = discard.length > 3 ? discard.sublist(discard.length - 3) : discard;
    for (final card in shown) {
      final h = card.toString().hashCode;
      addCard(card, Rect.fromLTWH(discardPos.dx + (h % 7 - 3), discardPos.dy + (h % 5 - 2), pileW, pileH),
          zone: 'discard', angle: ((h % 13) - 6) * 0.025);
    }

    // Your hand
    final interactive = _Interaction.of(controller);
    if (local != null) {
      final filling = fillingSlots(local);
      final hand = filling ? local.hand.cards.value : _sortedHand(local.hand.cards.value);
      final count = hand.length;
      final slots = filling ? max(count, cardsPerHand) : count;
      final spacing = slots <= 1 ? 0.0 : min(handW * 0.92, (size.width * 0.62 - handW) / (slots - 1));
      final total = spacing * max(slots - 1, 0) + handW;
      final left = (size.width - total) / 2;
      final base = size.height - handH - 14;
      for (var i = 0; i < count; i++) {
        final card = hand[i];
        final key = card.toString();
        final mid = (slots - 1) / 2;
        final marked = card.state == CardState.swap;
        final legal = interactive.play && controller.isLegal(card);
        final clickable = interactive.swap || legal;
        final lift = (marked ? 26.0 : 0) + (clickable && _hovered == key ? 14.0 : 0);
        final y = base + pow(i - mid, 2) * 2.5 - lift;
        addCard(
          card,
          Rect.fromLTWH(left + i * spacing, y, handW, handH),
          zone: 'hand:${local.name}',
          angle: (i - mid) * 0.035,
          faceUp: true,
          trump: card.suit == game.trumpSuit.value && showTrump,
          wrap: (child) => _HandCard(
            marked: marked,
            dimmed: interactive.play && !legal,
            glow: legal,
            onHover: (hovering) => setState(() => _hovered = hovering ? key : (_hovered == key ? null : _hovered)),
            onTap: !clickable
                ? null
                : () {
                    if (interactive.swap) {
                      SoundEffects.instance.play(Sfx.click);
                      controller.toggleSwap(card);
                    } else {
                      controller.play(card);
                    }
                    setState(() {});
                  },
            child: child,
          ),
        );
      }
    }

    // Table: the trick as one row in play order, re-centring as cards land
    final table = game.table.cards.value;
    final activeCount = players.where((element) => !element.skip).length;
    final trickDone = table.isNotEmpty && table.length >= activeCount && game.lastTrickWinner != null;
    final slot = min(tableW * 1.18, (playRight - playLeft) / max(table.length, 1));
    final rowLeft = felt.center.dx - (slot * (table.length - 1) + tableW) / 2;
    final rowTop = felt.center.dy - tableH / 2 + 4;
    for (var i = 0; i < table.length; i++) {
      final card = table[i];
      final owner = card.belongsTo;
      final x = rowLeft + i * slot;
      final winning = trickDone && owner?.name == game.lastTrickWinner?.name;
      final lead = i == 0;
      addCard(
        card,
        Rect.fromLTWH(x, rowTop, tableW, tableH),
        zone: 'table',
        angle: ((card.toString().hashCode % 9) - 4) * 0.012,
        faceUp: true,
        trump: card.suit == game.trumpSuit.value,
        wrap: (child) => _TableCardFrame(winning: winning, lead: lead && !trickDone, child: child),
      );
      overlays.add(AnimatedPositioned(
        key: ValueKey('tag-$card'),
        duration: _shuffle,
        curve: _shuffleCurve,
        left: x - 10,
        width: tableW + 20,
        top: rowTop + tableH + 8,
        child: _PlayedBy(
          name: owner == null ? '' : (owner.name == local?.name ? 'You' : owner.name),
          lead: lead,
          winning: winning,
          color: onFelt,
        ),
      ));
    }

    // Seats. Each shot at a placard spins it round once more.
    _seatRects.clear();
    for (var i = 0; i < opponents.length; i++) {
      final player = opponents[i];
      _seatRects[player.name] = seatRect(i);
      children.add(Positioned.fromRect(
        key: ValueKey('seat-${player.name}'),
        rect: seatRect(i),
        child: AnimatedRotation(
          turns: (game.spins.value[player.name] ?? 0).toDouble(),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutBack,
          child: RepaintBoundary(
            child: SeatPanel(
              player: player,
              game: game,
              active: _isActive(player),
              dealer: game.players.isNotEmpty && game.dealer.value == player,
            ),
          ),
        ),
      ));
    }

    // Glow under your hand when it's your move
    final yourMove = interactive.swap || interactive.play;
    children.add(
      Positioned(
        key: const ValueKey('your-move'),
        left: 0,
        right: 0,
        bottom: 0,
        height: handH + 40,
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: yourMove ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [colors.accent.withValues(alpha: 0.24), colors.accent.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Chat bubbles: under each opponent's seat, and above your own placard
    ChatMessage? latestFrom(String name) => game.chat.value.lastWhereOrNullBy(
        (element) => !element.system && element.author == name && now.difference(element.time) < chatBubbleLife);
    for (var i = 0; i < opponents.length; i++) {
      final said = latestFrom(opponents[i].name);
      if (said == null) continue;
      final seat = seatRect(i);
      overlays.add(Positioned(
        // Keyed by message so a new message pops in fresh
        key: ValueKey('bubble-${said.author}-${said.time.microsecondsSinceEpoch}'),
        // Twice the seat's width, centred under it
        left: seat.center.dx - (seat.width * 2 + 40) / 2,
        width: seat.width * 2 + 40,
        top: seat.bottom + 2,
        child: IgnorePointer(child: _ChatBubble(message: said, pointUp: true)),
      ));
    }
    if (local != null) {
      final said = latestFrom(local.name);
      if (said != null) {
        overlays.add(Positioned(
          key: ValueKey('bubble-${said.author}-${said.time.microsecondsSinceEpoch}'),
          left: 16,
          width: 560,
          bottom: 4,
          child: IgnorePointer(child: _ChatBubble(message: said, pointUp: false)),
        ));
      }
    }

    overlays.add(Positioned(
      key: const ValueKey('announcer'),
      left: felt.left,
      right: size.width - felt.right,
      top: felt.top + 14,
      child: IgnorePointer(child: AnnouncementBanner(announcer: widget.announcer)),
    ));

    overlays.add(Positioned.fill(
      key: const ValueKey('flashbang-fuse'),
      child: IgnorePointer(
        child: ValueListenableBuilder(
          valueListenable: widget.fuse,
          builder: (context, Offset? at, _) {
            if (at == null) return const SizedBox.shrink();
            final grenade = flashbangSize * toolScale;
            final spot = Offset(felt.left + at.dx * felt.width, felt.top + at.dy * felt.height);
            return Stack(children: [
              Positioned(
                left: spot.dx - grenade.width / 2,
                top: spot.dy - grenade.height / 2,
                child: _FizzingGrenade(key: ValueKey(at), size: grenade),
              ),
            ]);
          },
        ),
      ),
    ));

    final held = _held;
    final drawing = held == _Tool.marker || held == _Tool.eraser;
    if (held != null) {
      overlays.add(Positioned(
        key: const ValueKey('tool-hint'),
        left: felt.left,
        right: size.width - felt.right,
        bottom: size.height - felt.bottom + 14,
        child: IgnorePointer(
          child: Center(
            child: _ToolHint(
              ammo: held == _Tool.revolver ? _ammo : null,
              chambers: _chambers,
              action: switch (held) {
                _Tool.revolver => 'Click to shoot',
                _Tool.marker => 'Drag to draw on the table',
                _Tool.eraser => 'Drag to rub out ink',
                _Tool.flashbang => 'Click the table to throw it',
              },
            ),
          ),
        ),
      ));
      overlays.add(Positioned.fill(
        key: const ValueKey('tool-held'),
        child: Focus(
          focusNode: _gunFocus,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              _putDown();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.precise,
            onHover: (event) => _aim.value = event.localPosition,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: switch (held) {
                _Tool.revolver => (details) => _fire(details.localPosition),
                _Tool.flashbang => (details) => _throwFlashbang(details.localPosition),
                _ => null,
              },
              onPanDown: drawing ? (details) => _inkDown(details.localPosition) : null,
              onPanUpdate: drawing ? (details) => _inkMove(details.localPosition) : null,
              onPanEnd: drawing ? (_) => _strokeId = null : null,
              onPanCancel: drawing ? () => _strokeId = null : null,
              onSecondaryTapDown: (_) => _putDown(),
              child: ValueListenableBuilder(
                valueListenable: _aim,
                builder: (context, Offset? aim, _) => aim == null
                    ? const SizedBox.expand()
                    : switch (held) {
                        _Tool.revolver => _HeldRevolver(aim: aim, scale: gunScale, flash: _flash, recoil: _recoil),
                        _Tool.marker => _HeldMarker(aim: aim, scale: toolScale, color: _markerColor),
                        _Tool.eraser => _HeldEraser(aim: aim, diameter: eraserWidth * felt.width),
                        _Tool.flashbang => Stack(children: [
                            Positioned(
                              left: aim.dx - flashbangSize.width * toolScale * 0.45,
                              top: aim.dy - flashbangSize.height * toolScale * 0.45,
                              child: IgnorePointer(
                                child: SizedBox.fromSize(
                                  size: flashbangSize * toolScale * 0.9,
                                  child: const FittedBox(child: FlashbangGrenade()),
                                ),
                              ),
                            ),
                          ]),
                      },
              ),
            ),
          ),
        ),
      ));
    }

    return Stack(clipBehavior: Clip.none, children: [...children, ...cards, ...overlays]);
  }

  bool _isActive(GamePlayer player) {
    if (game.players.isEmpty) return false;
    final state = game.state.value;
    final turnBased = state == GameState.playing ||
        state == GameState.waitingForPlayer ||
        state == GameState.waitingForPlayerToSwap ||
        state == GameState.swapping;
    return turnBased && game.activePlayerLazy == player && !player.skip;
  }

  List<GamePlayer> _opponentsInOrder(List<GamePlayer> players, GamePlayer? local) {
    final index = local == null ? -1 : players.indexOf(local);
    if (index < 0) return players;
    return [
      for (var i = 1; i < players.length; i++) players[(index + i) % players.length],
    ];
  }

  List<GameCard> _sortedHand(List<GameCard> hand) {
    final trump = game.trumpSuit.value;
    int suitRank(Suit suit) => suit == trump ? 99 : _suitOrder.indexOf(suit);
    return [...hand]..sort((a, b) {
        final bySuit = suitRank(a.suit).compareTo(suitRank(b.suit));
        return bySuit != 0 ? bySuit : a.value.index.compareTo(b.value.index);
      });
  }
}

extension _LastWhere<T> on List<T> {
  T? lastWhereOrNullBy(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}

/// What the local player can do with their hand right now.
class _Interaction {
  const _Interaction({required this.swap, required this.play});

  final bool swap;
  final bool play;

  static _Interaction of(GameController controller) {
    final local = controller.localPlayer;
    if (local == null || local.skip || !controller.isLocalTurn) return const _Interaction(swap: false, play: false);
    final state = controller.game.state.value;
    return _Interaction(
      swap: state == GameState.waitingForPlayerToSwap && local.notReady,
      play: controller.canPlayNow,
    );
  }
}

/// Flips between [front] and [back] around the vertical axis, optionally
/// waiting [delay] first (so a card thrown to you turns over as it lands).
class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.faceUp, required this.front, required this.back, this.delay = Duration.zero});

  final bool faceUp;
  final Widget front;
  final Widget back;
  final Duration delay;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.faceUp ? 1 : 0,
  );
  Timer? _pending;

  @override
  void didUpdateWidget(_FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.faceUp == oldWidget.faceUp) return;
    _pending?.cancel();
    void flip() => widget.faceUp ? _controller.forward() : _controller.reverse();
    if (widget.delay == Duration.zero) {
      flip();
    } else {
      _pending = Timer(widget.delay, () {
        if (mounted) flip();
      });
    }
  }

  @override
  void dispose() {
    _pending?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final showFront = t >= 0.5;
        final angle = showFront ? (1 - t) * pi : -t * pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: showFront ? widget.front : widget.back,
        );
      },
    );
  }
}

class _HandCard extends StatelessWidget {
  const _HandCard({
    required this.child,
    required this.marked,
    required this.dimmed,
    required this.glow,
    required this.onHover,
    this.onTap,
  });

  final Widget child;
  final bool marked;
  final bool dimmed;
  final bool glow;
  final ValueChanged<bool> onHover;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        // Highlight and dimming are painted on top of the card rather than
        // with blurred shadows or opacity, which would cost an offscreen pass
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: dimmed ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.55) : Colors.transparent,
            border: Border.all(color: glow || marked ? colors.accent : Colors.transparent, width: 2.5),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (marked)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                      ),
                      child: const Text('SWAP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableCardFrame extends StatelessWidget {
  const _TableCardFrame({required this.child, required this.winning, required this.lead});

  final Widget child;
  final bool winning;
  final bool lead;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    return AnimatedScale(
      scale: winning ? 1.1 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: winning ? colors.accent : (lead ? Colors.white.withValues(alpha: 0.6) : Colors.transparent),
            width: winning ? 3 : 1.5,
          ),
        ),
        // Sharp spread instead of a blur: reads as a halo, costs nothing
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: winning ? colors.accent.withValues(alpha: 0.35) : Colors.transparent, spreadRadius: 5),
          ],
        ),
        child: child,
      ),
    );
  }
}

class SeatPanel extends StatelessWidget {
  const SeatPanel({super.key, required this.player, required this.game, required this.active, required this.dealer});

  final GamePlayer player;
  final Game game;
  final bool active;
  final bool dealer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    final onSeat = theme.colorScheme.onSurface;
    final sittingOut = game.suddenDeath.isNotEmpty && !game.suddenDeath.contains(player);

    String? status;
    if (game.champion.value == player) {
      status = 'Champion!';
    } else if (sittingOut) {
      status = 'Sitting out';
    } else if (player.skip && game.state.value != GameState.waitingToDeal && game.state.value != GameState.gameOver) {
      status = 'Folded';
    } else if (active) {
      status = game.state.value == GameState.waitingForPlayerToSwap || game.state.value == GameState.swapping
          ? 'Choosing swaps'
          : 'Thinking';
    } else if (game.state.value == GameState.waitingToDeal && player.voteToDeal && player.human) {
      status = 'Ready';
    }

    return AnimatedScale(
      scale: player.winner.value ? 1.06 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: sittingOut ? 0.45 : 1,
        duration: const Duration(milliseconds: 300),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.seat,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? colors.accent : onSeat.withValues(alpha: 0.08),
              width: active ? 2.5 : 1,
            ),
            boxShadow: [
              if (active) BoxShadow(color: colors.accent.withValues(alpha: 0.35), blurRadius: 16),
              const BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              PlayerAvatar(player: player, dealer: dealer, size: 36),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    status != null
                        ? Row(
                            children: [
                              if (active) _ThinkingDots(color: colors.accent),
                              Flexible(
                                child: Text(status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: active ? colors.accent : onSeat.withValues(alpha: 0.6))),
                              ),
                            ],
                          )
                        : TrickPips(tricks: player.tricks, donuts: player.donuts.value),
                  ],
                ),
              ),
              ScoreText(score: player.score.value),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.player, this.dealer = false, this.size = 36});

  final GamePlayer player;
  final bool dealer;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = DonutColors.of(context);
    final hue = (player.name.hashCode % 360).toDouble();
    final background = HSLColor.fromAHSL(1, hue, 0.55, 0.55).toColor();
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: background,
            child: player.human
                ? Text(player.name.isEmpty ? '?' : player.name.characters.first.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.42))
                : Icon(Icons.smart_toy_rounded, color: Colors.white, size: size * 0.55),
          ),
          if (dealer)
            Positioned(
              right: -4,
              bottom: -4,
              child: Tooltip(
                message: 'Dealer',
                child: Container(
                  width: size * 0.5,
                  height: size * 0.5,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text('D',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.24)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScoreText extends StatelessWidget {
  const ScoreText({super.key, required this.score, this.size = 22});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Points left',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween(begin: const Offset(0, -0.5), end: Offset.zero).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text(
          '$score',
          key: ValueKey(score),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: score <= 0 ? DonutColors.of(context).accent : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Tricks taken this hand as dots, plus donuts collected this match.
class TrickPips extends StatelessWidget {
  const TrickPips({super.key, required this.tricks, required this.donuts});

  final int tricks;
  final int donuts;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    final faint = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: '$tricks trick${tricks == 1 ? '' : 's'} this hand',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < cardsPerHand; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: i < tricks ? colors.accent : faint, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
        if (donuts > 0) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: '$donuts donut${donuts == 1 ? '' : 's'} this match',
            child: Text('\u{1F369}$donuts', style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ],
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots({required this.color});

  final Color color;

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: widget.color.withValues(
                    alpha: 0.3 + 0.7 * (0.5 + 0.5 * sin((_controller.value - i * 0.2) * 2 * pi)).clamp(0, 1)),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 3),
        ],
      ),
    ));
  }
}

class _PlayedBy extends StatelessWidget {
  const _PlayedBy({required this.name, required this.lead, required this.winning, required this.color});

  final String name;
  final bool lead;
  final bool winning;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: winning ? colors.accent : color.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: winning ? FontWeight.w800 : FontWeight.w600,
            )),
        if (lead || winning)
          Text(winning ? 'WINS' : 'LEAD',
              style: TextStyle(
                color: winning ? colors.accent : color.withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              )),
      ],
    );
  }
}

class _PileLabel extends StatelessWidget {
  const _PileLabel(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600));
  }
}

class _TrumpChip extends StatelessWidget {
  const _TrumpChip({required this.suit});

  final Suit suit;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.cardFace,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accent, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('TRUMP',
              style: TextStyle(color: colors.accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(width: 8),
          SuitIcon(suit, size: 16, color: isRed(suit) ? colors.cardRed : colors.cardInk),
        ],
      ),
    );
  }
}

/// A speech bubble that pops in, then fades out at the end of
/// [chatBubbleLife]. [pointUp] puts the tail on top (towards a seat above);
/// otherwise it hangs below, pointing at your placard in the action bar.
class _ChatBubble extends StatefulWidget {
  const _ChatBubble({required this.message, required this.pointUp});

  final ChatMessage message;
  final bool pointUp;

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  static const _fade = Duration(milliseconds: 400);
  bool _fading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final age = DateTime.now().difference(widget.message.time);
    final untilFade = chatBubbleLife - _fade - age;
    _timer = Timer(untilFade.isNegative ? Duration.zero : untilFade, () {
      if (mounted) setState(() => _fading = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.colorScheme.inverseSurface;
    final tail = CustomPaint(size: const Size(28, 14), painter: _TailPainter(fill, up: widget.pointUp));
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x30000000), offset: Offset(0, 4))],
      ),
      child: Text(widget.message.text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onInverseSurface, height: 1.3, fontSize: 24)),
    );
    final align = widget.pointUp ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return AnimatedOpacity(
      opacity: _fading ? 0 : 1,
      duration: _fade,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Transform.scale(
          scale: t,
          alignment: widget.pointUp ? Alignment.topCenter : Alignment.bottomLeft,
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: align,
          children: widget.pointUp
              ? [tail, Flexible(child: body)]
              : [
                  Flexible(child: body),
                  Padding(padding: const EdgeInsets.only(left: 40), child: tail),
                ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color, {required this.up});

  final Color color;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = up
        ? (Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height))
        : (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0));
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color || oldDelegate.up != up;
}

/// The revolver in hand: pointing up and left, its muzzle just below and to
/// the right of the crosshair so it never hides what you're aiming at.
class _HeldRevolver extends StatelessWidget {
  const _HeldRevolver({required this.aim, required this.scale, required this.flash, required this.recoil});

  final Offset aim;
  final double scale;
  final bool flash;

  /// Bumped on every shot, to kick the barrel up.
  final int recoil;

  @override
  Widget build(BuildContext context) {
    final width = revolverSize.width * scale;
    final height = revolverSize.height * scale;
    // Flipped to point left, the muzzle sits at this point in the box
    final muzzle = Offset((revolverSize.width - revolverMuzzle.dx) * scale, revolverMuzzle.dy * scale);
    final target = aim + const Offset(14, 10);
    return Stack(
      children: [
        Positioned(
          left: target.dx - muzzle.dx,
          top: target.dy - muzzle.dy,
          width: width,
          height: height,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(recoil),
              tween: Tween(begin: recoil == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (context, kick, child) => Transform.rotate(
                angle: 0.35 + 0.45 * kick,
                alignment: Alignment(muzzle.dx / width * 2 - 1, muzzle.dy / height * 2 - 1),
                child: child,
              ),
              child: Transform.flip(flipX: true, child: FittedBox(child: Revolver(flash: flash))),
            ),
          ),
        ),
      ],
    );
  }
}

enum _Tool { revolver, marker, eraser, flashbang }

/// A marker in hand: tip on the cursor, body leaning up and to the right.
class _HeldMarker extends StatelessWidget {
  const _HeldMarker({required this.aim, required this.scale, required this.color});

  final Offset aim;
  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = markerSize.width * scale;
    final height = markerSize.height * scale;
    final tip = markerTip * scale;
    return Stack(
      children: [
        Positioned(
          left: aim.dx - tip.dx,
          top: aim.dy - tip.dy,
          width: width,
          height: height,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -0.7,
              alignment: Alignment(tip.dx / width * 2 - 1, tip.dy / height * 2 - 1),
              child: FittedBox(child: MarkerPen(color: color)),
            ),
          ),
        ),
      ],
    );
  }
}

/// The eraser in hand: a ring showing exactly what it will rub out, with the
/// block itself just above it.
class _HeldEraser extends StatelessWidget {
  const _HeldEraser({required this.aim, required this.diameter});

  final Offset aim;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: aim.dx - diameter / 2,
          top: aim.dy - diameter / 2,
          width: diameter,
          height: diameter,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
        Positioned(
          left: aim.dx - eraserSize.width / 2,
          top: aim.dy - diameter / 2 - eraserSize.height - 2,
          child: IgnorePointer(child: Transform.rotate(angle: 0.12, child: const EraserBlock())),
        ),
      ],
    );
  }
}

/// What the tool in your hand does, and for the revolver how many shots are
/// left.
class _ToolHint extends StatelessWidget {
  const _ToolHint({required this.ammo, required this.chambers, required this.action});

  final int? ammo;
  final int chambers;
  final String action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ammo != null) ...[
            for (var i = 0; i < chambers; i++)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i < ammo! ? const Color(0xFFFFC107) : Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
          ],
          Text(
            ammo == 0
                ? 'Empty! Right-click or Esc to put it down and reload'
                : '$action · Right-click or Esc to put it down',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// A flashbang that's just landed: drops in, rolls a little and blinks.
class _FizzingGrenade extends StatefulWidget {
  const _FizzingGrenade({super.key, required this.size});

  final Size size;

  @override
  State<_FizzingGrenade> createState() => _FizzingGrenadeState();
}

class _FizzingGrenadeState extends State<_FizzingGrenade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final drop = Curves.bounceOut.transform((t / 0.45).clamp(0.0, 1.0));
        final roll = sin(t * 18) * 0.25 * (1 - t);
        final lit = (t * 12).floor().isEven;
        return Transform.translate(
          offset: Offset(0, -40 * (1 - drop)),
          child: Transform.rotate(
            angle: 1.2 + roll,
            child: SizedBox.fromSize(size: widget.size, child: FittedBox(child: FlashbangGrenade(lit: lit))),
          ),
        );
      },
    );
  }
}
