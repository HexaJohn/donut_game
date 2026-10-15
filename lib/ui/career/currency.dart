import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:flutter/material.dart';

/// Colours and icons for the two currencies and XP.
const Color crumbsColor = Color(0xFFC98A3B);
const Color glazeColor = Color(0xFF4FC3F7);
const Color xpColor = Color(0xFF7E57C2);

IconData currencyIcon(Currency currency) => switch (currency) {
      Currency.crumbs => Icons.grain_rounded,
      Currency.glaze => Icons.water_drop_rounded,
    };

Color currencyColor(Currency currency) => switch (currency) {
      Currency.crumbs => crumbsColor,
      Currency.glaze => glazeColor,
    };

/// Formats 12345 as 12,345.
String formatAmount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}$buffer';
}

/// A small pill showing an amount of a currency, or XP.
class AmountChip extends StatelessWidget {
  const AmountChip({super.key, required this.amount, this.currency, this.compact = false, this.prefix = ''});

  const AmountChip.xp({super.key, required this.amount, this.compact = false, this.prefix = ''}) : currency = null;

  final int amount;

  /// Null means XP.
  final Currency? currency;
  final bool compact;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final color = currency == null ? xpColor : currencyColor(currency!);
    final icon = currency == null ? Icons.auto_awesome_rounded : currencyIcon(currency!);
    final label = currency == null ? shopXpSymbol() : currency!.symbol;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 16, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                shopAmount({'prefix': prefix, 'amount': formatAmount(amount), 'unit': label}),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 11.5 : 13,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A price tag on a shop item.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.item, this.affordable = true});

  final ShopItem item;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    final color = currencyColor(item.currency);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(currencyIcon(item.currency), size: 15, color: affordable ? color : color.withValues(alpha: 0.45)),
        const SizedBox(width: 4),
        Text(
          formatAmount(item.price),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: affordable ? null : Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}
