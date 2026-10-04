import 'dart:math';

import 'package:flutter/material.dart';

/// The Donut mark: a frosted donut with sprinkles.
class DonutLogo extends StatelessWidget {
  const DonutLogo({super.key, this.size = 96, this.frosting = const Color(0xFFF06292), this.shadow = true});

  final double size;
  final Color frosting;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _DonutPainter(frosting, shadow)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.frosting, this.shadow);

  final Color frosting;
  final bool shadow;

  static const _sprinkleColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFD54F),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.92;
    final hole = r * 0.3;

    Path ring(double outer, double inner, [Offset offset = Offset.zero]) => Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: c + offset, radius: outer)),
          Path()..addOval(Rect.fromCircle(center: c + offset, radius: inner)),
        );

    if (shadow) {
      canvas.drawPath(
        ring(r, hole, Offset(0, r * 0.1)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.06),
      );
    }

    // Dough
    canvas.drawPath(
      ring(r, hole),
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFE8B57A), Color(0xFFC98A4B), Color(0xFFA9692F)],
          stops: const [0.35, 0.75, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Frosting with a wavy outer edge
    final outer = Path();
    const waves = 9;
    for (var i = 0; i <= 180; i++) {
      final a = i / 180 * 2 * pi;
      final rr = r * 0.84 + r * 0.05 * sin(a * waves);
      final p = c + Offset(cos(a), sin(a)) * rr;
      i == 0 ? outer.moveTo(p.dx, p.dy) : outer.lineTo(p.dx, p.dy);
    }
    outer.close();
    final frostingPath = Path.combine(
      PathOperation.difference,
      outer,
      Path()..addOval(Rect.fromCircle(center: c, radius: hole * 1.25)),
    );
    canvas.drawPath(frostingPath, Paint()..color = frosting);

    // Shine
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.62),
      pi * 1.1,
      pi * 0.45,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.07,
    );

    // Sprinkles at fixed spots so the logo never changes
    final random = Random(7);
    for (var i = 0; i < 22; i++) {
      final a = random.nextDouble() * 2 * pi;
      final d = hole * 1.45 + random.nextDouble() * (r * 0.72 - hole * 1.45);
      final p = c + Offset(cos(a), sin(a)) * d;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(random.nextDouble() * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 0.13, height: r * 0.04),
          Radius.circular(r * 0.02),
        ),
        Paint()..color = _sprinkleColors[i % _sprinkleColors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => oldDelegate.frosting != frosting || oldDelegate.shadow != shadow;
}
