import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/progression/ranks.dart';
import 'package:donut_game/ui/career/currency.dart';
import 'package:donut_game/ui/career/emblem_editor.dart';
import 'package:donut_game/ui/career/rank_insignia.dart';
import 'package:donut_game/ui/career/shop_tab.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/material.dart';

/// Opens the career screen on [tab] (0 rank, 1 shop, 2 emblem).
Future<void> showCareer(BuildContext context, {int tab = 0}) {
  return Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => CareerScreen(initialTab: tab),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  ));
}

/// Rank, shop and emblem, under one roof.
class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = PlayerProfile.instance;
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        body: Column(
          children: [
            DonutTitleBar(title: 'Career', onBack: () => Navigator.pop(context)),
            ListenableBuilder(listenable: profile, builder: (context, _) => _Header(profile: profile)),
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
              ),
              // Short screens (a phone on its side) get slim, single-line tabs
              child: TabBar(
                tabs: [
                  for (final (icon, label) in const [
                    (Icons.military_tech_rounded, 'Rank'),
                    (Icons.storefront_rounded, 'Shop'),
                    (Icons.brush_rounded, 'Emblem'),
                  ])
                    _isShort(context)
                        ? Tab(
                            height: 44,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(icon, size: 18),
                              const SizedBox(width: 6),
                              Text(label),
                            ]))
                        : Tab(icon: Icon(icon), text: label),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _RankTab(),
                  ShopTab(),
                  EmblemEditor(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether the screen is too short for the roomy header and tabs.
bool _isShort(BuildContext context) => MediaQuery.sizeOf(context).height < 480;

/// Emblem, rank and wallet across the top of every tab. Narrow screens put
/// the wallet on its own row; short ones shrink everything.
class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = profile.nextRank;
    final short = _isShort(context);
    final narrow = MediaQuery.sizeOf(context).width < 560;
    final wallet = Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        AmountChip(amount: profile.crumbs, currency: Currency.crumbs, compact: short || narrow),
        AmountChip(amount: profile.glaze, currency: Currency.glaze, compact: short || narrow),
      ],
    );
    final identity = Row(
      children: [
        EmblemWidget(emblem: profile.emblem, size: short ? 36 : (narrow ? 44 : 56), shadow: true),
        SizedBox(width: short ? 10 : 14),
        RankInsignia(rank: profile.rank, size: short ? 32 : (narrow ? 40 : 48)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.rank.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (short ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: profile.rankProgressValue, minHeight: 6, color: xpColor),
              ),
              const SizedBox(height: 4),
              Text(
                next == null
                    ? '${formatAmount(profile.xp)} XP. Top of the ladder.'
                    : '${formatAmount(profile.xp)} / ${formatAmount(next.xp)} XP to ${next.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
        if (!narrow) ...[const SizedBox(width: 16), wallet],
      ],
    );
    return Container(
      color: theme.colorScheme.surface,
      padding: short
          ? const EdgeInsets.fromLTRB(16, 8, 16, 8)
          : EdgeInsets.fromLTRB(narrow ? 16 : 24, 16, narrow ? 16 : 24, narrow ? 12 : 16),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [identity, const SizedBox(height: 10), wallet],
            )
          : identity,
    );
  }
}

