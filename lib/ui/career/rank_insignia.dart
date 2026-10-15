import 'dart:math';

import 'package:donut_game/audit/ai_audit.dart';
import 'package:donut_game/progression/ranks.dart';
import 'package:flutter/material.dart';

/// A rank's badge: a shield that gains chevrons, bars, stars and finally a
/// wreath as the families go by.
class RankInsignia extends StatelessWidget {
  const RankInsignia({super.key, required this.rank, required this.size, this.color, this.dim = false});

  final Rank rank;
  final double size;

  /// Defaults to the theme's primary colour.
  final Color? color;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _InsigniaPainter(rank, dim ? tint.withValues(alpha: 0.35) : tint)),
    );
  }
}

class _InsigniaPainter extends CustomPainter with AiArt {
  _InsigniaPainter(this.rank, this.color);

  final Rank rank;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = color;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final family = rank.family;
    final grade = max(rank.grade, 1);

    // Shield outline, filled faintly
    final shield = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.92, h * 0.16)
      ..lineTo(w * 0.86, h * 0.6)
      ..quadraticBezierTo(w * 0.8, h * 0.84, w * 0.5, h * 0.97)
      ..quadraticBezierTo(w * 0.2, h * 0.84, w * 0.14, h * 0.6)
      ..lineTo(w * 0.08, h * 0.16)
      ..close();
    canvas.drawPath(shield, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawPath(shield, line);

    final c = Offset(w * 0.5, h * 0.5);

    if (family >= 17) {
      // Mythic and above: wreath of leaves around a star
      for (var i = 0; i < 14; i++) {
        final a = pi * 0.15 + i * (pi * 1.7) / 13;
        final p = c + Offset(cos(a), sin(a)) * w * 0.3;
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(a + pi / 2);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.08, height: w * 0.16), fill);
        canvas.restore();
      }
      _star(canvas, c, w * 0.18, fill);
      if (family == 18) _star(canvas, Offset(w * 0.5, h * 0.2), w * 0.07, fill);
      return;
    }

    if (family >= 14) {
      // Dozen upward: a ring of small stars
      final count = (family - 14) * 2 + 4 + (grade - 1) * 2;
      for (var i = 0; i < count; i++) {
        final a = -pi / 2 + i * 2 * pi / count;
        _star(canvas, c + Offset(cos(a), sin(a)) * w * 0.28, w * 0.07, fill);
      }
      _star(canvas, c, w * 0.12, fill);
      return;
    }

    if (family >= 10) {
      // Beignet to Pastry Chef: stars under a bar
      final stars = family - 9; // 1..4
      final spacing = w * 0.18;
      for (var i = 0; i < stars; i++) {
        final x = c.dx + (i - (stars - 1) / 2) * spacing;
        _star(canvas, Offset(x, h * 0.42), w * 0.08, fill);
      }
      for (var g = 0; g < grade; g++) {
        final y = h * 0.6 + g * h * 0.09;
        canvas.drawLine(Offset(w * 0.3, y), Offset(w * 0.7, y), line);
      }
      return;
    }

    if (family >= 5) {
      // Cruller to Boston Cream: bars above chevrons
      final bars = family - 4; // 1..5
      for (var b = 0; b < bars; b++) {
        final y = h * 0.22 + b * h * 0.08;
        canvas.drawLine(Offset(w * 0.3, y), Offset(w * 0.7, y), line);
      }
      for (var g = 0; g < grade; g++) {
        final y = h * 0.78 - g * h * 0.1;
        _chevron(canvas, c.dx, y, w * 0.34, h * 0.09, line);
      }
      return;
    }

    // Crumb to Jelly: chevrons only, more for each family
    final chevrons = family + grade - 1;
    if (chevrons == 0) {
      canvas.drawCircle(c, w * 0.08, fill);
      return;
    }
    for (var i = 0; i < chevrons; i++) {
      final y = h * 0.72 - i * h * 0.11;
      _chevron(canvas, c.dx, y, w * 0.36, h * 0.1, line);
    }
  }

  void _chevron(Canvas canvas, double cx, double y, double width, double depth, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(cx - width / 2, y)
        ..lineTo(cx, y - depth)
        ..lineTo(cx + width / 2, y),
      paint,
    );
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final p = Offset(c.dx + cos(a) * radius, c.dy + sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(_InsigniaPainter oldDelegate) => oldDelegate.rank != rank || oldDelegate.color != color;
}
