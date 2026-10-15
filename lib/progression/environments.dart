import 'dart:math';

import 'package:donut_game/audit/ai_audit.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:flutter/material.dart';

/// What the table looks like: felt colours, and for some, a texture painted
/// over the felt.
class TableEnvironment {
  const TableEnvironment({required this.id, this.felt, this.edge, this.texture});

  final String id;

  /// Null follows the theme.
  final Color? felt;
  final Color? edge;
  final CustomPainter Function(Color felt)? texture;

  Color feltColor(DonutColors colors) => felt ?? colors.felt;
  Color edgeColor(DonutColors colors) => edge ?? colors.feltEdge;

  /// The environment with [id], or the theme's own felt if unknown.
  static TableEnvironment byId(String id) =>
      environments.firstWhere((env) => env.id == id, orElse: () => environments.first);
}

final List<TableEnvironment> environments = [
  const TableEnvironment(id: 'env.theme'),
  const TableEnvironment(id: 'env.blue', felt: Color(0xFF1F4E79), edge: Color(0xFF14354F)),
  const TableEnvironment(id: 'env.red', felt: Color(0xFF7A1F2B), edge: Color(0xFF4F121B)),
  const TableEnvironment(id: 'env.purple', felt: Color(0xFF4A1F6E), edge: Color(0xFF2E1245)),
  TableEnvironment(
      id: 'env.oak', felt: const Color(0xFF8A5A2B), edge: const Color(0xFF4F3217), texture: (felt) => _WoodPainter(felt)),
  TableEnvironment(
      id: 'env.marble',
      felt: const Color(0xFFE8E4DC),
      edge: const Color(0xFF9E978C),
      texture: (felt) => _MarblePainter(felt)),
  TableEnvironment(
      id: 'env.slate', felt: const Color(0xFF2E3338), edge: const Color(0xFF1A1D20), texture: (felt) => _SlatePainter(felt)),
  TableEnvironment(
      id: 'env.carbon',
      felt: const Color(0xFF1C1C1E),
      edge: const Color(0xFF3A3A3F),
      texture: (felt) => _CarbonPainter(felt)),
  TableEnvironment(
      id: 'env.denim', felt: const Color(0xFF3B5A8A), edge: const Color(0xFF24395A), texture: (felt) => _DenimPainter(felt)),
  TableEnvironment(
      id: 'env.grid', felt: const Color(0xFF0B0620), edge: const Color(0xFFFF2BD6), texture: (felt) => _GridPainter(felt)),
  TableEnvironment(
      id: 'env.galaxy',
      felt: const Color(0xFF070A1C),
      edge: const Color(0xFF2A2F5A),
      texture: (felt) => _GalaxyPainter(felt)),
  TableEnvironment(
      id: 'env.gold', felt: const Color(0xFFB8860B), edge: const Color(0xFF7A5A08), texture: (felt) => _GoldPainter(felt)),
  TableEnvironment(
      id: 'env.bakery',
      felt: const Color(0xFFF2EBDD),
      edge: const Color(0xFFB3261E),
      texture: (felt) => _BakeryPainter(felt)),
];

/// A texture painter that paints the same thing for the same felt colour.
abstract class _Texture extends CustomPainter with AiArt {
  _Texture(this.felt);

  final Color felt;

  @override
  bool shouldRepaint(covariant _Texture oldDelegate) => oldDelegate.felt != felt;
}

