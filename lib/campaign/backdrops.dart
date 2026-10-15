import 'dart:math';

import 'package:donut_game/audit/ai_audit.dart';
import 'package:donut_game/ui/widget/rasterized_paint.dart';
import 'package:flutter/material.dart';

/// The scene behind the table in a campaign venue. Painted, not pictures, so
/// it scales to any window. Kept dim and soft so the seats and cards on top
/// stay easy to read.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    // Painted to an image once: the scene never changes, but it would
    // otherwise be redrawn shape by shape on every frame of every animation
    return RepaintBoundary(child: ClipRect(child: RasterizedPaint(painter: backdropPainter(id), cacheKey: id)));
  }
}

CustomPainter backdropPainter(String id) => switch (id) {
      'backdrop.bakery' => const _BakeryBackdrop(),
      'backdrop.market' => const _MarketBackdrop(),
      'backdrop.diner' => const _DinerBackdrop(),
      'backdrop.riverboat' => const _RiverboatBackdrop(),
      'backdrop.orbital' => const _OrbitalBackdrop(),
      'backdrop.grand' => const _GrandBackdrop(),
      _ => const _BakeryBackdrop(),
    };

/// Fixed pseudo-random numbers, so a backdrop looks the same every frame.
class _Seeded {
  _Seeded(this._seed);

  int _seed;

  double next() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}

void _gradient(Canvas canvas, Rect rect, List<Color> colors, {List<double>? stops}) {
  canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors, stops: stops)
            .createShader(rect));
}

/// Darkens the edges a little, drawing the eye to the table.
void _vignette(Canvas canvas, Rect rect, [double strength = 0.45]) {
  canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [Colors.transparent, Colors.black.withValues(alpha: strength)],
          stops: const [0.55, 1],
        ).createShader(rect));
}

abstract class _Scene extends CustomPainter with AiArt {
  const _Scene();

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => oldDelegate.runtimeType != runtimeType;
}

class _BakeryBackdrop extends _Scene {
  const _BakeryBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _gradient(canvas, rect, const [Color(0xFFF3DDBA), Color(0xFFE2BE8E)]);
    // Subway tiles on the lower wall
    final tileTop = size.height * 0.45;
    canvas.drawRect(Rect.fromLTRB(0, tileTop, size.width, size.height), Paint()..color = const Color(0xFFF7EFE2));
    final grout = Paint()
      ..color = const Color(0xFFD9CBB4)
      ..strokeWidth = 1.2;
    const tileW = 46.0, tileH = 22.0;
    var row = 0;
    for (var y = tileTop; y < size.height; y += tileH, row++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grout);
      for (var x = row.isEven ? 0.0 : tileW / 2; x < size.width; x += tileW) {
        canvas.drawLine(Offset(x, y), Offset(x, y + tileH), grout);
      }
    }
    // Shelves with loaves and donuts
    final shelf = Paint()..color = const Color(0xFF8A5A2B);
    final random = _Seeded(3);
    for (final y in [size.height * 0.16, size.height * 0.34]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-4, y, size.width + 8, 9), const Radius.circular(3)), shelf);
      var x = 18.0;
      while (x < size.width - 30) {
        if (random.next() < 0.5) {
          final w = 34 + random.next() * 14;
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y - 16, w, 16), const Radius.circular(9)),
              Paint()..color = const Color(0xFFC88A45));
          x += w + 10;
        } else {
          final r = 9 + random.next() * 3;
          final c = Offset(x + r, y - r);
          canvas.drawCircle(c, r, Paint()..color = const Color(0xFFD9A066));
          canvas.drawCircle(
              c, r * 0.8, Paint()..color = [const Color(0xFFE85D9A), const Color(0xFF6B3A1E)][x.toInt() % 2]);
          canvas.drawCircle(c, r * 0.32, Paint()..color = const Color(0xFFE8CDA4));
          x += r * 2 + 10;
        }
        x += random.next() * 30;
      }
    }
    _vignette(canvas, rect, 0.3);
  }
}

