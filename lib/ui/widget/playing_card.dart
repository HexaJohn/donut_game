import 'dart:math';

import 'package:donut_game/audit/ai_audit.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/progression/card_faces.dart';
import 'package:donut_game/progression/card_patterns.dart';
import 'package:donut_game/progression/profile.dart';
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

/// Corner radius at the design size.
const double cardCornerRadius = 9;

/// The corner radius of a card drawn [width] wide, for anything outlining it.
double cardRadiusFor(double width) => cardCornerRadius * width / cardDesignSize.width;

class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget(
      {super.key, required this.card, this.faceUp = true, this.trump = false, this.back, this.face});

  final GameCard card;
  final bool faceUp;

  /// Shows a small trump marker on the face.
  final bool trump;

  /// Catalog ids of the deck it comes from; null uses the equipped ones.
  final String? back;
  final String? face;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox.fromSize(
        size: cardDesignSize,
        child: faceUp
            ? CardFace(card: card, trump: trump, style: face ?? PlayerProfile.instance.cardFace)
            : CardBack(pattern: back),
      ),
    );
  }
}

BoxDecoration _cardDecoration(DonutColors colors, Color fill) {
  return BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(cardCornerRadius),
    border: Border.all(color: colors.cardEdge, width: colors.glow ? 1.5 : 1),
    // Sharp offset shadow: a blur here would run for every card, every frame
    boxShadow: const [BoxShadow(color: Color(0x38000000), offset: Offset(0, 2))],
  );
}

/// The face of [card], drawn in the face style [style] from the catalog.
class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card, this.trump = false, this.style = 'face.classic'});

  final GameCard card;
  final bool trump;
  final String style;

  @override
  Widget build(BuildContext context) => AiMarked(name: 'card face ($style)', child: _face(context));

  Widget _face(BuildContext context) {
    final colors = DonutColors.of(context);
    final look = cardFaceStyle(style);
    final isFace = card.value == Value.jack || card.value == Value.queen || card.value == Value.king;
    var ink = switch (card.suit) {
      Suit.clubs when look.fourColour => fourColourClubs,
      Suit.diamonds when look.fourColour => fourColourDiamonds,
      _ => isRed(card.suit) ? colors.cardRed : colors.cardInk,
    };
    if (isFace && look.trim != null) ink = Color.lerp(ink, look.trim, 0.55)!;
    final paper = look.paper == null ? colors.cardFace : Color.lerp(colors.cardFace, look.paper, 0.6)!;
    final rank = _rank[card.value]!;
    final glow = look.glow
        ? [Shadow(color: ink, blurRadius: 6), Shadow(color: ink.withValues(alpha: 0.6), blurRadius: 12)]
        : null;
    final rankStyle = TextStyle(
        color: ink, fontWeight: look.rankWeight, height: 1, letterSpacing: -0.5, fontFamily: look.font, shadows: glow);

    Widget suit(double size) {
      final icon = SuitIcon(card.suit, size: size, color: ink);
      if (!look.glow) return icon;
      // A soft halo behind the pip
      return Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: ink.withValues(alpha: 0.45), blurRadius: size * 0.6)]),
        child: icon,
      );
    }

    Widget corner() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rank, style: rankStyle.copyWith(fontSize: look.jumbo ? 30 : 19)),
            const SizedBox(height: 1),
            suit(look.jumbo ? 18 : 14),
          ],
        );

    Widget centre;
    if (isFace) {
      centre = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rank,
              style: rankStyle.copyWith(
                  fontSize: look.jumbo ? 30 : 40, fontWeight: FontWeight.w800, fontFamily: look.font ?? 'Georgia')),
          const SizedBox(height: 3),
          suit(20),
        ],
      );
    } else {
      final size = card.value == Value.ace ? 52.0 : 40.0;
      centre = suit(look.jumbo ? size * 0.6 : size);
    }

    final framed = isFace || look.frame;
    final edge = look.trim ?? ink;
    return Container(
      decoration: _cardDecoration(colors, paper),
      child: Stack(
        children: [
          if (look.sprinkles) const Positioned.fill(child: CustomPaint(painter: SprinkleEdgePainter())),
          if (look.trim != null)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: look.trim!, width: 1.5),
                ),
              ),
            ),
          if (framed)
            Positioned.fill(
              child: Container(
                margin:
                    look.jumbo ? const EdgeInsets.fromLTRB(30, 20, 30, 20) : const EdgeInsets.fromLTRB(22, 14, 22, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: edge.withValues(alpha: look.trim != null ? 0.7 : 0.25)),
                  color: isFace ? ink.withValues(alpha: 0.04) : null,
                  boxShadow: look.glow ? [BoxShadow(color: ink.withValues(alpha: 0.35), blurRadius: 6)] : null,
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

/// The back of a card, in the pattern the player has equipped (or [pattern]
/// if given), drawn in the theme's card-back colours.
class CardBack extends StatelessWidget {
  const CardBack({super.key, this.pattern});

  /// A catalog pattern id; null uses the equipped one.
  final String? pattern;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    return Container(
      decoration: _cardDecoration(colors, colors.cardBack),
      padding: const EdgeInsets.all(6),
      child: CustomPaint(
        painter: CardBackPainter(
          id: pattern ?? PlayerProfile.instance.cardPattern,
          pattern: colors.cardBackPattern,
          back: colors.cardBack,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