class _RankTab extends StatelessWidget {
  const _RankTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = PlayerProfile.instance;
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) {
        final stats = profile.stats;
        final winRate = stats.matches == 0 ? 0 : (stats.wins * 100 / stats.matches).round();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Column(
                children: [
                  RankInsignia(rank: profile.rank, size: 140),
                  const SizedBox(height: 8),
                  Text(profile.rank.title,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  Text('Rank ${profile.rank.index + 1} of ${ranks.length}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section(theme, 'Career'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Stat('Matches', '${stats.matches}'),
                _Stat('Wins', '${stats.wins}'),
                _Stat('Win rate', '$winRate%'),
                _Stat('Tricks taken', formatAmount(stats.tricks)),
                _Stat('Donuts eaten', '${stats.donuts}'),
                _Stat('Hands played', formatAmount(stats.handsPlayed)),
                _Stat('Bonus spins', '${stats.slotPulls}'),
                _Stat('Jackpots', '${stats.jackpots}'),
              ],
            ),
            const SizedBox(height: 24),
            _section(theme, 'How to earn'),
            Text(
              'Every offline match pays XP and Crumbs: more for winning, taking tricks and dodging donuts. '
              'Each match ends with a bonus spin. Every rank-up pays Crumbs and Glaze, the rare stuff, unlocks more of the shop, and some ranks hand over items the shop doesn\'t sell.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            _section(theme, 'The ladder'),
            for (final rank in ranks)
              _LadderRow(rank: rank, held: rank.index == profile.rank.index, reached: rank.xp <= profile.xp),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _confirmReset(context, profile),
                icon: Icon(Icons.restart_alt_rounded, color: theme.colorScheme.error),
                label: Text('Reset career', style: TextStyle(color: theme.colorScheme.error)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _section(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text.toUpperCase(),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      );

  Future<void> _confirmReset(BuildContext context, PlayerProfile profile) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset your career?'),
        content: const Text('Rank, currencies, unlocks and emblem all go back to the start. There is no undo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (yes == true) profile.reset();
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _LadderRow extends StatelessWidget {
  const _LadderRow({required this.rank, required this.held, required this.reached});

  final Rank rank;
  final bool held;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dim = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final reward = rankReward(rank);
    final item = reward.item == null ? null : itemById(reward.item!);
    final onSale = itemsUnlockedAt(rank).where((item) => !item.rankOnly).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: held ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(10),
        border: held ? Border.all(color: theme.colorScheme.primary) : null,
      ),
      child: Row(
        children: [
          RankInsignia(rank: rank, size: 30, dim: !reached),
          const SizedBox(width: 12),
          Expanded(
            child: Text(rank.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: held ? FontWeight.w800 : FontWeight.w500,
                  color: reached ? null : dim,
                )),
          ),
          if (onSale.isNotEmpty) ...[
            Tooltip(
              message: 'New in the shop: ${onSale.map((item) => item.name).join(', ')}',
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded, size: 16, color: dim),
                  const SizedBox(width: 2),
                  Text('${onSale.length}', style: theme.textTheme.bodySmall?.copyWith(color: dim)),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (item != null) ...[
            Tooltip(
              message: item.name,
              child: SizedBox(width: 56, height: 36, child: FittedBox(child: ItemPreview(item: item))),
            ),
            const SizedBox(width: 6),
          ],
          if (reward.crumbs > 0) AmountChip(amount: reward.crumbs, currency: Currency.crumbs, compact: true),
          if (reward.glaze > 0) ...[
            const SizedBox(width: 4),
            AmountChip(amount: reward.glaze, currency: Currency.glaze, compact: true),
          ],
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text('${formatAmount(rank.xp)} XP',
                textAlign: TextAlign.right, style: theme.textTheme.bodySmall?.copyWith(color: dim)),
          ),
        ],
      ),
    );
  }
}

/// The strip on the home screen: emblem, rank, progress and wallet. Tapping
/// it opens the career screen.
class CareerStrip extends StatelessWidget {
  const CareerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = PlayerProfile.instance;
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) {
        return Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => showCareer(context),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                // Narrow: no emblem, the wallet stacked, the title gives way
                final narrow = constraints.maxWidth < 460;
                final title = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(profile.rank.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: narrow ? double.infinity : 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(value: profile.rankProgressValue, minHeight: 5, color: xpColor),
                      ),
                    ),
                  ],
                );
                final crumbs = AmountChip(amount: profile.crumbs, currency: Currency.crumbs, compact: true);
                final glaze = AmountChip(amount: profile.glaze, currency: Currency.glaze, compact: true);
                final more =
                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.5));
                if (narrow) {
                  return Row(
                    children: [
                      RankInsignia(rank: profile.rank, size: 34),
                      const SizedBox(width: 10),
                      Expanded(child: title),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [crumbs, const SizedBox(height: 4), glaze],
                      ),
                      more,
                    ],
                  );
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EmblemWidget(emblem: profile.emblem, size: 44, shadow: true),
                    const SizedBox(width: 10),
                    RankInsignia(rank: profile.rank, size: 36),
                    const SizedBox(width: 10),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 180), child: title),
                    const SizedBox(width: 14),
                    crumbs,
                    const SizedBox(width: 6),
                    glaze,
                    const SizedBox(width: 6),
                    more,
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
