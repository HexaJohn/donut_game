import 'dart:math';

import 'package:flutter/material.dart';

/// A burst of paper confetti from the centre, falling and tumbling for
/// [life]. Purely local: nobody else sees it.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.size, required this.life, required this.seed});

  final double size;
  final Duration life;
  final int seed;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.life)..forward();
  late final List<_Piece> _pieces = () {
    final random = Random(widget.seed);
    return [for (var i = 0; i < 70; i++) _Piece.random(random)];
  }();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _controller.value)),
      ),
    );
  }
}

class _Piece {
  _Piece(this.angle, this.speed, this.spin, this.color, this.width, this.height, this.drift);

  final double angle;
  final double speed;
  final double spin;
  final Color color;
  final double width;
  final double height;
  final double drift;

  static const _colors = [
    Color(0xFFFF5252),
    Color(0xFFFFC857),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
    Color(0xFFFFFFFF),
  ];

  static _Piece random(Random random) => _Piece(
        -pi / 2 + (random.nextDouble() - 0.5) * pi * 0.9,
        0.5 + random.nextDouble() * 0.9,
        (random.nextDouble() - 0.5) * 12,
        _colors[random.nextInt(_colors.length)],
        4 + random.nextDouble() * 5,
        6 + random.nextDouble() * 6,
        (random.nextDouble() - 0.5) * 0.3,
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final half = size.width / 2;
    final fade = t > 0.75 ? 1 - (t - 0.75) / 0.25 : 1.0;
    for (final piece in pieces) {
      // Shot outward, slowed by drag, pulled down by gravity
      final travel = piece.speed * half * (1 - pow(1 - t, 2.2));
      final x = c.dx + cos(piece.angle) * travel + piece.drift * half * t;
      final y = c.dy + sin(piece.angle) * travel + half * 1.2 * t * t;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * t);
      // Flutter: the width wobbles as the piece turns over
      final w = piece.width * (0.3 + 0.7 * (cos(piece.spin * t * 1.7).abs()));
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: piece.height),
        Paint()..color = piece.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
