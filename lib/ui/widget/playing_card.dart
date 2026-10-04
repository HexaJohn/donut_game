import 'dart:math';

import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/widget/suit_icon.dart';
import 'package:flutter/material.dart';

const Map<Suit, String> suitSymbol = {
  Suit.spades: '♠',
  Suit.hearts: '♥',
  Suit.diamonds: '♦',
  Suit.clubs: '♣',
};

const Map<Value, String> _rank = {
  Value.two: '2',
  Value.three: '3',
  Value.four: '4',
  Value.five: '5',
  Value.six: '6',
  Value.seven: '7',
  Value.eight: '8',
  Value.nine: '9',
  Value.ten: '10',
  Value.jack: 'J',
  Value.queen: 'Q',
  Value.king: 'K',
  Value.ace: 'A',
};

/// Bundled Segoe UI Symbol, so suit glyphs never fall back to colour emoji.
const String suitFont = 'FluentIcons';

bool isRed(Suit suit) => suit == Suit.hearts || suit == Suit.diamonds;

/// Designed at 100x140 and scaled to whatever size it is given.
const Size cardDesignSize = Size(100, 140);

class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({super.key, required this.card, this.faceUp = true, this.trump = false});

  final GameCard card;
  final bool faceUp;

  /// Shows a small trump marker on the face.
  final bool trump;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox.fromSize(
        size: cardDesignSize,
        child: faceUp ? _CardFace(card: card, trump: trump) : const CardBack(),
      ),
    );
  }
}

BoxDecoration _cardDecoration(DonutColors colors, Color fill) {
  return BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(9),
    border: Border.all(color: colors.cardEdge, width: colors.glow ? 1.5 : 1),
    // Sharp offset shadow: a blur here would run for every card, every frame
    boxShadow: const [BoxShadow(color: Color(0x38000000), offset: Offset(0, 2))],
  );
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card, required this.trump});

  final GameCard card;
  final bool trump;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    final ink = isRed(card.suit) ? colors.cardRed : colors.cardInk;
    final rank = _rank[card.value]!;
    final isFace = card.value == Value.jack || card.value == Value.queen || card.value == Value.king;

    Widget corner() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rank,
                style:
                    TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w700, height: 1, letterSpacing: -0.5)),
            const SizedBox(height: 1),
            SuitIcon(card.suit, size: 14, color: ink),
          ],
        );

    Widget centre;
    if (isFace) {
      centre = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rank,
              style:
                  TextStyle(color: ink, fontSize: 40, fontWeight: FontWeight.w800, height: 1, fontFamily: 'Georgia')),
          const SizedBox(height: 3),
          SuitIcon(card.suit, size: 20, color: ink),
        ],
      );
    } else {
      centre = SuitIcon(card.suit, size: card.value == Value.ace ? 52 : 40, color: ink);
    }

    return Container(
      decoration: _cardDecoration(colors, colors.cardFace),
      child: Stack(
        children: [
          if (isFace)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: ink.withValues(alpha: 0.25)),
                  color: ink.withValues(alpha: 0.04),
                ),
              ),
            ),
          Center(child: centre),
          Positioned(left: 6, top: 6, child: corner()),
          Positioned(right: 6, bottom: 6, child: Transform.rotate(angle: pi, child: corner())),
          if (trump)
            Positioned(
              right: 5,
              top: 5,
              child: Tooltip(
                message: 'Trump',
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                  child: Icon(Icons.star_rounded, size: 13, color: colors.cardFace),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CardBack extends StatelessWidget {
  const CardBack({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    return Container(
      decoration: _cardDecoration(colors, colors.cardBack),
      padding: const EdgeInsets.all(6),
      child: CustomPaint(
        painter: _BackPatternPainter(colors.cardBackPattern),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BackPatternPainter extends CustomPainter {
  _BackPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final lines = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    const step = 9.0;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lines);
      canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), lines);
    }
    // Little donut in the middle
    final c = size.center(Offset.zero);
    canvas.drawCircle(
        c,
        11.5,
        Paint()
          ..color = color.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11);
  }

  @override
  bool shouldRepaint(_BackPatternPainter oldDelegate) => oldDelegate.color != color;
}
