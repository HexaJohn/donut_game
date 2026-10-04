import 'dart:math';

import 'package:flutter/material.dart';

/// Size the revolver is drawn at; scale it with a [Transform] or [FittedBox].
const Size revolverSize = Size(120, 72);

/// Where the muzzle sits within [revolverSize], so a held gun can be lined up
/// with the cursor.
const Offset revolverMuzzle = Offset(118, 24);

/// A cartoon six-shooter pointing right.
class Revolver extends StatelessWidget {
  const Revolver({super.key, this.flash = false});

  /// Draws a muzzle flash at the barrel.
  final bool flash;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: revolverSize, painter: _RevolverPainter(flash));
  }
}

class _RevolverPainter extends CustomPainter {
  _RevolverPainter(this.flash);

  final bool flash;

  static const _outline = Color(0xFF1E2126);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final metal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC9CED6), Color(0xFF7D848F), Color(0xFF4A5059)],
      ).createShader(Offset.zero & size);

    void shape(Path path, Paint fill) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }

    // Grip
    shape(
      Path()
        ..moveTo(30, 36)
        ..lineTo(50, 38)
        ..quadraticBezierTo(46, 56, 40, 68)
        ..quadraticBezierTo(28, 72, 16, 66)
        ..quadraticBezierTo(22, 50, 30, 36)
        ..close(),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8D6E63), Color(0xFF5D4037)])
            .createShader(const Rect.fromLTWH(16, 36, 34, 36)),
    );
    // Grip panel lines
    final grain = Paint()
      ..color = const Color(0x553E2723)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(30, 46), const Offset(40, 47), grain);
    canvas.drawLine(const Offset(27, 53), const Offset(39, 54), grain);
    canvas.drawLine(const Offset(24, 60), const Offset(37, 61), grain);

    // Trigger guard and trigger
    canvas.drawArc(const Rect.fromLTWH(46, 34, 20, 20), 0, pi, false, line..strokeWidth = 3);
    line.strokeWidth = 2;
    canvas.drawLine(const Offset(55, 38), const Offset(53, 47), line);

    // Frame
    shape(
      Path()
        ..moveTo(26, 22)
        ..lineTo(70, 18)
        ..lineTo(72, 38)
        ..lineTo(32, 40)
        ..close(),
      metal,
    );
    // Hammer
    shape(
      Path()
        ..moveTo(26, 22)
        ..lineTo(20, 12)
        ..lineTo(28, 12)
        ..lineTo(34, 21)
        ..close(),
      metal,
    );
    // Barrel and front sight
    shape(Path()..addRRect(RRect.fromLTRBR(66, 19, 118, 30, const Radius.circular(2))), metal);
    shape(Path()..addRect(const Rect.fromLTWH(110, 15, 5, 4)), metal);
    // Ejector rod under the barrel
    shape(Path()..addRRect(RRect.fromLTRBR(70, 30, 104, 34, const Radius.circular(2))), metal);

    // Cylinder with flutes
    shape(Path()..addRRect(RRect.fromLTRBR(38, 16, 66, 40, const Radius.circular(6))), metal);
    final flute = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final y in [22.0, 28.0, 34.0]) {
      canvas.drawLine(Offset(43, y), Offset(61, y), flute);
    }
    // Shine
    canvas.drawLine(
        const Offset(70, 21),
        const Offset(112, 21),
        Paint()
          ..color = const Color(0x88FFFFFF)
          ..strokeWidth = 1.5);

    if (flash) {
      final c = revolverMuzzle + const Offset(10, 0);
      final star = Path();
      for (var i = 0; i < 16; i++) {
        final r = i.isEven ? 22.0 : 9.0;
        final a = i / 16 * 2 * pi;
        final p = c + Offset(cos(a) * r * 1.3, sin(a) * r);
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFB300));
      canvas.drawCircle(c, 7, Paint()..color = const Color(0xFFFFF8E1));
    }
  }

  @override
  bool shouldRepaint(_RevolverPainter oldDelegate) => oldDelegate.flash != flash;
}

/// A splintered bullet hole. [seed] varies its cracks and angle.
class BulletHoleMark extends StatelessWidget {
  const BulletHoleMark({super.key, required this.seed, required this.size, required this.surface});

  final int seed;
  final double size;

  /// Colour of what was shot (the felt), for the scorched ring.
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _HolePainter(seed, surface));
  }
}

class _HolePainter extends CustomPainter {
  _HolePainter(this.seed, this.surface);

  final int seed;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Scorch around the hole
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.lerp(surface, Colors.black, 0.55)!,
          Color.lerp(surface, Colors.black, 0.25)!.withValues(alpha: 0.5),
          surface.withValues(alpha: 0),
        ], stops: const [
          0.35,
          0.6,
          1
        ]).createShader(Rect.fromCircle(center: c, radius: r * 0.9)),
    );

    // Cracks radiating out
    final crack = Paint()
      ..color = Color.lerp(surface, Colors.black, 0.6)!
      ..strokeWidth = max(1, r * 0.06)
      ..strokeCap = StrokeCap.round;
    final count = 5 + random.nextInt(4);
    for (var i = 0; i < count; i++) {
      final a = i / count * 2 * pi + random.nextDouble() * 0.6;
      final length = r * (0.55 + random.nextDouble() * 0.45);
      final mid = c +
          Offset(cos(a), sin(a)) * length * 0.55 +
          Offset(random.nextDouble() - 0.5, random.nextDouble() - 0.5) * r * 0.15;
      final end = c + Offset(cos(a), sin(a)) * length;
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(mid.dx, mid.dy)
            ..lineTo(end.dx, end.dy),
          crack..style = PaintingStyle.stroke);
    }

    // The hole itself, slightly out of round
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(random.nextDouble() * pi);
    final hole = Rect.fromCenter(center: Offset.zero, width: r * 0.62, height: r * 0.54);
    canvas.drawOval(hole.inflate(r * 0.06), Paint()..color = Color.lerp(surface, Colors.white, 0.25)!);
    canvas.drawOval(
      hole,
      Paint()..shader = const RadialGradient(colors: [Color(0xFF000000), Color(0xFF1A1A1A)]).createShader(hole),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HolePainter oldDelegate) => oldDelegate.seed != seed || oldDelegate.surface != surface;
}