class _WoodPainter extends _Texture {
  _WoodPainter(super.felt);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(3);
    final dark = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke;
    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke;
    // Planks
    const plank = 72.0;
    for (var y = 0.0; y < size.height; y += plank) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()..color = Colors.black.withValues(alpha: 0.25)..strokeWidth = 2);
      // Grain lines wandering along each plank
      for (var i = 0; i < 9; i++) {
        final gy = y + 6 + random.nextDouble() * (plank - 12);
        final path = Path()..moveTo(0, gy);
        for (var x = 0.0; x < size.width; x += 60) {
          path.quadraticBezierTo(x + 30, gy + (random.nextDouble() - 0.5) * 8, x + 60, gy + (random.nextDouble() - 0.5) * 3);
        }
        canvas.drawPath(path, (i.isEven ? dark : light)..strokeWidth = 0.8 + random.nextDouble() * 1.4);
      }
      // A knot now and then
      if (random.nextDouble() < 0.6) {
        final c = Offset(random.nextDouble() * size.width, y + plank / 2);
        for (var r = 3.0; r < 14; r += 3) {
          canvas.drawOval(Rect.fromCenter(center: c, width: r * 2.4, height: r * 1.4), dark..strokeWidth = 1);
        }
      }
    }
  }
}

class _MarblePainter extends _Texture {
  _MarblePainter(super.felt);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(8);
    for (var i = 0; i < 14; i++) {
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: 0.05 + random.nextDouble() * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 + random.nextDouble() * 1.6;
      var p = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      final path = Path()..moveTo(p.dx, p.dy);
      final drift = Offset(random.nextDouble() - 0.5, random.nextDouble() - 0.5) * 2;
      for (var s = 0; s < 20; s++) {
        final next = p + drift * (30 + random.nextDouble() * 40) + Offset(random.nextDouble() - 0.5, random.nextDouble() - 0.5) * 40;
        path.quadraticBezierTo(p.dx + (random.nextDouble() - 0.5) * 50, p.dy + (random.nextDouble() - 0.5) * 50, next.dx, next.dy);
        p = next;
      }
      canvas.drawPath(path, paint);
    }
    // Soft cloudy patches
    for (var i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        40 + random.nextDouble() * 90,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.03)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }
  }
}

class _SlatePainter extends _Texture {
  _SlatePainter(super.felt);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(13);
    for (var i = 0; i < 900; i++) {
      final p = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      canvas.drawCircle(p, 0.6 + random.nextDouble() * 1.2,
          Paint()..color = (random.nextBool() ? Colors.white : Colors.black).withValues(alpha: 0.08));
    }
    // Cleavage lines
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final y = random.nextDouble() * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + (random.nextDouble() - 0.5) * 40), paint);
    }
  }
}

class _CarbonPainter extends _Texture {
  _CarbonPainter(super.felt);

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 10.0;
    final light = Paint()..color = Colors.white.withValues(alpha: 0.09);
    final dark = Paint()..color = Colors.black.withValues(alpha: 0.35);
    var row = 0;
    for (var y = 0.0; y < size.height; y += cell, row++) {
      var col = 0;
      for (var x = 0.0; x < size.width; x += cell, col++) {
        final weaveA = (row + col).isEven;
        final r = Rect.fromLTWH(x, y, cell, cell);
        canvas.drawRect(r, weaveA ? light : dark);
        // Fibre direction
        final fibre = Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = 1;
        for (var k = 2.0; k < cell; k += 3) {
          if (weaveA) {
            canvas.drawLine(Offset(x + k, y), Offset(x + k, y + cell), fibre);
          } else {
            canvas.drawLine(Offset(x, y + k), Offset(x + cell, y + k), fibre);
          }
        }
      }
    }
    // Glossy sweep
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.12), Colors.transparent, Colors.white.withValues(alpha: 0.06)],
        ).createShader(Offset.zero & size),
    );
  }
}

class _DenimPainter extends _Texture {
  _DenimPainter(super.felt);

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final dark = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), light);
    }
    for (var x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), dark);
    }
    // Worn patches
    final random = Random(21);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        50 + random.nextDouble() * 80,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }
    // Orange stitching around the edge
    final stitch = Paint()
      ..color = const Color(0xFFE0A040).withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const inset = 14.0;
    for (var x = inset + 4; x < size.width - inset; x += 10) {
      canvas.drawLine(Offset(x, inset), Offset(x + 5, inset), stitch);
      canvas.drawLine(Offset(x, size.height - inset), Offset(x + 5, size.height - inset), stitch);
    }
    for (var y = inset + 4; y < size.height - inset; y += 10) {
      canvas.drawLine(Offset(inset, y), Offset(inset, y + 5), stitch);
      canvas.drawLine(Offset(size.width - inset, y), Offset(size.width - inset, y + 5), stitch);
    }
  }
}

