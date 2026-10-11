import 'dart:math';

import 'package:flutter/material.dart';

/// A player's emblem: a shape, an icon on it, and three colours.
@immutable
class Emblem {
  const Emblem({
    this.shape = EmblemShape.circle,
    this.icon = 'donut',
    this.background = const Color(0xFFE0457B),
    this.foreground = const Color(0xFFFFFFFF),
    this.accent = const Color(0xFFFFD54F),
    this.ring = true,
  });

  final EmblemShape shape;

  /// Key into [emblemIcons].
  final String icon;
  final Color background;
  final Color foreground;

  /// Ring and shape details.
  final Color accent;

  /// Whether the accent ring around the edge is drawn.
  final bool ring;

  Emblem copyWith({
    EmblemShape? shape,
    String? icon,
    Color? background,
    Color? foreground,
    Color? accent,
    bool? ring,
  }) {
    return Emblem(
      shape: shape ?? this.shape,
      icon: icon ?? this.icon,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      accent: accent ?? this.accent,
      ring: ring ?? this.ring,
    );
  }

  Map<String, dynamic> toJson() => {
        'shape': shape.name,
        'icon': icon,
        'bg': background.toARGB32(),
        'fg': foreground.toARGB32(),
        'accent': accent.toARGB32(),
        'ring': ring,
      };

  factory Emblem.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Emblem();
    const fallback = Emblem();
    return Emblem(
      shape: EmblemShape.values.firstWhere((s) => s.name == json['shape'], orElse: () => fallback.shape),
      icon: emblemIcons.containsKey(json['icon']) ? json['icon'] : fallback.icon,
      background: Color(json['bg'] ?? fallback.background.toARGB32()),
      foreground: Color(json['fg'] ?? fallback.foreground.toARGB32()),
      accent: Color(json['accent'] ?? fallback.accent.toARGB32()),
      ring: json['ring'] ?? fallback.ring,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Emblem &&
      other.shape == shape &&
      other.icon == icon &&
      other.background == background &&
      other.foreground == foreground &&
      other.accent == accent &&
      other.ring == ring;

  @override
  int get hashCode => Object.hash(shape, icon, background, foreground, accent, ring);
}

enum EmblemShape { circle, shield, hexagon, diamond, square, badge, star, heart }

extension EmblemShapeInfo on EmblemShape {
  String get label => switch (this) {
        EmblemShape.circle => 'Circle',
        EmblemShape.shield => 'Shield',
        EmblemShape.hexagon => 'Hexagon',
        EmblemShape.diamond => 'Diamond',
        EmblemShape.square => 'Square',
        EmblemShape.badge => 'Badge',
        EmblemShape.star => 'Star',
        EmblemShape.heart => 'Heart',
      };
}

/// Every icon an emblem can carry. Keys are stored in the profile, so they
/// must not be renamed.
const Map<String, IconData> emblemIcons = {
  'donut': Icons.donut_large_rounded,
  'spade': Icons.spa_rounded,
  'heart': Icons.favorite_rounded,
  'diamond': Icons.diamond_rounded,
  'club': Icons.filter_vintage_rounded,
  'star': Icons.star_rounded,
  'bolt': Icons.bolt_rounded,
  'skull': Icons.sentiment_very_dissatisfied_rounded,
  'crown': Icons.workspace_premium_rounded,
  'flame': Icons.local_fire_department_rounded,
  'moon': Icons.nightlight_round,
  'sun': Icons.wb_sunny_rounded,
  'coffee': Icons.coffee_rounded,
  'cake': Icons.cake_rounded,
  'cookie': Icons.cookie_rounded,
  'pizza': Icons.local_pizza_rounded,
  'icecream': Icons.icecream_rounded,
  'bakery': Icons.bakery_dining_rounded,
  'anchor': Icons.anchor_rounded,
  'rocket': Icons.rocket_launch_rounded,
  'paw': Icons.pets_rounded,
  'bug': Icons.bug_report_rounded,
  'leaf': Icons.eco_rounded,
  'snow': Icons.ac_unit_rounded,
  'wave': Icons.waves_rounded,
  'eye': Icons.visibility_rounded,
  'ghost': Icons.mood_rounded,
  'robot': Icons.smart_toy_rounded,
  'dice': Icons.casino_rounded,
  'target': Icons.gps_fixed_rounded,
  'shield': Icons.shield_rounded,
  'sword': Icons.colorize_rounded,
  'music': Icons.music_note_rounded,
  'headphones': Icons.headphones_rounded,
  'camera': Icons.photo_camera_rounded,
  'palette': Icons.palette_rounded,
  'bomb': Icons.circle_rounded,
  'key': Icons.key_rounded,
  'lock': Icons.lock_rounded,
  'infinity': Icons.all_inclusive_rounded,
  'hashtag': Icons.tag_rounded,
  'question': Icons.question_mark_rounded,
  'exclaim': Icons.priority_high_rounded,
  'peace': Icons.back_hand_rounded,
  'thumbs': Icons.thumb_up_rounded,
  'bike': Icons.pedal_bike_rounded,
  'car': Icons.directions_car_rounded,
  'plane': Icons.flight_rounded,
  'tree': Icons.park_rounded,
  'mountain': Icons.terrain_rounded,
};

/// The whole palette, free for everyone: 12 hues in 5 tones, plus greys.
final List<Color> emblemPalette = () {
  final colors = <Color>[];
  for (final light in [0.82, 0.68, 0.52, 0.38, 0.26]) {
    for (var hue = 0; hue < 360; hue += 30) {
      colors.add(HSLColor.fromAHSL(1, hue.toDouble(), 0.78, light).toColor());
    }
  }
  for (final light in [1.0, 0.9, 0.78, 0.62, 0.48, 0.35, 0.22, 0.12, 0.0]) {
    colors.add(HSLColor.fromAHSL(1, 0, 0, light).toColor());
  }
  return colors;
}();

/// Draws an [Emblem] at [size].
class EmblemWidget extends StatelessWidget {
  const EmblemWidget({super.key, required this.emblem, required this.size, this.shadow = false});

