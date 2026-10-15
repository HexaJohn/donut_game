import 'dart:async';
import 'dart:math';

import 'package:donut_game/audit/ai_audit.dart';
import 'package:donut_game/analytics/usage.dart';
import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/campaign/backdrops.dart';
import 'package:donut_game/data/model/chat_message.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/progression/environments.dart';
import 'package:donut_game/progression/gadgets.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/ui/widget/confetti.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/announcer.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/player_sheet.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:donut_game/ui/widget/rasterized_paint.dart';
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
  int get _chambers => chambersFor(PlayerProfile.instance);
  _Tool? _held;
  Color _markerColor = markerColors.first;
  late int _ammo = _chambers;

  /// Confetti bursts still falling, by where and when they went off.
  final List<(Offset, DateTime)> _bursts = [];
  static const _burstLife = Duration(milliseconds: 1800);

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
    Usage.instance.count('gadget.${tool.name}');
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

  /// Stamps a donut on the felt as a thick ring of ink, so it syncs like any
  /// other stroke.
  void _stamp(Offset at) {
    final centre = _onFelt(at);
    if (centre == null) return;
    SoundEffects.instance.play(Sfx.place);
    const radius = 0.045;
    final aspect = _feltRect.width / _feltRect.height;
    const steps = 40;
    final points = [
      for (var i = 0; i <= steps; i++)
        Offset(
          centre.dx + cos(i * 2 * pi / steps) * radius,
          centre.dy + sin(i * 2 * pi / steps) * radius * aspect,
        ),
    ];
    controller.draw(
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}',
      color: _markerColor,
      width: radius * 0.9,
      erase: false,
      points: points,
    );
  }

  void _confetti(Offset at) {
    if (!_feltRect.contains(at)) return;
    SoundEffects.instance.play(Sfx.slide);
    setState(() => _bursts.add((at, DateTime.now())));
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

    // Sizing. A tall screen (a phone held upright) sizes cards by width so
    // the hand fills it, stacks the seats in rows of three, and moves the
    // piles into the felt's top corners so the trick gets the full width.
    final portrait = size.height > size.width * 1.15;
    // A short, wide screen (a phone on its side) seats opponents in columns
    // either side of the felt, so the felt gets the full height
    final sideSeats = !portrait && size.height < 340 && size.width >= 560;
    final cw = portrait
        ? (size.width / 6.2).clamp(44.0, 104.0)
        : sideSeats
            ? (size.height / 5.2).clamp(44.0, 104.0)
            : (min(size.width / 11, (size.height - 200) / 5.1)).clamp(44.0, 104.0);
    final ch = cw * 1.4;
    const seatTop = 12.0;
    final seatGap = portrait ? 8.0 : 12.0;
    final perRow = portrait ? min(n, 3) : n;
    final seatRows = (n / perRow).ceil();
    final seatW = sideSeats ? 128.0 : min(210.0, (size.width - 32 - (perRow - 1) * seatGap) / perRow);
    // Narrow placards put the name under the avatar instead of beside it
    final compactSeats = seatW < 150;
    final seatH = compactSeats ? 72.0 : 70.0;
    final miniW = min(cw * 0.5, seatW / 4);
    final miniH = miniW * 1.4;
    // Each row of seats has its players' face-down hands under it
    final seatStride = seatH + 6 + miniH + 8;

    final handW = cw * 1.12;
    final handH = handW * 1.4;
    final feltTop = sideSeats ? 8.0 : seatTop + seatRows * seatStride + 6;
    final feltBottom = size.height - handH - (sideSeats ? 18 : 30);
    final feltInset = sideSeats ? seatW + 20 : 16.0;
    final felt = Rect.fromLTRB(feltInset, feltTop, size.width - feltInset, max(feltBottom, feltTop + ch * 2));
    final pileW = cw * (portrait ? 0.75 : 0.9);
    final pileH = pileW * 1.4;
    final deckPos =
        portrait ? Offset(felt.left + 14, felt.top + 14) : Offset(felt.left + 28, felt.center.dy - pileH / 2);
    final discardPos = portrait
        ? Offset(felt.right - 14 - pileW, felt.top + 14)
        : Offset(felt.right - 28 - pileW, felt.center.dy - pileH / 2);
    final tableW = cw * 0.95;
    final tableH = tableW * 1.4;
    final playLeft = portrait ? felt.left + 12 : deckPos.dx + pileW + 24;
    final playRight = portrait ? felt.right - 12 : discardPos.dx - 24;

    // Side columns: the first half on the left, the rest on the right, with
    // room between seats for the hands tucked under them
    final leftCount = (n + 1) ~/ 2;
    Rect sideSeatRect(int i) {
      final right = i >= leftCount;
      final index = right ? i - leftCount : i;
      final count = right ? n - leftCount : leftCount;
      final gap = miniH * 0.45 + 6;
      final total = count * seatH + (count - 1) * gap;
      final top = max(8.0, (size.height - total) / 2 - miniH * 0.2);
      return Rect.fromLTWH(right ? size.width - 12 - seatW : 12, top + index * (seatH + gap), seatW, seatH);
    }

    Rect seatRect(int i) {
      if (sideSeats) return sideSeatRect(i);
      final row = i ~/ perRow;
      final inRow = row == seatRows - 1 ? n - row * perRow : perRow;
      final rowWidth = inRow * seatW + (inRow - 1) * seatGap;
      final left = (size.width - rowWidth) / 2;
      return Rect.fromLTWH(left + (i % perRow) * (seatW + seatGap), seatTop + row * seatStride, seatW, seatH);
    }

    final children = <Widget>[
      if (controller.backdrop != null)
        Positioned.fill(key: const ValueKey('backdrop'), child: Backdrop(id: controller.backdrop!)),
    ];
    final cards = <Widget>[];
    final overlays = <Widget>[];
    final used = <String>{};

    final now = DateTime.now();

    // Every player's cards come in their own deck; undealt cards are the
    // dealer's
    final dealer = game.players.isEmpty ? null : game.dealer.value;

    void addCard(GameCard card, Rect rect,
        {required String zone,
        double angle = 0,
        bool faceUp = false,
        bool trump = false,
        Widget Function(Widget)? wrap}) {
      final key = card.key;
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
      final deckOf = zone == 'deck' ? dealer : card.belongsTo ?? dealer;
      final back = deckOf?.cardBack ?? 'pattern.classic';
      final face = deckOf?.cardFace ?? 'face.classic';
      Widget child = _FlipCard(
        faceUp: faceUp,
        // Turn face up as the card lands rather than mid-air
        delay: throwing && faceUp ? _throw * 0.55 : Duration.zero,
        front: RepaintBoundary(child: PlayingCardWidget(card: card, trump: trump, back: back, face: face)),
        back: RepaintBoundary(child: PlayingCardWidget(card: card, faceUp: false, back: back, face: face)),
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

    // Felt, in whatever environment the game or the player picked
    final profile = PlayerProfile.instance;
    final environment = TableEnvironment.byId(controller.environment ?? profile.environment);
    final feltColor = environment.feltColor(colors);
    final feltEdge = environment.edgeColor(colors);
    final texture = environment.texture;
    children.add(Positioned.fromRect(
        key: const ValueKey('felt'),
        rect: felt,
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: feltEdge, width: 6),
              boxShadow: [
                if (colors.glow) BoxShadow(color: feltEdge.withValues(alpha: 0.5), blurRadius: 18),
                const BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color.lerp(feltColor, Colors.white, 0.06)!, feltColor],
                        radius: 1.2,
                      ),
                    ),
                  ),
                  // Painted to an image once, not shape by shape every frame
                  if (texture != null)
                    RasterizedPaint(
                        key: ValueKey(environment.id),
                        painter: texture(feltColor),
                        cacheKey: (environment.id, feltColor)),
                ],
              ),
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
              child: BulletHoleMark(seed: hole.seed, size: holeSize, surface: feltColor),
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
      // Left of the discard pile, so its label stays readable; upright, the
      // pile is up top, so the tray takes the felt's bottom corner
      right: portrait ? size.width - felt.right + 12 : size.width - discardPos.dx + 20,
      bottom: size.height - felt.bottom + (portrait ? 12 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Markers in columns of seven, so unlocked packs don't climb the felt
          for (final column in _columnsOf(markerColorsFor(profile), 7)) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final color in column)
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
            SizedBox(width: cw * 0.08),
          ],
          // The eraser comes with the Marker Set
          if (profile.owns('gadget.markers')) ...[
            SizedBox(width: cw * 0.17),
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
          ],
          if (profile.owns('gadget.flashbang')) ...[
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
          ],
          if (profile.owns('gadget.stamp')) ...[
            SizedBox(width: cw * 0.25),
            Opacity(
              opacity: _held == _Tool.stamp ? 0 : 1,
              child: trayItem(
                'Donut stamp',
                _Tool.stamp,
                _GadgetIcon(icon: Icons.approval_rounded, size: cw * 0.5, color: _markerColor),
              ),
            ),
          ],
          if (profile.owns('gadget.confetti')) ...[
            SizedBox(width: cw * 0.25),
            Opacity(
              opacity: _held == _Tool.confetti ? 0 : 1,
              child: trayItem(
                'Confetti cannon',
                _Tool.confetti,
                _GadgetIcon(icon: Icons.celebration_rounded, size: cw * 0.5, color: const Color(0xFFFFC857)),
              ),
            ),
          ],
          if (profile.owns('gadget.revolver')) ...[
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
        ],
      ),
    ));

    // Pile labels and trump chip
    final onFelt = ThemeData.estimateBrightnessForColor(feltColor) == Brightness.dark ? Colors.white : Colors.black;
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
    final trumpChip = AnimatedOpacity(
      opacity: showTrump ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: _TrumpChip(suit: game.trumpSuit.value),
    );
    children.add(portrait
        // Between the two piles
        ? Positioned(
            key: const ValueKey('trump'),
            left: deckPos.dx + pileW,
            right: size.width - discardPos.dx,
            top: felt.top + 16,
            child: Center(child: trumpChip),
          )
        : Positioned(key: const ValueKey('trump'), left: felt.left + 20, top: felt.top + 16, child: trumpChip));

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
        child: RepaintBoundary(
            child: FittedBox(
                child: SizedBox(
                    width: 100, height: 140, child: CardBack(pattern: dealer?.cardBack ?? 'pattern.classic')))),
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
        // Beside the felt they peek out from under the placard instead
        addCard(hand[j], Rect.fromLTWH(x, sideSeats ? seat.bottom - miniH * 0.55 : seat.bottom + 6, miniW, miniH),
            zone: 'hand:${opponents[i].name}', angle: (j - (slots - 1) / 2) * 0.06);
      }
    }

    // Discard: the newest few, face down, scattered a little
    final discard = game.discard.cards.value;
    final shown = discard.length > 3 ? discard.sublist(discard.length - 3) : discard;
    for (final card in shown) {
      final h = card.key.hashCode;
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
      final spread = size.width * (portrait ? 0.92 : 0.62);
      final spacing = slots <= 1 ? 0.0 : min(handW * 0.92, (spread - handW) / (slots - 1));
      final total = spacing * max(slots - 1, 0) + handW;
      final left = (size.width - total) / 2;
      final base = size.height - handH - 14;
      for (var i = 0; i < count; i++) {
        final card = hand[i];
        final key = card.key;
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
                ? () {
                    // Say why, rather than silently ignore the tap
                    final reason = _whyNotNow(controller);
                    if (reason == null) return;
                    ScaffoldMessenger.maybeOf(context)
                      ?..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(reason), duration: const Duration(seconds: 3)));
                  }
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
    // Upright, the trick sits in the space under the piles, leaving room for
    // the name tags below it
    final rowTop = portrait
        ? (() {
            final top = deckPos.dy + pileH + 10;
            final room = felt.bottom - top - 34;
            return top + max(0.0, (room - tableH) / 2);
          })()
        : felt.center.dy - tableH / 2 + 4;
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
        angle: ((card.key.hashCode % 9) - 4) * 0.012,
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
      // Over the cards when the hands tuck under the placards
      (sideSeats ? overlays : children).add(Positioned.fromRect(
        key: ValueKey('seat-${player.name}'),
        rect: seatRect(i),
        child: AnimatedRotation(
          turns: (game.spins.value[player.name] ?? 0).toDouble(),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutBack,
          child: RepaintBoundary(
            // Tapping another person (online, hands free) offers mute, block
            // and report
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _held == null && controller.canModerate(player)
                  ? () => showPlayerOptions(context, controller, player)
                  : null,
              child: SeatPanel(
                player: player,
                game: game,
                active: _isActive(player),
                dealer: game.players.isNotEmpty && game.dealer.value == player,
                compact: compactSeats,
              ),
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
      // Twice the seat's width, centred under it but kept on screen; beside
      // the felt, out over the felt next to the seat
      final bubbleW = sideSeats ? min(260.0, felt.width * 0.6) : min(seat.width * 2 + 40, size.width - 16);
      final onLeft = seat.center.dx < size.width / 2;
      overlays.add(Positioned(
        // Keyed by message so a new message pops in fresh
        key: ValueKey('bubble-${said.author}-${said.time.microsecondsSinceEpoch}'),
        left: sideSeats
            ? (onLeft ? seat.right + 6 : seat.left - bubbleW - 6)
            : (seat.center.dx - bubbleW / 2).clamp(8.0, size.width - bubbleW - 8),
        width: bubbleW,
        top: sideSeats ? seat.top : seat.bottom + 2,
        child: IgnorePointer(child: _ChatBubble(message: said, pointUp: true)),
      ));
    }
    if (local != null) {
      final said = latestFrom(local.name);
      if (said != null) {
        overlays.add(Positioned(
          key: ValueKey('bubble-${said.author}-${said.time.microsecondsSinceEpoch}'),
          left: 16,
          width: min(560.0, size.width - 32),
          bottom: 4,
          child: IgnorePointer(child: _ChatBubble(message: said, pointUp: false)),
        ));
      }
    }

    _bursts.removeWhere((burst) => now.difference(burst.$2) > _burstLife);
    for (final (at, fired) in _bursts) {
      overlays.add(Positioned(
        key: ValueKey('confetti-${fired.microsecondsSinceEpoch}'),
        left: at.dx - 150,
        top: at.dy - 150,
        child: IgnorePointer(child: ConfettiBurst(size: 300, life: _burstLife, seed: fired.microsecondsSinceEpoch)),
      ));
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
                _Tool.stamp => 'Click the table to stamp a donut',
                _Tool.confetti => 'Click the table to fire',
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
                _Tool.stamp => (details) => _stamp(details.localPosition),
                _Tool.confetti => (details) => _confetti(details.localPosition),
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
                        _Tool.stamp => _HeldGadget(
                            aim: aim,
                            child: _GadgetIcon(icon: Icons.approval_rounded, size: cw * 0.6, color: _markerColor),
                          ),
                        _Tool.confetti => _HeldGadget(
                            aim: aim,
                            child: _GadgetIcon(
                                icon: Icons.celebration_rounded, size: cw * 0.6, color: const Color(0xFFFFC857)),
                          ),
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

/// Splits [items] into columns of at most [size].
List<List<T>> _columnsOf<T>(List<T> items, int size) => [
      for (var i = 0; i < items.length; i += size) items.sublist(i, min(i + size, items.length)),
    ];

/// A tray gadget drawn as an icon on a round pad.
class _GadgetIcon extends StatelessWidget {
  const _GadgetIcon({required this.icon, required this.size, required this.color});

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Icon(icon, size: size * 0.6, color: color),
    );
  }
}

/// A gadget in hand, following the cursor.
class _HeldGadget extends StatelessWidget {
  const _HeldGadget({required this.aim, required this.child});

  final Offset aim;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(left: aim.dx + 10, top: aim.dy + 10, child: IgnorePointer(child: child)),
    ]);
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
bool _swapRound(GameState state) =>
    state == GameState.waitingToSwap || state == GameState.swapping || state == GameState.waitingForPlayerToSwap;

/// Why tapping your hand does nothing right now, if there's a reason worth
/// saying.
String? _whyNotNow(GameController controller) {
  final local = controller.localPlayer;
  final game = controller.game;
  if (local == null || local.skip || game.players.isEmpty) return null;
  final active = game.activePlayerLazy;
  if (_swapRound(game.state.value)) {
    final turns = game.swapTurnsUntil(local);
    if (turns < 0) return 'You\'ve swapped this hand. Waiting for ${active.name}.';
    return 'Not your turn to swap yet. ${active.name} is choosing'
        '${turns == 1 ? ', and you\'re next.' : ', then ${turns - 1} more before you.'}';
  }
  final state = game.state.value;
  if ((state == GameState.playing || state == GameState.waitingForPlayer) && !controller.canPlayNow && active != local) {
    return 'Wait for your turn. ${active.name} is playing.';
  }
  return null;
}

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
        // with blurred shadows or opacity, which would cost an offscreen pass.
        // Corners follow the card's, which scale with its size.
        child: LayoutBuilder(builder: (context, box) {
          final radius = cardRadiusFor(box.maxWidth);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
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
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
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
          );
        }),
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
      // Corners follow the card's, which scale with its size
      child: LayoutBuilder(builder: (context, box) {
        final radius = BorderRadius.circular(cardRadiusFor(box.maxWidth));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: winning ? colors.accent : (lead ? Colors.white.withValues(alpha: 0.6) : Colors.transparent),
              width: winning ? 3 : 1.5,
            ),
          ),
          // Sharp spread instead of a blur: reads as a halo, costs nothing.
          // The spread grows the corners with it.
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(color: winning ? colors.accent.withValues(alpha: 0.35) : Colors.transparent, spreadRadius: 5),
            ],
          ),
          child: child,
        );
      }),
    );
  }
}

