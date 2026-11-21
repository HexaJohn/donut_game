import 'dart:math';

import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/progression/bonus_cards.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/career/currency.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:flutter/material.dart';

/// Three face-down cards in the player's own card back. Tapping one turns it
/// over; the prizes are decided before the first flip.
class BonusCardsWidget extends StatefulWidget {
  const BonusCardsWidget({super.key, required this.draw, required this.onDone});

  final BonusDraw draw;

  /// Called once every card is face up.
  final VoidCallback onDone;

  @override
  State<BonusCardsWidget> createState() => _BonusCardsWidgetState();
}

class _BonusCardsWidgetState extends State<BonusCardsWidget> with TickerProviderStateMixin {
  static const _flipTime = Duration(milliseconds: 450);

  late final List<AnimationController> _flips = [
    for (var i = 0; i < widget.draw.cards.length; i++) AnimationController(vsync: this, duration: _flipTime),
  ];
  late final AnimationController _total = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  final Set<int> _flipped = {};

  /// Every card is face up and the total is showing.
  bool _done = false;

  @override
  void dispose() {
    for (final flip in _flips) {
      flip.dispose();
    }
    _total.dispose();
    super.dispose();
  }

  void _flip(int i) {
    if (!_flipped.add(i)) return;
    setState(() {});
    SoundEffects.instance.play(Sfx.slide);
    _flips[i].forward().then((_) {
      if (!mounted) return;
      SoundEffects.instance.play(widget.draw.cards[i].rare ? Sfx.yourTurn : Sfx.place, volume: 0.8);
      if (_done || !_flips.every((flip) => flip.isCompleted)) return;
      setState(() => _done = true);
      _total.forward().then((_) => widget.onDone());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draw = widget.draw;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < draw.cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              _FlipCard(
                key: ValueKey('bonus-card-$i'),
                card: draw.cards[i],
                controller: _flips[i],
                onTap: _flipped.contains(i) ? null : () => _flip(i),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        // Room for the total, growing if its chips wrap, so the hint and the
        // total take the same space without clipping either
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: !_done
                ? Text(_flipped.isEmpty ? shopBonusHint() : '',
                    key: const ValueKey('hint'),
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))
                : ScaleTransition(
                    key: const ValueKey('total'),
                    scale: CurvedAnimation(parent: _total, curve: Curves.easeOutBack),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (draw.crumbs > 0) AmountChip(amount: draw.crumbs, currency: Currency.crumbs, prefix: '+'),
                        if (draw.glaze > 0) AmountChip(amount: draw.glaze, currency: Currency.glaze, prefix: '+'),
                        if (draw.xp > 0) AmountChip.xp(amount: draw.xp, prefix: '+'),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({super.key, required this.card, required this.controller, required this.onTap});

  final BonusCard card;
  final AnimationController controller;
  final VoidCallback? onTap;

  static const double _width = 84;
  static const _gold = Color(0xFFE6B422);

  @override
  Widget build(BuildContext context) {
    final height = _width * cardDesignSize.height / cardDesignSize.width;
    return Tooltip(
      message: onTap == null ? '' : shopBonusFlip(),
      child: MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              // Turns about the vertical axis; past halfway the face shows
              final t = Curves.easeInOut.transform(controller.value);
              final faceUp = t >= 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(pi * t + (faceUp ? pi : 0)),
                child: SizedBox(
                  width: _width,
                  height: height,
                  child: faceUp
                      ? _Prize(card: card)
                      : FittedBox(child: SizedBox.fromSize(size: cardDesignSize, child: const CardBack())),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A flipped card: the prize, with a gold edge when it's a rare one.
class _Prize extends StatelessWidget {
  const _Prize({required this.card});

  final BonusCard card;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    final (icon, color) = switch (card.prize) {
      BonusPrize.crumbs => (currencyIcon(Currency.crumbs), crumbsColor),
      BonusPrize.glaze => (currencyIcon(Currency.glaze), glazeColor),
      BonusPrize.xp => (Icons.auto_awesome_rounded, xpColor),
    };
    return Container(
      decoration: BoxDecoration(
        color: colors.cardFace,
        borderRadius: BorderRadius.circular(cardCornerRadius),
        border: Border.all(
          color: card.rare ? _FlipCard._gold : colors.cardEdge,
          width: card.rare ? 2.5 : 1,
        ),
        boxShadow: const [BoxShadow(color: Color(0x38000000), offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.rare)
            Text(shopBonusRare(),
                style: const TextStyle(
                    color: _FlipCard._gold, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11)),
          Icon(icon, size: 34, color: color),
          const SizedBox(height: 8),
          switch (card.prize) {
            BonusPrize.crumbs => AmountChip(amount: card.amount, currency: Currency.crumbs, compact: true, prefix: '+'),
            BonusPrize.glaze => AmountChip(amount: card.amount, currency: Currency.glaze, compact: true, prefix: '+'),
            BonusPrize.xp => AmountChip.xp(amount: card.amount, compact: true, prefix: '+'),
          },
        ],
      ),
    );
  }
}
