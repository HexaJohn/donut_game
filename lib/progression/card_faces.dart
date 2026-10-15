import 'dart:math';

import 'package:donut_game/audit/ai_audit.dart';
import 'package:flutter/material.dart';

/// How the face of a card is drawn, for each face style in the catalog. Ink
/// and paper still come from the theme; a style only changes the layout,
/// type and trim on top.
class CardFaceStyle {
  const CardFaceStyle({
    this.font,
    this.rankWeight = FontWeight.w700,
    this.fourColour = false,
    this.jumbo = false,
    this.frame = false,
    this.paper,
    this.glow = false,
    this.trim,
    this.sprinkles = false,
  });

  /// Font for the ranks; null keeps the theme's.
  final String? font;
  final FontWeight rankWeight;

  /// Clubs green and diamonds blue, so every suit has its own colour.
  final bool fourColour;

  /// Oversized corner indices and a small centre pip.
  final bool jumbo;

  /// A thin inner frame on every card, not just the court cards.
  final bool frame;

  /// Tint blended into the theme's card face.
  final Color? paper;

  /// Ink glows like a neon sign.
  final bool glow;

  /// Colour of a metallic inner border and court-card ink.
  final Color? trim;

  /// Hundreds and thousands scattered round the edge.
  final bool sprinkles;
}

const Color fourColourClubs = Color(0xFF2E8B57);
const Color fourColourDiamonds = Color(0xFF2F6FD6);
const Color gildedTrim = Color(0xFFC9A227);

CardFaceStyle cardFaceStyle(String id) => switch (id) {
      'face.four_colour' => const CardFaceStyle(fourColour: true),
      'face.jumbo' => const CardFaceStyle(jumbo: true, rankWeight: FontWeight.w900),
      'face.parlour' => const CardFaceStyle(font: 'Georgia', frame: true, paper: Color(0xFFF3E6C8)),
      'face.terminal' => const CardFaceStyle(font: 'Courier New', rankWeight: FontWeight.w800, frame: true),
      'face.sprinkle' => const CardFaceStyle(sprinkles: true, rankWeight: FontWeight.w900),
      'face.neon' => const CardFaceStyle(glow: true, rankWeight: FontWeight.w600),
      'face.gilded' => const CardFaceStyle(font: 'Georgia', trim: gildedTrim, paper: Color(0xFFFFF4D6)),
      _ => const CardFaceStyle(),
    };

/// Sprinkles in a band round the edge of a card, the same on every card of
/// the deck.
class SprinkleEdgePainter extends CustomPainter with AiArt {
  const SprinkleEdgePainter();

  static const _colours = [
    Color(0xFFE85D9A),
    Color(0xFF4FC3F7),
    Color(0xFFFFD54F),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    // A fixed scatter, so the deck doesn't shimmer between repaints
    var seed = 7;
    double next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    const band = 9.0;
    for (var i = 0; i < 46; i++) {
      final along = next();
      final depth = 2.5 + next() * (band - 5);
      final side = i % 4;
      final p = switch (side) {
        0 => Offset(along * size.width, depth),
        1 => Offset(size.width - depth, along * size.height),
        2 => Offset(along * size.width, size.height - depth),
        _ => Offset(depth, along * size.height),
      };
      final angle = next() * pi;
      final d = Offset(2.2 * cos(angle), 2.2 * sin(angle));
      paint.color = _colours[i % _colours.length];
      canvas.drawLine(p - d, p + d, paint);
    }
  }

  @override
  bool shouldRepaint(SprinkleEdgePainter oldDelegate) => false;
}