class SeatPanel extends StatelessWidget {
  const SeatPanel(
      {super.key,
      required this.player,
      required this.game,
      required this.active,
      required this.dealer,
      this.compact = false});

  final GamePlayer player;
  final Game game;
  final bool active;
  final bool dealer;

  /// Avatar and score on top, name and status underneath, for narrow seats.
  final bool compact;

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
    } else if (_swapRound(game.state.value) && game.handNumber > 0) {
      // Everyone can see who's done, who's next and who's waiting
      final turns = game.swapTurnsUntil(player);
      status = turns < 0 ? 'Swapped' : (turns == 1 ? 'Up next' : 'Waiting to swap');
    } else if (game.state.value == GameState.waitingToDeal && player.voteToDeal && player.human) {
      status = 'Ready';
    }

    // What they're doing, or their tricks this hand
    final details = status != null
        ? Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
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
        : TrickPips(tricks: player.tricks, donuts: player.donuts.value);

    return AnimatedScale(
      scale: player.winner.value ? 1.06 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: sittingOut ? 0.45 : 1,
        duration: const Duration(milliseconds: 300),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 8),
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
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        PlayerAvatar(player: player, dealer: dealer, size: 24),
                        const Spacer(),
                        ScoreText(score: player.score.value, size: 18),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                    SizedBox(height: 12, child: FittedBox(alignment: Alignment.centerLeft, child: details)),
                  ],
                )
              : Row(
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
                          details,
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
          // Our own follows the profile live; others' come from the table
          if (player.human && (player.id == 'local' || player.name == Settings.instance.nickname))
            EmblemWidget(emblem: PlayerProfile.instance.emblem, size: size)
          else if (player.human && player.emblem != null)
            EmblemWidget(emblem: player.emblem!, size: size)
          else
            CircleAvatar(
              radius: size / 2,
              backgroundColor: background,
              child: player.human || player.character
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

class _TailPainter extends CustomPainter with AiArt {
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

enum _Tool { revolver, marker, eraser, flashbang, stamp, confetti }

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
