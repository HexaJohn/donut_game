import 'package:donut_game/data/model/ink_stroke.dart';
import 'package:flutter/material.dart';

/// Marker colours in the tray.
const markerColors = <Color>[
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFFFAFAFA),
];

/// Stroke widths as fractions of the felt's width.
const double markerWidth = 0.005;
const double eraserWidth = 0.035;

/// Size a marker is drawn at; its tip is at [markerTip].
const Size markerSize = Size(96, 22);
const Offset markerTip = Offset(0, 11);

/// A felt-tip marker lying on its side, tip pointing left.
class MarkerPen extends StatelessWidget {
  const MarkerPen({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: markerSize, painter: _MarkerPainter(color));
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    void shape(Path path, Color fill) {
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(path, outline);
    }

    // Felt tip
    shape(
      Path()
        ..moveTo(1, 11)
        ..lineTo(12, 6)
        ..lineTo(12, 16)
        ..close(),
      color,
    );
    // Collar
    shape(Path()..addRect(const Rect.fromLTWH(12, 4, 8, 14)), const Color(0xFFB0BEC5));
    // Body
    shape(Path()..addRRect(RRect.fromLTRBR(20, 3, 76, 19, const Radius.circular(3))), const Color(0xFFF5F5F5));
    // Colour band
    canvas.drawRect(const Rect.fromLTWH(34, 4, 16, 14), Paint()..color = color);
    // Cap on the back end
    shape(Path()..addRRect(RRect.fromLTRBR(74, 2, 95, 20, const Radius.circular(5))), color);
    // Shine
    canvas.drawLine(
        const Offset(22, 7),
        const Offset(72, 7),
        Paint()
          ..color = const Color(0x99FFFFFF)
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_MarkerPainter oldDelegate) => oldDelegate.color != color;
}

/// Size the eraser block is drawn at.
const Size eraserSize = Size(64, 34);

/// A classic two-tone rubber eraser.
class EraserBlock extends StatelessWidget {
  const EraserBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: eraserSize.width,
      height: eraserSize.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF263238), width: 1.5),
        gradient: const LinearGradient(
          colors: [Color(0xFFF8BBD0), Color(0xFFF8BBD0), Color(0xFF64B5F6), Color(0xFF64B5F6)],
          stops: [0, 0.55, 0.55, 1],
        ),
      ),
    );
  }
}

/// Draws the table's ink, clipped to the felt. Repaints whenever [ink]
/// changes, without rebuilding anything around it.
class InkLayer extends StatelessWidget {
  const InkLayer({super.key, required this.ink, required this.radius});

  final ValueNotifier<List<InkStroke>> ink;

  /// Corner radius of the felt, so ink stays on the table.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: CustomPaint(painter: _InkPainter(ink, radius), size: Size.infinite));
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.ink, this.radius) : super(repaint: ink);

  final ValueNotifier<List<InkStroke>> ink;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final strokes = ink.value;
    if (strokes.isEmpty) return;
    final bounds = Offset.zero & size;
    canvas.clipRRect(RRect.fromRectAndRadius(bounds, Radius.circular(radius)));
    // A layer of its own, so the eraser clears ink and not the felt beneath
    canvas.saveLayer(bounds, Paint());
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.erase ? const Color(0xFF000000) : Color(stroke.color).withValues(alpha: 0.92)
        ..blendMode = stroke.erase ? BlendMode.clear : BlendMode.srcOver
        ..strokeWidth = stroke.width * size.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final points = [for (final p in stroke.points) Offset(p.dx * size.width, p.dy * size.height)];
      if (points.length == 1) {
        canvas.drawCircle(points.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      // Smooth through the midpoints so fast strokes don't look jagged
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length - 1; i++) {
        final mid = Offset.lerp(points[i], points[i + 1], 0.5)!;
        path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(points.last.dx, points.last.dy);
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InkPainter oldDelegate) => oldDelegate.ink != ink || oldDelegate.radius != radius;
}

/// Size the flashbang is drawn at.
const Size flashbangSize = Size(40, 66);

/// A stun grenade: grey canister, fuse head, spoon and pin ring. [lit] shows
/// the fuse light once the pin is pulled.
class FlashbangGrenade extends StatelessWidget {
  const FlashbangGrenade({super.key, this.lit = false});

  final bool lit;

  @override
  Widget build(BuildContext context) => CustomPaint(size: flashbangSize, painter: _GrenadePainter(lit));
}

class _GrenadePainter extends CustomPainter {
  _GrenadePainter(this.lit);

  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = const Color(0xFF1E2126)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    void shape(Path path, Paint fill) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, outline);
    }

    final metal = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF9EA7AD), Color(0xFF5F6A70), Color(0xFF3E474C)])
          .createShader(const Rect.fromLTWH(6, 20, 28, 44));
    // Canister with grip bands and vent holes
    shape(Path()..addRRect(RRect.fromLTRBR(6, 22, 34, 64, const Radius.circular(5))), metal);
    final band = Paint()..color = const Color(0xFF2E3538);
    canvas.drawRect(const Rect.fromLTWH(6, 30, 28, 3), band);
    canvas.drawRect(const Rect.fromLTWH(6, 54, 28, 3), band);
    for (final y in [39.0, 46.0]) {
      for (final x in [12.0, 20.0, 28.0]) {
        canvas.drawCircle(Offset(x, y), 2, band);
      }
    }
    // Fuse head
    shape(Path()..addRRect(RRect.fromLTRBR(12, 12, 28, 23, const Radius.circular(2))), metal);
    // Spoon running down the side
    shape(
      Path()
        ..moveTo(26, 13)
        ..quadraticBezierTo(38, 14, 37, 26)
        ..lineTo(36, 44)
        ..lineTo(33, 44)
        ..lineTo(34, 26)
        ..quadraticBezierTo(34, 18, 26, 17)
        ..close(),
      Paint()..color = const Color(0xFFB0BEC5),
    );
    if (!lit) {
      // Pin ring
      canvas.drawCircle(
          const Offset(9, 10),
          6,
          Paint()
            ..color = const Color(0xFFCFD8DC)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawLine(const Offset(13, 13), const Offset(15, 16), outline);
    } else {
      // Fuse light
      canvas.drawCircle(const Offset(20, 9), 5, Paint()..color = const Color(0xAAFF5252));
      canvas.drawCircle(const Offset(20, 9), 2.5, Paint()..color = const Color(0xFFFFEBEE));
    }
  }

  @override
  bool shouldRepaint(_GrenadePainter oldDelegate) => oldDelegate.lit != lit;
}
