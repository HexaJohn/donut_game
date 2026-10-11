import 'dart:math';

import 'package:flutter/material.dart';

/// Paints the back of a card in the pattern [id] from the catalog. Each is
/// drawn with [pattern] ink on a [back] fill, so it follows the theme.
class CardBackPainter extends CustomPainter {
  CardBackPainter({required this.id, required this.pattern, required this.back});

  final String id;
  final Color pattern;
  final Color back;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    switch (id) {
      case 'pattern.dots':
        _dots(canvas, size);
      case 'pattern.chevrons':
        _chevrons(canvas, size);
      case 'pattern.waves':
        _waves(canvas, size);
      case 'pattern.sprinkles':
        _sprinkles(canvas, size);
      case 'pattern.hexes':
        _hexes(canvas, size);
      case 'pattern.stars':
        _stars(canvas, size);
      case 'pattern.plaid':
        _plaid(canvas, size);
      case 'pattern.circuit':
        _circuit(canvas, size);
      case 'pattern.argyle':
        _argyle(canvas, size);
      case 'pattern.filigree':
        _filigree(canvas, size);
      case 'pattern.galaxy':
        _galaxy(canvas, size);
      case 'pattern.bakers_seal':
        _bakersSeal(canvas, size);
      case 'pattern.midnight_glaze':
        _midnightGlaze(canvas, size);
      default:
        _classic(canvas, size);
    }
  }

  Paint _ink(double alpha, {PaintingStyle style = PaintingStyle.fill, double width = 1}) => Paint()
    ..color = pattern.withValues(alpha: alpha)
    ..style = style
    ..strokeWidth = width;

  void _frame(Canvas canvas, Size size, [double alpha = 0.6]) {
    canvas.drawRect(Offset.zero & size, _ink(alpha, style: PaintingStyle.stroke, width: 1.5));
  }

  void _donut(Canvas canvas, Offset c, double radius, double alpha) {
    canvas.drawCircle(c, radius, _ink(alpha, style: PaintingStyle.stroke, width: radius * 0.95));
  }

  void _classic(Canvas canvas, Size size) {
    _frame(canvas, size);
    final lines = _ink(0.28);
    const step = 9.0;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lines);
      canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), lines);
    }
    _donut(canvas, size.center(Offset.zero), 11.5, 0.9);
  }

  void _dots(Canvas canvas, Size size) {
    _frame(canvas, size);
    final paint = _ink(0.55);
    const step = 11.0;
    var row = 0;
    for (var y = 6.0; y < size.height; y += step, row++) {
      for (var x = row.isEven ? 6.0 : 6.0 + step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 2.2, paint);
      }
    }
    _donut(canvas, size.center(Offset.zero), 11.5, 0.9);
  }

  void _chevrons(Canvas canvas, Size size) {
    _frame(canvas, size);
    final paint = _ink(0.5, style: PaintingStyle.stroke, width: 3);
    const h = 10.0;
    const w = 14.0;
    for (var y = -h; y < size.height + h; y += h * 2) {
      final path = Path()..moveTo(0, y);
      var up = false;
      for (var x = 0.0; x <= size.width + w; x += w) {
        path.lineTo(x, up ? y : y + h);
        up = !up;
      }
      canvas.drawPath(path, paint);
    }
  }

  void _waves(Canvas canvas, Size size) {
    _frame(canvas, size);
    final paint = _ink(0.5, style: PaintingStyle.stroke, width: 2);
    const amp = 3.0;
    const wave = 18.0;
    for (var y = 4.0; y < size.height; y += 9) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x < size.width + wave; x += wave) {
        path.quadraticBezierTo(x + wave / 4, y - amp, x + wave / 2, y);
        path.quadraticBezierTo(x + wave * 3 / 4, y + amp, x + wave, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _sprinkles(Canvas canvas, Size size) {
    _frame(canvas, size);
    final random = Random(7);
    final paint = Paint()
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 48; i++) {
      final p = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      final angle = random.nextDouble() * pi;
      final hue = (random.nextDouble() * 360);
      paint.color = HSLColor.fromAHSL(0.85, hue, 0.8, 0.7).toColor();
      canvas.drawLine(p, p + Offset(cos(angle), sin(angle)) * 6, paint);
    }
    _donut(canvas, size.center(Offset.zero), 11.5, 0.9);
  }

  void _hexes(Canvas canvas, Size size) {
    _frame(canvas, size);
    final paint = _ink(0.5, style: PaintingStyle.stroke, width: 1.2);
    const r = 7.0;
    final w = r * sqrt(3);
    var row = 0;
    for (var y = 0.0; y < size.height + r; y += r * 1.5, row++) {
      for (var x = row.isOdd ? w / 2 : 0.0; x < size.width + w; x += w) {
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = pi / 6 + i * pi / 3;
          final p = Offset(x + cos(a) * r, y + sin(a) * r);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path..close(), paint);
      }
    }
  }

  void _stars(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: 0.25));
    _frame(canvas, size);
    final random = Random(42);
    for (var i = 0; i < 70; i++) {
      final p = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      final big = random.nextDouble() < 0.15;
      canvas.drawCircle(p, big ? 1.6 : 0.8, _ink(big ? 0.95 : 0.6));
    }
    // One four-point star
    final c = size.center(Offset.zero);
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final radius = i.isEven ? 11.0 : 3.0;
      final a = -pi / 2 + i * pi / 4;
      final p = Offset(c.dx + cos(a) * radius, c.dy + sin(a) * radius);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), _ink(0.9));
  }

  void _plaid(Canvas canvas, Size size) {
    const step = 16.0;
    final wide = _ink(0.35, style: PaintingStyle.stroke, width: 6);
    final thin = _ink(0.6, style: PaintingStyle.stroke, width: 1);
    for (var x = step / 2; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), wide);
      canvas.drawLine(Offset(x + 5, 0), Offset(x + 5, size.height), thin);
    }
    for (var y = step / 2; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), wide);
      canvas.drawLine(Offset(0, y + 5), Offset(size.width, y + 5), thin);
    }
    _frame(canvas, size);
  }

  void _circuit(Canvas canvas, Size size) {
    _frame(canvas, size);
    final random = Random(11);
    final trace = _ink(0.7, style: PaintingStyle.stroke, width: 1.4);
    final pad = _ink(0.9);
    const grid = 8.0;
    for (var i = 0; i < 26; i++) {
      var p = Offset((random.nextInt((size.width / grid).floor())) * grid, (random.nextInt((size.height / grid).floor())) * grid);
      final path = Path()..moveTo(p.dx, p.dy);
      canvas.drawCircle(p, 1.8, pad);
      final steps = 2 + random.nextInt(3);
      for (var s = 0; s < steps; s++) {
        final dir = random.nextInt(4);
        final len = grid * (1 + random.nextInt(3));
        p += switch (dir) {
          0 => Offset(len, 0),
          1 => Offset(-len, 0),
          2 => Offset(0, len),
          _ => Offset(0, -len),
        };
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, trace);
      canvas.drawCircle(p, 1.8, pad);
    }
  }

  void _argyle(Canvas canvas, Size size) {
    const w = 22.0;
    const h = 32.0;
    final fill = _ink(0.35);
    final line = _ink(0.7, style: PaintingStyle.stroke, width: 0.8);
    for (var y = -h; y < size.height + h; y += h) {
      for (var x = -w; x < size.width + w; x += w) {
        final diamond = Path()
          ..moveTo(x + w / 2, y)
          ..lineTo(x + w, y + h / 2)
          ..lineTo(x + w / 2, y + h)
          ..lineTo(x, y + h / 2)
          ..close();
        if (((x / w).round() + (y / h).round()).isEven) canvas.drawPath(diamond, fill);
      }
    }
    for (var y = -h; y < size.height + h; y += h) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + size.width * h / w), line);
      canvas.drawLine(Offset(size.width, y), Offset(0, y + size.width * h / w), line);
    }
    _frame(canvas, size);
  }

  void _filigree(Canvas canvas, Size size) {
    _frame(canvas, size, 0.9);
    canvas.drawRect((Offset.zero & size).deflate(4), _ink(0.5, style: PaintingStyle.stroke, width: 0.8));
    final stroke = _ink(0.85, style: PaintingStyle.stroke, width: 1.2);
    final c = size.center(Offset.zero);
    // Corner scrolls
    for (final corner in [
      (const Offset(6, 6), 1.0, 1.0),
      (Offset(size.width - 6, 6), -1.0, 1.0),
      (Offset(6, size.height - 6), 1.0, -1.0),
      (Offset(size.width - 6, size.height - 6), -1.0, -1.0),
    ]) {
      final (o, sx, sy) = corner;
      final path = Path()
        ..moveTo(o.dx, o.dy + 14 * sy)
        ..cubicTo(o.dx, o.dy + 4 * sy, o.dx + 4 * sx, o.dy, o.dx + 14 * sx, o.dy)
        ..moveTo(o.dx + 3 * sx, o.dy + 10 * sy)
        ..quadraticBezierTo(o.dx + 10 * sx, o.dy + 10 * sy, o.dx + 10 * sx, o.dy + 3 * sy);
      canvas.drawPath(path, stroke);
    }
    // Central medallion: ring of petals around a donut
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final tip = c + Offset(cos(a), sin(a)) * 24;
      final side = Offset(-sin(a), cos(a)) * 5;
      final path = Path()
        ..moveTo(c.dx + cos(a) * 14, c.dy + sin(a) * 14)
        ..quadraticBezierTo(tip.dx + side.dx, tip.dy + side.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(tip.dx - side.dx, tip.dy - side.dy, c.dx + cos(a) * 14, c.dy + sin(a) * 14);
      canvas.drawPath(path, stroke);
    }
    canvas.drawCircle(c, 30, _ink(0.5, style: PaintingStyle.stroke, width: 0.8));
    _donut(canvas, c, 8, 0.95);
  }

  void _galaxy(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [pattern.withValues(alpha: 0.55), pattern.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.4)],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: c, radius: size.height * 0.7)),
    );
    // Spiral arms
    final arm = _ink(0.55, style: PaintingStyle.stroke, width: 3);
    for (var k = 0; k < 2; k++) {
      final path = Path();
      for (var t = 0.0; t < 3 * pi; t += 0.15) {
        final r = 3 + t * 5;
        final p = c + Offset(cos(t + k * pi) * r, sin(t + k * pi) * r * 0.8);
        t == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, arm);
    }
    final random = Random(99);
    for (var i = 0; i < 60; i++) {
      final p = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      canvas.drawCircle(p, random.nextDouble() < 0.2 ? 1.4 : 0.7, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
    _frame(canvas, size, 0.8);
  }

  void _bakersSeal(Canvas canvas, Size size) {
    _frame(canvas, size, 0.9);
    final c = size.center(Offset.zero);
    // Faint wheat stalks either side
    final stroke = _ink(0.7, style: PaintingStyle.stroke, width: 1.2)..strokeCap = StrokeCap.round;
    for (final sx in [-1.0, 1.0]) {
      final base = Offset(c.dx + sx * 30, size.height - 10);
      canvas.drawLine(base, Offset(c.dx + sx * 24, 14), stroke);
      for (var i = 0; i < 7; i++) {
        final p = Offset.lerp(base, Offset(c.dx + sx * 24, 14), 0.3 + i * 0.1)!;
        canvas.drawLine(p, p + Offset(sx * 5, -4), stroke);
        canvas.drawLine(p, p + Offset(-sx * 3, -4), stroke);
      }
    }
    // Rubber stamp ring with ticks
    canvas.drawCircle(c, 28, _ink(0.9, style: PaintingStyle.stroke, width: 2.5));
    canvas.drawCircle(c, 22, _ink(0.6, style: PaintingStyle.stroke, width: 1));
    for (var i = 0; i < 24; i++) {
      final a = i * pi / 12;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * 23, c + Offset(cos(a), sin(a)) * 26.5, _ink(0.8, width: 1.2));
    }
    _donut(canvas, c, 9, 0.95);
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? 4.0 : 1.8;
      final a = -pi / 2 + i * pi / 5;
      final p = Offset(c.dx + cos(a) * radius, c.dy + sin(a) * radius);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), _ink(1));
  }

  void _midnightGlaze(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: 0.35));
    // Glaze dripping from the top edge
    final glaze = Paint()..color = pattern.withValues(alpha: 0.85);
    final random = Random(5);
    final drips = Path()..moveTo(0, 0);
    var x = 0.0;
    while (x < size.width) {
      final w = 8 + random.nextDouble() * 10;
      final depth = 14 + random.nextDouble() * 30;
      drips.lineTo(x, 14);
      drips.quadraticBezierTo(x + w * 0.5, 14, x + w * 0.5, depth);
      drips.quadraticBezierTo(x + w * 0.5, depth + 6, x + w * 0.5 + 1, depth);
      drips.quadraticBezierTo(x + w * 0.5 + 2, 14, x + w, 14);
      x += w;
    }
    drips
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(drips, glaze);
    canvas.drawPath(drips, Paint()..color = Colors.white.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    // Shine spots
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(Offset(random.nextDouble() * size.width, 4 + random.nextDouble() * 8), 1.2,
          Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
    _frame(canvas, size, 0.7);
    _donut(canvas, Offset(size.width / 2, size.height * 0.62), 12, 0.95);
  }

  @override
  bool shouldRepaint(CardBackPainter oldDelegate) =>
      oldDelegate.id != id || oldDelegate.pattern != pattern || oldDelegate.back != back;
}