  final Emblem emblem;
  final double size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: EmblemPainter(emblem, shadow: shadow),
        child: Center(
          child: Icon(emblemIcons[emblem.icon] ?? Icons.donut_large_rounded,
              size: size * 0.5, color: emblem.foreground),
        ),
      ),
    );
  }
}

class EmblemPainter extends CustomPainter {
  EmblemPainter(this.emblem, {this.shadow = false});

  final Emblem emblem;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = emblemPath(emblem.shape, size);
    if (shadow) {
      canvas.drawPath(
        path.shift(Offset(0, size.height * 0.04)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.04),
      );
    }
    canvas.drawPath(path, Paint()..color = emblem.background);
    // Soft highlight across the top
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );
    canvas.restore();
    if (emblem.ring) {
      canvas.drawPath(
        path,
        Paint()
          ..color = emblem.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, size.width * 0.07)
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(EmblemPainter oldDelegate) => oldDelegate.emblem != emblem || oldDelegate.shadow != shadow;
}

/// The outline of [shape] filling [size], inset a little so strokes fit.
Path emblemPath(EmblemShape shape, Size size) {
  final inset = size.width * 0.05;
  final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
  final c = rect.center;
  final r = rect.width / 2;
  switch (shape) {
    case EmblemShape.circle:
      return Path()..addOval(rect);
    case EmblemShape.square:
      return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.28)));
    case EmblemShape.diamond:
      return Path()
        ..moveTo(c.dx, rect.top)
        ..lineTo(rect.right, c.dy)
        ..lineTo(c.dx, rect.bottom)
        ..lineTo(rect.left, c.dy)
        ..close();
    case EmblemShape.hexagon:
      return _polygon(c, r, 6, rotation: pi / 6);
    case EmblemShape.shield:
      return Path()
        ..moveTo(rect.left, rect.top + r * 0.15)
        ..quadraticBezierTo(c.dx, rect.top - r * 0.1, rect.right, rect.top + r * 0.15)
        ..lineTo(rect.right, c.dy)
        ..quadraticBezierTo(rect.right, rect.bottom - r * 0.3, c.dx, rect.bottom)
        ..quadraticBezierTo(rect.left, rect.bottom - r * 0.3, rect.left, c.dy)
        ..close();
    case EmblemShape.badge:
      // A seal: scalloped edge
      final path = Path();
      const points = 12;
      for (var i = 0; i < points * 2; i++) {
        final radius = i.isEven ? r : r * 0.86;
        final angle = -pi / 2 + i * pi / points;
        final p = Offset(c.dx + cos(angle) * radius, c.dy + sin(angle) * radius);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      return path..close();
    case EmblemShape.star:
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final radius = i.isEven ? r : r * 0.55;
        final angle = -pi / 2 + i * pi / 5;
        final p = Offset(c.dx + cos(angle) * radius, c.dy + sin(angle) * radius);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      return path..close();
    case EmblemShape.heart:
      final w = rect.width;
      final h = rect.height;
      return Path()
        ..moveTo(rect.left + w * 0.5, rect.bottom)
        ..cubicTo(rect.left + w * 0.18, rect.top + h * 0.7, rect.left + w * 0.02, rect.top + h * 0.52,
            rect.left + w * 0.04, rect.top + h * 0.32)
        ..cubicTo(rect.left + w * 0.06, rect.top + h * 0.1, rect.left + w * 0.3, rect.top, rect.left + w * 0.5,
            rect.top + h * 0.22)
        ..cubicTo(rect.left + w * 0.7, rect.top, rect.left + w * 0.94, rect.top + h * 0.1, rect.left + w * 0.96,
            rect.top + h * 0.32)
        ..cubicTo(rect.left + w * 0.98, rect.top + h * 0.52, rect.left + w * 0.82, rect.top + h * 0.7,
            rect.left + w * 0.5, rect.bottom)
        ..close();
  }
}

Path _polygon(Offset c, double r, int sides, {double rotation = 0}) {
  final path = Path();
  for (var i = 0; i < sides; i++) {
    final angle = rotation + i * 2 * pi / sides;
    final p = Offset(c.dx + cos(angle) * r, c.dy + sin(angle) * r);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}