class _MarketBackdrop extends _Scene {
  const _MarketBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _gradient(canvas, rect, const [Color(0xFF0E1033), Color(0xFF2B1648), Color(0xFF40183C)]);
    final random = _Seeded(11);
    // A few stars
    for (var i = 0; i < 60; i++) {
      canvas.drawCircle(Offset(random.next() * size.width, random.next() * size.height * 0.5), random.next() * 1.2,
          Paint()..color = Colors.white.withValues(alpha: 0.3 + random.next() * 0.4));
    }
    // Strings of lanterns sagging across the sky
    const colours = [Color(0xFFFF6B3D), Color(0xFFFFC24B), Color(0xFFE8445A)];
    for (var s = 0; s < 3; s++) {
      final y = size.height * (0.1 + s * 0.13);
      final sag = 30.0 + s * 10;
      final wire = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width / 2, y + sag * 2, size.width, y);
      canvas.drawPath(
          wire,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      final metric = wire.computeMetrics().first;
      for (var d = 20.0; d < metric.length; d += 54) {
        final p = metric.getTangentForOffset(d)!.position;
        final colour = colours[(d ~/ 54 + s) % colours.length];
        canvas.drawCircle(p + const Offset(0, 9), 16, Paint()..color = colour.withValues(alpha: 0.18));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: p + const Offset(0, 9), width: 13, height: 16), const Radius.circular(6)),
            Paint()..color = colour);
      }
    }
    // Stall roofs along the bottom
    final roof = Paint()..color = const Color(0xFF14091F);
    var x = -20.0;
    while (x < size.width) {
      final w = 120 + random.next() * 80;
      final top = size.height * (0.62 + random.next() * 0.08);
      canvas.drawPath(
          Path()
            ..moveTo(x, size.height)
            ..lineTo(x, top + 20)
            ..lineTo(x + w / 2, top)
            ..lineTo(x + w, top + 20)
            ..lineTo(x + w, size.height)
            ..close(),
          roof);
      x += w - 10;
    }
    _vignette(canvas, rect);
  }
}

class _DinerBackdrop extends _Scene {
  const _DinerBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _gradient(canvas, rect, const [Color(0xFF1E5F63), Color(0xFF2E7F80)]);
    // Chrome trim
    final trimY = size.height * 0.55;
    _gradient(canvas, Rect.fromLTWH(0, trimY, size.width, 14),
        const [Color(0xFFF2F4F5), Color(0xFF9AA4A8), Color(0xFFE3E7E9)]);
    // Checkerboard floor in perspective
    final floorTop = trimY + 14;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, floorTop, size.width, size.height));
    canvas.drawRect(Rect.fromLTRB(0, floorTop, size.width, size.height), Paint()..color = const Color(0xFFF0EDE6));
    final dark = Paint()..color = const Color(0xFF1C1C1E);
    final vanish = Offset(size.width / 2, floorTop - size.height * 0.6);
    const columns = 24;
    for (var row = 0; row < 12; row++) {
      final t0 = row / 12, t1 = (row + 1) / 12;
      double yAt(double t) => floorTop + (size.height - floorTop) * pow(t, 1.6);
      for (var c = -columns; c < columns; c++) {
        if ((row + c).isEven) continue;
        Offset at(double cx, double t) {
          final y = yAt(t);
          final spread = (y - vanish.dy) / (size.height - vanish.dy);
          return Offset(vanish.dx + (cx * 60) * spread * 2.2, y);
        }

        canvas.drawPath(
            Path()
              ..moveTo(at(c.toDouble(), t0).dx, at(c.toDouble(), t0).dy)
              ..lineTo(at(c + 1.0, t0).dx, at(c + 1.0, t0).dy)
              ..lineTo(at(c + 1.0, t1).dx, at(c + 1.0, t1).dy)
              ..lineTo(at(c.toDouble(), t1).dx, at(c.toDouble(), t1).dy)
              ..close(),
            dark);
      }
    }
    canvas.restore();
    // Neon donut sign
    final sign = Offset(size.width * 0.82, size.height * 0.24);
    final radius = min(size.width, size.height) * 0.08;
    for (final (width, alpha) in [(18.0, 0.12), (10.0, 0.25), (4.0, 1.0)]) {
      canvas.drawCircle(
          sign,
          radius,
          Paint()
            ..color = const Color(0xFFFF4FA3).withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = width);
    }
    canvas.drawCircle(
        sign,
        radius * 0.4,
        Paint()
          ..color = const Color(0xFF7DF9FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    _vignette(canvas, rect, 0.4);
  }
}

class _RiverboatBackdrop extends _Scene {
  const _RiverboatBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Dark wood panelling
    canvas.drawRect(rect, Paint()..color = const Color(0xFF3B2416));
    final random = _Seeded(5);
    const plank = 38.0;
    for (var x = 0.0; x < size.width; x += plank) {
      final shade = 0.85 + random.next() * 0.3;
      canvas.drawRect(Rect.fromLTWH(x, 0, plank - 2, size.height),
          Paint()..color = Color.lerp(const Color(0xFF2A190F), const Color(0xFF55331E), shade - 0.5)!);
    }
    // Portholes showing the moonlit river
    final y = size.height * 0.3;
    final r = min(size.width, size.height) * 0.07;
    for (final fx in [0.15, 0.85]) {
      final c = Offset(size.width * fx, y);
      canvas.drawCircle(c, r + 7, Paint()..color = const Color(0xFFB58A3C));
      final glass = Rect.fromCircle(center: c, radius: r);
      canvas.save();
      canvas.clipPath(Path()..addOval(glass));
      _gradient(canvas, glass, const [Color(0xFF0D1B3A), Color(0xFF1F3C6B), Color(0xFF0A1428)],
          stops: const [0, 0.55, 1]);
      canvas.drawCircle(c + Offset(r * 0.3, -r * 0.35), r * 0.18, Paint()..color = const Color(0xFFF4F1D8));
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
            Offset(c.dx - r + random.next() * r, c.dy + r * (0.2 + i * 0.18)),
            Offset(c.dx + random.next() * r, c.dy + r * (0.2 + i * 0.18)),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.25)
              ..strokeWidth = 1.2);
      }
      canvas.restore();
    }
    // Brass rail
    _gradient(
        canvas, Rect.fromLTWH(0, size.height * 0.58, size.width, 8), const [Color(0xFFE8C46A), Color(0xFF8C6420)]);
    // Velvet curtains at the sides
    for (final left in [true, false]) {
      final w = size.width * 0.07;
      final x0 = left ? 0.0 : size.width - w;
      final curtain = Rect.fromLTWH(x0, 0, w, size.height);
      canvas.drawRect(
          curtain,
          Paint()
            ..shader = const LinearGradient(colors: [Color(0xFF5A0F1C), Color(0xFF8E1B2E), Color(0xFF5A0F1C)])
                .createShader(Rect.fromLTWH(x0, 0, w / 2, size.height)));
    }
    _vignette(canvas, rect, 0.5);
  }
}

