import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/analytics/usage.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/progression/card_patterns.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/environments.dart';
import 'package:donut_game/progression/gadgets.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/progression/ranks.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/career/currency.dart';
import 'package:donut_game/ui/widget/revolver.dart';
import 'package:donut_game/ui/widget/table_tools.dart';
import 'package:flutter/material.dart';

/// Card patterns, environments and gadgets for sale.
class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = PlayerProfile.instance;
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final kind in ItemKind.values) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              // Wraps so the blurb drops under the heading on narrow screens
              child: Wrap(
                spacing: 10,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(kind.label.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                  Text(
                    switch (kind) {
                      ItemKind.cardPattern => shopBlurbPatterns(),
                      ItemKind.cardFace => shopBlurbFaces(),
                      ItemKind.environment => shopBlurbEnvironments(),
                      ItemKind.gadget => shopBlurbGadgets(),
                    },
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in itemsOfKind(kind)..sort((a, b) => a.rank.compareTo(b.rank)))
                  ShopCard(item: item, profile: profile),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}

class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.item, required this.profile});

  final ShopItem item;
  final PlayerProfile profile;

  Future<void> _buy(BuildContext context) async {
    final bought = profile.buy(item);
    if (bought) Usage.instance.count('shop.${item.id}');
    SoundEffects.instance.play(bought ? Sfx.place : Sfx.click);
    if (!bought && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(shopNotEnough({'currency': item.currency.label, 'item': item.name})),
        behavior: SnackBarBehavior.floating,
        width: 360,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final owned = profile.owns(item.id);
    final equipped = profile.isEquipped(item.id);
    final affordable = profile.canAfford(item);
    final unlocked = profile.hasUnlocked(item);

    Widget action;
    if (equipped) {
      action = _Status(icon: Icons.check_circle_rounded, text: shopEquipped());
    } else if (owned && item.kind == ItemKind.gadget) {
      action = _Status(icon: Icons.check_circle_rounded, text: shopOwned());
    } else if (owned) {
      action = OutlinedButton(
        onPressed: () {
          profile.equip(item.id);
          SoundEffects.instance.play(Sfx.slide);
        },
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(36)),
        child: Text(shopEquip()),
      );
    } else if (!unlocked || item.rankOnly) {
      action = _Status(icon: Icons.lock_rounded, text: shopReach.of('rank', unlockRank(item).title));
    } else if (!profile.hasRequirement(item)) {
      action = _Status(icon: Icons.link_rounded, text: shopNeeds.of('item', itemById(item.requires!)?.name));
    } else {
      action = FilledButton.tonal(
        onPressed: affordable ? () => _buy(context) : null,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(36)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(shopBuy()),
              const SizedBox(width: 8),
              PriceTag(item: item, affordable: affordable),
            ],
          ),
        ),
      );
    }

    final card = Container(
      width: 196,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: equipped
              ? theme.colorScheme.primary
              : item.rare
                  ? glazeColor.withValues(alpha: 0.6)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: equipped ? 2 : 1,
        ),
        boxShadow: [
          if (item.rare && !owned) BoxShadow(color: glazeColor.withValues(alpha: 0.2), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 96, child: Center(child: ItemPreview(item: item))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              if (item.rare)
                Tooltip(
                  message: shopRareTooltip(),
                  child: const Icon(Icons.water_drop_rounded, size: 14, color: glazeColor),
                ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 34,
            child: Text(item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          const SizedBox(height: 8),
          action,
        ],
      ),
    );
    return owned || unlocked ? card : Opacity(opacity: 0.6, child: card);
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small picture of what an item is: a card back, a felt swatch or a
/// gadget icon.
class ItemPreview extends StatelessWidget {
  const ItemPreview({super.key, required this.item, this.scale = 1});

  final ShopItem item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    switch (item.kind) {
      case ItemKind.cardPattern:
        return Container(
          width: 60 * scale,
          height: 84 * scale,
          decoration: BoxDecoration(
            color: colors.cardBack,
            borderRadius: BorderRadius.circular(6 * scale),
            border: Border.all(color: colors.cardEdge),
            boxShadow: const [BoxShadow(color: Color(0x38000000), offset: Offset(0, 2))],
          ),
          padding: EdgeInsets.all(4 * scale),
          child: CustomPaint(
            painter: CardBackPainter(id: item.id, pattern: colors.cardBackPattern, back: colors.cardBack),
          ),
        );
      case ItemKind.cardFace:
        // A court card and a pip card, fanned, to show off both layouts
        return SizedBox(
          width: 96 * scale,
          height: 88 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final (i, card) in [GameCard(Suit.clubs, Value.seven), GameCard(Suit.diamonds, Value.queen)].indexed)
                Transform.translate(
                  offset: Offset((i * 2 - 1) * 14 * scale, 0),
                  child: Transform.rotate(
                    angle: (i * 2 - 1) * 0.12,
                    child: SizedBox(
                      width: 60 * scale,
                      height: 84 * scale,
                      child: FittedBox(
                        child: SizedBox.fromSize(size: cardDesignSize, child: CardFace(card: card, style: item.id)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      case ItemKind.environment:
        return EnvironmentSwatch(id: item.id, width: 150 * scale, height: 84 * scale);
      case ItemKind.gadget:
        return _GadgetPreview(id: item.id, scale: scale);
    }
  }
}

class EnvironmentSwatch extends StatelessWidget {
  const EnvironmentSwatch({super.key, required this.id, required this.width, required this.height});

  final String id;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    final env = TableEnvironment.byId(id);
    final felt = env.feltColor(colors);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: env.edgeColor(colors), width: 4),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [Color.lerp(felt, Colors.white, 0.06)!, felt], radius: 1.2),
            ),
          ),
          if (env.texture != null) CustomPaint(painter: env.texture!(felt)),
        ],
      ),
    );
  }
}

class _GadgetPreview extends StatelessWidget {
  const _GadgetPreview({required this.id, required this.scale});

  final String id;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Color>? markers;
    IconData? icon;
    // The tools themselves, drawn as they sit in the tray
    final tool = switch (id) {
      'gadget.revolver' => const Revolver(),
      'gadget.flashbang' => const FlashbangGrenade(),
      _ => null,
    };
    if (tool != null) {
      return SizedBox(
        width: 110 * scale,
        height: 72 * scale,
        child: Transform.rotate(angle: id == 'gadget.revolver' ? -0.2 : 0.3, child: FittedBox(child: tool)),
      );
    }
    switch (id) {
      case 'gadget.markers':
        markers = markerColors;
      case 'gadget.markers_neon':
        markers = neonMarkers;
      case 'gadget.markers_pastel':
        markers = pastelMarkers;
      case 'gadget.marker_gold':
        markers = const [goldMarker];
      case 'gadget.stamp':
        icon = Icons.approval_rounded;
      case 'gadget.confetti':
        icon = Icons.celebration_rounded;
      case 'gadget.speedloader':
        icon = Icons.album_rounded;
    }
    if (markers != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final color in markers)
            Padding(
              padding: EdgeInsets.only(bottom: 3 * scale),
              child: Container(
                width: 110 * scale,
                height: 12 * scale,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4 * scale),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
            ),
        ],
      );
    }
    return Icon(icon, size: 64 * scale, color: theme.colorScheme.primary);
  }
}