class _GridPainter extends _Texture {
  _GridPainter(super.felt);

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.42;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, horizon),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A0B4A), Color(0xFF7A1FA0), Color(0xFFFF6B9D)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, horizon)),
    );
    // Sun
    canvas.drawCircle(Offset(size.width / 2, horizon - 10), size.height * 0.16,
        Paint()..color = const Color(0xFFFFC857).withValues(alpha: 0.9));
    final line = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.65)
      ..strokeWidth = 1.2;
    final glow = Paint()
      ..color = const Color(0xFFFF2BD6).withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(Offset(0, horizon), Offset(size.width, horizon), glow);
    // Converging verticals
    final vanish = Offset(size.width / 2, horizon);
    for (var i = -12; i <= 12; i++) {
      final x = size.width / 2 + i * size.width / 9;
      canvas.drawLine(vanish, Offset(x, size.height), line);
    }
    // Horizontals bunching toward the horizon
    for (var k = 1; k < 14; k++) {
      final t = k / 14;
      final y = horizon + (size.height - horizon) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }
}

class _GalaxyPainter extends _Texture {
  _GalaxyPainter(super.felt);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(77);
    // Nebula clouds
    for (final (color, n) in [(const Color(0xFF6A2CCF), 4), (const Color(0xFF1E7BD6), 3), (const Color(0xFFD63C8F), 2)]) {
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(
          Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
          60 + random.nextDouble() * 140,
          Paint()
            ..color = color.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
        );
      }
    }
    for (var i = 0; i < 400; i++) {
      final p = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      final big = random.nextDouble() < 0.08;
      canvas.drawCircle(p, big ? 1.8 : 0.9, Paint()..color = Colors.white.withValues(alpha: big ? 0.95 : 0.4 + random.nextDouble() * 0.4));
    }
  }
}

class _GoldPainter extends _Texture {
  _GoldPainter(super.felt);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(31);
    // Leaf squares, each slightly different
    const leaf = 48.0;
    for (var y = 0.0; y < size.height; y += leaf) {
      for (var x = 0.0; x < size.width; x += leaf) {
        final tone = (random.nextDouble() - 0.5) * 0.16;
        canvas.drawRect(
          Rect.fromLTWH(x, y, leaf, leaf),
          Paint()..color = (tone > 0 ? Colors.white : Colors.black).withValues(alpha: tone.abs()),
        );
      }
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.transparent,
            Colors.white.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0, 0.35, 0.6, 1],
        ).createShader(Offset.zero & size),
    );
    // Hairline cracks between leaves
    final crack = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 0.7;
    for (var y = 0.0; y < size.height; y += leaf) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), crack);
    }
    for (var x = 0.0; x < size.width; x += leaf) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), crack);
    }
  }
}

class _BakeryPainter extends _Texture {
  _BakeryPainter(super.felt);

  @override
  void paint(Canvas canvas, Size size) {
    const tile = 40.0;
    final red = Paint()..color = const Color(0xFFB3261E).withValues(alpha: 0.85);
    var row = 0;
    for (var y = 0.0; y < size.height; y += tile, row++) {
      var col = 0;
      for (var x = 0.0; x < size.width; x += tile, col++) {
        if ((row + col).isOdd) canvas.drawRect(Rect.fromLTWH(x, y, tile, tile), red);
      }
    }
    final grout = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1.5;
    for (var y = 0.0; y < size.height; y += tile) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grout);
    }
    for (var x = 0.0; x < size.width; x += tile) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grout);
    }
    // Flour dust
    final random = Random(5);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        30 + random.nextDouble() * 60,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
      );
    }
  }
}
