import 'dart:math';

import 'package:donut_game/audit/ai_audit.dart';
import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/slot_machine.dart';
import 'package:donut_game/ui/career/currency.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:flutter/material.dart';

/// Three reels and a lever. The result is decided before the pull; the reels
/// only put on a show landing on it.
class SlotMachineWidget extends StatefulWidget {
  const SlotMachineWidget({super.key, required this.result, required this.onDone, this.autoPull = false});

  final SlotResult result;

  /// Called once the reels have stopped and the payout is showing.
  final VoidCallback onDone;

  /// Pulls the lever straight away rather than waiting for a tap.
  final bool autoPull;

  @override
  State<SlotMachineWidget> createState() => _SlotMachineWidgetState();
}

class _SlotMachineWidgetState extends State<SlotMachineWidget> with TickerProviderStateMixin {
  static const _reelOrder = SlotSymbol.values;
  static const _spinTime = Duration(milliseconds: 1700);
  static const _stagger = Duration(milliseconds: 450);

  late final List<AnimationController> _reels = [
    for (var i = 0; i < 3; i++) AnimationController(vsync: this, duration: _spinTime + _stagger * i),
  ];
  late final AnimationController _lever = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _payout = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  /// How many full turns each reel makes before it lands.
  late final List<int> _turns = [for (var i = 0; i < 3; i++) 3 + i];

  bool _pulled = false;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();
    _reels.last.addStatusListener((status) {
      if (status == AnimationStatus.completed) _land();
    });
    if (widget.autoPull) WidgetsBinding.instance.addPostFrameCallback((_) => _pull());
  }

  @override
  void dispose() {
    for (final reel in _reels) {
      reel.dispose();
    }
    _lever.dispose();
    _payout.dispose();
    super.dispose();
  }

  void _pull() {
    if (_pulled) return;
    setState(() => _pulled = true);
    SoundEffects.instance.play(Sfx.revolverLoaded);
    _lever.forward().then((_) => _lever.reverse());
    for (var i = 0; i < 3; i++) {
      _reels[i].forward(from: 0);
      _reels[i].addStatusListener((status) {
        if (status == AnimationStatus.completed) SoundEffects.instance.play(Sfx.place, volume: 0.8);
      });
    }
  }

  void _land() {
    if (!mounted) return;
    setState(() => _stopped = true);
    final result = widget.result;
    if (result.jackpot) {
      SoundEffects.instance.play(Sfx.yourMove);
    } else if (result.triple) {
      SoundEffects.instance.play(Sfx.yourTurn);
    } else {
      SoundEffects.instance.play(Sfx.click);
    }
    _payout.forward().then((_) => widget.onDone());
  }

  /// Where reel [i] shows at animation value [t]: a fractional index into
  /// [_reelOrder], decelerating onto the target.
  double _position(int i, double t) {
    final target = _reelOrder.indexOf(widget.result.reels[i]).toDouble();
    final eased = Curves.easeOutCubic.transform(t);
    final total = _turns[i] * _reelOrder.length + target;
    return eased * total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;
    const gold = Color(0xFFE6B422);
    final body = theme.brightness == Brightness.dark ? const Color(0xFF2A1F33) : const Color(0xFF8B2E4A);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: body,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: gold, width: 3),
                boxShadow: [
                  BoxShadow(color: body.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 10)),
                  if (_stopped && result.triple) BoxShadow(color: gold.withValues(alpha: 0.6), blurRadius: 40),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('BONUS SPIN',
                      style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _Reel(
                          controller: _reels[i],
                          position: (t) => _position(i, t),
                          highlight: _stopped && result.triple,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Payline marker
                  Container(width: 200, height: 3, decoration: BoxDecoration(color: gold.withValues(alpha: 0.5))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _Lever(controller: _lever, enabled: !_pulled, onPull: _pull),
          ],
        ),
        const SizedBox(height: 18),
        // Room for the payout, growing if its chips wrap, so the hint and the
        // result take the same space without clipping either
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: !_pulled
                ? Text('Pull the lever',
                    key: const ValueKey('hint'),
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))
                : !_stopped
                    ? const SizedBox(key: ValueKey('spinning'))
                    : ScaleTransition(
                        key: const ValueKey('payout'),
                        scale: CurvedAnimation(parent: _payout, curve: Curves.easeOutBack),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(result.label,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: result.jackpot ? gold : null,
                                  letterSpacing: result.jackpot ? 2 : 0,
                                )),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (result.crumbs > 0)
                                  AmountChip(amount: result.crumbs, currency: Currency.crumbs, prefix: '+'),
                                if (result.glaze > 0) AmountChip(amount: result.glaze, currency: Currency.glaze, prefix: '+'),
                                if (result.xp > 0) AmountChip.xp(amount: result.xp, prefix: '+'),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}

class _Reel extends StatelessWidget {
  const _Reel({required this.controller, required this.position, required this.highlight});

  final AnimationController controller;
  final double Function(double t) position;
  final bool highlight;

  static const double _cell = 64;

