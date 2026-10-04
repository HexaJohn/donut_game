import 'package:donut_game/res/resources.dart';
import 'package:flutter/material.dart';

/// A drawn suit symbol. Font glyphs shrink badly at card-corner sizes, where
/// a club's lobes smear into a spade-like blob; these shapes stay distinct:
/// clubs are three separate round lobes, spades a single pointed leaf.
class SuitIcon extends StatelessWidget {
  const SuitIcon(this.suit, {super.key, required this.size, required this.color});

  final Suit suit;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _SuitPainter(suit, color));
  }
}

class _SuitPainter extends CustomPainter {
  _SuitPainter(this.suit, this.color);

  final Suit suit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);
    canvas.drawPath(_paths[suit]!, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SuitPainter oldDelegate) => oldDelegate.suit != suit || oldDelegate.color != color;
}

/// Flared stem shared by spades and clubs, from the body down to the base.
Path _stem(double top, double neck) => Path()
  ..moveTo(0.5 - neck, top)
  ..quadraticBezierTo(0.48, 0.86, 0.3, 0.97)
  ..lineTo(0.7, 0.97)
  ..quadraticBezierTo(0.52, 0.86, 0.5 + neck, top)
  ..close();

/// Each shape is drawn in a 1 x 1 box.
final Map<Suit, Path> _paths = {
  Suit.hearts: Path()
    ..moveTo(0.5, 0.95)
    ..cubicTo(0.18, 0.7, 0.02, 0.52, 0.04, 0.32)
    ..cubicTo(0.06, 0.12, 0.3, 0.02, 0.5, 0.24)
    ..cubicTo(0.7, 0.02, 0.94, 0.12, 0.96, 0.32)
    ..cubicTo(0.98, 0.52, 0.82, 0.7, 0.5, 0.95)
    ..close(),
  Suit.diamonds: Path()
    ..moveTo(0.5, 0.02)
    ..quadraticBezierTo(0.66, 0.3, 0.88, 0.5)
    ..quadraticBezierTo(0.66, 0.7, 0.5, 0.98)
    ..quadraticBezierTo(0.34, 0.7, 0.12, 0.5)
    ..quadraticBezierTo(0.34, 0.3, 0.5, 0.02)
    ..close(),
  // Pointed leaf: an upside-down heart with a sharp tip
  Suit.spades: Path.combine(
    PathOperation.union,
    Path()
      ..moveTo(0.5, 0.02)
      ..cubicTo(0.66, 0.24, 0.96, 0.38, 0.96, 0.6)
      ..cubicTo(0.96, 0.8, 0.7, 0.86, 0.5, 0.7)
      ..cubicTo(0.3, 0.86, 0.04, 0.8, 0.04, 0.6)
      ..cubicTo(0.04, 0.38, 0.34, 0.24, 0.5, 0.02)
      ..close(),
    _stem(0.66, 0.05),
  ),
  // Three clearly separate round lobes, joined only at the centre
  Suit.clubs: Path.combine(
    PathOperation.union,
    Path()
      ..addOval(Rect.fromCircle(center: const Offset(0.5, 0.25), radius: 0.215))
      ..addOval(Rect.fromCircle(center: const Offset(0.255, 0.6), radius: 0.215))
      ..addOval(Rect.fromCircle(center: const Offset(0.745, 0.6), radius: 0.215))
      ..addOval(Rect.fromCircle(center: const Offset(0.5, 0.52), radius: 0.11)),
    _stem(0.55, 0.045),
  ),
};
