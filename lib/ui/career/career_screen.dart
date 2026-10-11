import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/progression/battle_pass.dart';
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

/// Opens the career screen on [tab] (0 rank, 1 pass, 2 shop, 3 emblem).
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

/// Rank, battle pass, shop and emblem, under one roof.
class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = PlayerProfile.instance;
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Scaffold(
        body: Column(
          children: [
            DonutTitleBar(
              title: 'Career',
              trailing: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            ListenableBuilder(listenable: profile, builder: (context, _) => _Header(profile: profile)),
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
              ),
              child: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.military_tech_rounded), text: 'Rank'),
                  Tab(icon: Icon(Icons.confirmation_num_rounded), text: 'Battle pass'),
                  Tab(icon: Icon(Icons.storefront_rounded), text: 'Shop'),
                  Tab(icon: Icon(Icons.brush_rounded), text: 'Emblem'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _RankTab(),
                  _PassTab(),
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

/// Emblem, rank and wallet across the top of every tab.
class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = profile.nextRank;
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          EmblemWidget(emblem: profile.emblem, size: 56, shadow: true),
          const SizedBox(width: 14),
          RankInsignia(rank: profile.rank, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.rank.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              AmountChip(amount: profile.crumbs, currency: Currency.crumbs),
              AmountChip(amount: profile.glaze, currency: Currency.glaze),
            ],
          ),
        ],
      ),
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
                      style:
                          theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
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
                _Stat('Bad Batch games', '${stats.badBatchGames}'),
                _Stat('Bad Batch wins', '${stats.badBatchWins}'),
                _Stat('Bonus spins', '${stats.slotPulls}'),
                _Stat('Jackpots', '${stats.jackpots}'),
              ],
            ),
            const SizedBox(height: 24),
            _section(theme, 'How to earn'),
            Text(
              'Every offline match pays XP and Crumbs: more for winning, taking tricks and dodging donuts. '
              'Each match ends with a bonus spin. Ranking up pays Glaze, the rare stuff, and so does the battle pass.',
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
          Text('${formatAmount(rank.xp)} XP', style: theme.textTheme.bodySmall?.copyWith(color: dim)),
        ],
      ),
    );
  }
}

class _PassTab extends StatelessWidget {
  const _PassTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = PlayerProfile.instance;
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) {
        final tier = profile.passTier;
        final ready = profile.unclaimedTiers.length;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(passName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        'Free for everyone. Every bit of XP you earn moves it along; claim each tier when it unlocks.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('Tier $tier of $passTierCount',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                  value: passProgress(profile.xp), minHeight: 8, color: theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tier >= passTierCount
                                ? 'Complete'
                                : '${formatAmount(passTiers[tier].xp - profile.xp)} XP to next',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                FilledButton.icon(
                  onPressed: ready == 0
                      ? null
                      : () {
                          profile.claimAll();
                          SoundEffects.instance.play(Sfx.yourMove);
                        },
                  icon: const Icon(Icons.redeem_rounded),
                  label: Text(ready == 0 ? 'Nothing to claim' : 'Claim $ready'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final t in passTiers) _TierCard(tier: t, profile: profile)],
            ),
          ],
        );
      },
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.profile});

  final PassTier tier;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = tier.tier <= profile.passTier;
    final claimed = profile.isClaimed(tier.tier);
    final ready = unlocked && !claimed;
    final item = tier.item == null ? null : itemById(tier.item!);
    final milestone = item != null;

    return Opacity(
      opacity: unlocked ? 1 : 0.6,
      child: Container(
        width: milestone ? 196 : 132,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ready
                ? theme.colorScheme.primary
                : claimed
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.15),
            width: ready ? 2 : 1,
          ),
          boxShadow: [if (ready) BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 14)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('TIER ${tier.tier}',
                    style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (claimed)
                  Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary)
                else if (!unlocked)
                  Icon(Icons.lock_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: milestone ? 96 : 56,
              child: Center(
                child: item != null
                    ? ItemPreview(item: item, scale: item.kind == ItemKind.environment ? 0.95 : 1)
                    : tier.glaze > 0
                        ? const Icon(Icons.water_drop_rounded, size: 40, color: glazeColor)
                        : const Icon(Icons.grain_rounded, size: 40, color: crumbsColor),
              ),
            ),
            const SizedBox(height: 8),
            if (item != null)
              Text(item.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (tier.crumbs > 0) AmountChip(amount: tier.crumbs, currency: Currency.crumbs, compact: true),
                if (tier.glaze > 0) AmountChip(amount: tier.glaze, currency: Currency.glaze, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            if (ready)
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(32), padding: EdgeInsets.zero),
                onPressed: () {
                  profile.claimTier(tier.tier);
                  SoundEffects.instance.play(Sfx.place);
                },
                child: const Text('Claim'),
              )
            else
              Text(
                claimed ? 'Claimed' : '${formatAmount(tier.xp)} XP',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              ),
          ],
        ),
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
        final ready = profile.unclaimedTiers.length;
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmblemWidget(emblem: profile.emblem, size: 44, shadow: true),
                  const SizedBox(width: 10),
                  RankInsignia(rank: profile.rank, size: 36),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(profile.rank.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 150,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(value: profile.rankProgressValue, minHeight: 5, color: xpColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  AmountChip(amount: profile.crumbs, currency: Currency.crumbs, compact: true),
                  const SizedBox(width: 6),
                  AmountChip(amount: profile.glaze, currency: Currency.glaze, compact: true),
                  if (ready > 0) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: '$ready battle pass ${ready == 1 ? 'tier' : 'tiers'} to claim',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                        child: Text('$ready',
                            style: TextStyle(
                                color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