  @override
  Widget build(BuildContext context) {
    const symbols = SlotSymbol.values;
    return Container(
      width: 64,
      height: _cell * 1.6,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: highlight ? const Color(0xFFE6B422) : Colors.black26, width: highlight ? 2.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final pos = position(controller.value);
          final index = pos.floor();
          final frac = pos - index;
          // Draw the symbol at pos centred, with neighbours above and below
          return Stack(
            children: [
              for (var k = -1; k <= 1; k++)
                Positioned(
                  top: (_cell * 1.6 - _cell) / 2 + (k - frac) * _cell,
                  left: 0,
                  right: 0,
                  height: _cell,
                  child: Center(child: SlotSymbolView(symbol: symbols[(index + k) % symbols.length], size: 40)),
                ),
              // Shading top and bottom so the reel looks curved
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        stops: const [0, 0.3, 0.7, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One symbol as drawn on the reels and in the payout table.
class SlotSymbolView extends StatelessWidget {
  const SlotSymbolView({super.key, required this.symbol, required this.size});

  final SlotSymbol symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (symbol) {
      case SlotSymbol.donut:
        return DonutLogo(size: size, frosting: const Color(0xFFE0457B), shadow: false);
      case SlotSymbol.glaze:
        return Icon(Icons.water_drop_rounded, size: size, color: glazeColor);
      case SlotSymbol.seven:
        return Text('7',
            style: TextStyle(
                fontSize: size * 1.05, fontWeight: FontWeight.w900, color: const Color(0xFFD7263D), height: 1));
      case SlotSymbol.bar:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: size * 0.14, vertical: size * 0.08),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B22),
            borderRadius: BorderRadius.circular(size * 0.12),
            border: Border.all(color: const Color(0xFFE6B422), width: 2),
          ),
          child: Text('BAR',
              style: TextStyle(
                  color: const Color(0xFFE6B422), fontWeight: FontWeight.w900, fontSize: size * 0.34, height: 1)),
        );
      case SlotSymbol.sprinkle:
        return CustomPaint(size: Size.square(size), painter: _SprinklePainter());
      case SlotSymbol.cherry:
        return CustomPaint(size: Size.square(size), painter: _CherryPainter());
      case SlotSymbol.crumb:
        return Icon(Icons.grain_rounded, size: size * 0.9, color: crumbsColor);
    }
  }
}

class _CherryPainter extends CustomPainter with AiArt {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final stem = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, w * 0.7)
        ..quadraticBezierTo(w * 0.4, w * 0.3, w * 0.6, w * 0.12)
        ..moveTo(w * 0.7, w * 0.65)
        ..quadraticBezierTo(w * 0.72, w * 0.35, w * 0.6, w * 0.12),
      stem,
    );
    final red = Paint()..color = const Color(0xFFD7263D);
    canvas.drawCircle(Offset(w * 0.32, w * 0.74), w * 0.2, red);
    canvas.drawCircle(Offset(w * 0.7, w * 0.68), w * 0.2, red);
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(w * 0.26, w * 0.68), w * 0.05, shine);
    canvas.drawCircle(Offset(w * 0.64, w * 0.62), w * 0.05, shine);
  }

  @override
  bool shouldRepaint(_CherryPainter oldDelegate) => false;
}

class _SprinklePainter extends CustomPainter with AiArt {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final random = Random(2);
    const colors = [Color(0xFFFFD54F), Color(0xFF4FC3F7), Color(0xFF81C784), Color(0xFFBA68C8), Color(0xFFFF8A65)];
    for (var i = 0; i < 7; i++) {
      final c = Offset(w * 0.2 + random.nextDouble() * w * 0.6, w * 0.2 + random.nextDouble() * w * 0.6);
      final a = random.nextDouble() * pi;
      canvas.drawLine(
        c - Offset(cos(a), sin(a)) * w * 0.16,
        c + Offset(cos(a), sin(a)) * w * 0.16,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = w * 0.11
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SprinklePainter oldDelegate) => false;
}

class _Lever extends StatelessWidget {
  const _Lever({required this.controller, required this.enabled, required this.onPull});

  final AnimationController controller;
  final bool enabled;
  final VoidCallback onPull;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: enabled ? 'Pull' : '',
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: enabled ? onPull : null,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              // The handle swings from up to down and back
              final t = Curves.easeInOut.transform(controller.value);
              return SizedBox(
                width: 44,
                height: 150,
                child: CustomPaint(painter: _LeverPainter(t, enabled)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LeverPainter extends CustomPainter with AiArt {
  _LeverPainter(this.t, this.enabled);

  final double t;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width * 0.3, size.height * 0.55);
    // Mount
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: pivot, width: 18, height: 40), const Radius.circular(5)),
      Paint()..color = const Color(0xFF555555),
    );
    // Arm swings from pointing up (t=0) to pointing down (t=1)
    final angle = -pi / 2 + t * pi;
    final tip = pivot + Offset(cos(angle), sin(angle)) * size.height * 0.4;
    canvas.drawLine(
      pivot,
      tip,
      Paint()
        ..color = const Color(0xFFBDBDBD)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(tip, 12, Paint()..color = enabled ? const Color(0xFFD7263D) : const Color(0xFF8A4A52));
    canvas.drawCircle(tip + const Offset(-3, -3), 4, Paint()..color = Colors.white.withValues(alpha: 0.45));
    canvas.drawCircle(pivot, 5, Paint()..color = const Color(0xFF333333));
  }

  @override
  bool shouldRepaint(_LeverPainter oldDelegate) => oldDelegate.t != t || oldDelegate.enabled != enabled;
}