class _OrbitalBackdrop extends _Scene {
  const _OrbitalBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF03040C));
    final random = _Seeded(23);
    for (var i = 0; i < 220; i++) {
      final big = random.next() < 0.06;
      canvas.drawCircle(Offset(random.next() * size.width, random.next() * size.height),
          big ? 1.6 : random.next() * 0.9, Paint()..color = Colors.white.withValues(alpha: 0.35 + random.next() * 0.6));
    }
    // A planet rising at the bottom
    final planet = Offset(size.width * 0.3, size.height * 1.55);
    final pr = size.height * 0.85;
    canvas.drawCircle(planet, pr + 18, Paint()..color = const Color(0xFF4FA3FF).withValues(alpha: 0.12));
    canvas.drawCircle(
        planet,
        pr,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0.3, -0.8),
            colors: [Color(0xFF3B7DD8), Color(0xFF1A3A78), Color(0xFF07122E)],
            stops: [0, 0.4, 1],
          ).createShader(Rect.fromCircle(center: planet, radius: pr)));
    // The station window: a frame with struts
    final frame = Paint()
      ..color = const Color(0xFF2A2F3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(60)), frame);
    final strut = Paint()
      ..color = const Color(0xFF2A2F3A)
      ..strokeWidth = 10;
    canvas.drawLine(Offset(size.width * 0.33, 0), Offset(size.width * 0.33, size.height), strut);
    canvas.drawLine(Offset(size.width * 0.67, 0), Offset(size.width * 0.67, size.height), strut);
    _vignette(canvas, rect, 0.35);
  }
}

class _GrandBackdrop extends _Scene {
  const _GrandBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _gradient(canvas, rect, const [Color(0xFF3A0C18), Color(0xFF5A1426)]);
    const gold = Color(0xFFC9A227);
    // Wainscot panels
    final panelTop = size.height * 0.5;
    final outline = Paint()
      ..color = gold.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const panelW = 120.0;
    for (var x = 20.0; x < size.width - 40; x += panelW + 20) {
      canvas.drawRect(Rect.fromLTWH(x, panelTop + 20, panelW, size.height - panelTop - 40), outline);
      canvas.drawRect(Rect.fromLTWH(x + 8, panelTop + 28, panelW - 16, size.height - panelTop - 56), outline);
    }
    canvas.drawLine(
        Offset(0, panelTop),
        Offset(size.width, panelTop),
        Paint()
          ..color = gold
          ..strokeWidth = 4);
    // A chandelier hanging over the table
    final hub = Offset(size.width / 2, size.height * 0.12);
    canvas.drawLine(
        Offset(hub.dx, 0),
        hub,
        Paint()
          ..color = gold
          ..strokeWidth = 2);
    for (var tier = 0; tier < 2; tier++) {
      final w = 150.0 - tier * 60;
      final y = hub.dy + tier * 26;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(hub.dx, y), width: w * 2, height: 40),
          0,
          pi,
          false,
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      for (var i = 0; i <= 6; i++) {
        final a = pi * i / 6;
        final p = Offset(hub.dx + cos(a) * w, y + sin(a) * 20);
        canvas.drawCircle(p, 14, Paint()..color = const Color(0xFFFFE6A0).withValues(alpha: 0.18));
        canvas.drawCircle(p, 4, Paint()..color = const Color(0xFFFFF4D0));
      }
    }
    // Gold sconce glows along the wall
    for (final fx in [0.1, 0.9]) {
      final c = Offset(size.width * fx, size.height * 0.3);
      canvas.drawCircle(c, 34, Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.1));
      canvas.drawCircle(c, 5, Paint()..color = const Color(0xFFFFF4D0));
    }
    _vignette(canvas, rect, 0.4);
  }
}
