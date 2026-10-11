import 'dart:math';

import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/progression/ranks.dart';
import 'package:donut_game/progression/rewards.dart';
import 'package:donut_game/progression/slot_machine.dart';
import 'package:donut_game/ui/career/currency.dart';
import 'package:donut_game/ui/career/rank_insignia.dart';
import 'package:donut_game/ui/career/slot_machine_widget.dart';
import 'package:flutter/material.dart';

/// Everything one finished match paid, already banked in the profile. The
/// post-match screen replays it: the bar fills from [xpBefore], the slots
/// land on [slot].
class MatchOutcome {
  MatchOutcome._({
    required this.rewards,
    required this.slot,
    required this.xpBefore,
    required this.rankUps,
    required this.slotRankUps,
  });

  final MatchRewards rewards;
  final SlotResult slot;
  final int xpBefore;

  /// Ranks reached by the match rewards, and then by the bonus spin.
  final List<Rank> rankUps;
  final List<Rank> slotRankUps;

  int get xpAfter => xpBefore + rewards.xp;
  Rank get rankBefore => rankFor(xpBefore);
  Rank get rankAfter => rankFor(xpAfter);
  bool get rankedUp => rankAfter.index > rankBefore.index;

  /// Crumbs and Glaze paid for the rank-ups during the match rewards.
  int get rankUpCrumbs => rankUps.fold(0, (sum, rank) => sum + rankReward(rank).crumbs);
  int get rankUpGlaze => rankUps.fold(0, (sum, rank) => sum + rankReward(rank).glaze);

  /// Items handed over by any rank reached, the bonus spin included.
  List<ShopItem> get unlockedItems => [
        for (final rank in [...rankUps, ...slotRankUps])
          if (rankReward(rank).item case final id?) itemById(id)!,
      ];

  /// Shop items that went on sale with any rank reached.
  List<ShopItem> get newInShop => [
        for (final rank in [...rankUps, ...slotRankUps]) ...itemsUnlockedAt(rank).where((item) => !item.rankOnly),
      ];

  /// Banks a finished offline Donut match and rolls the slots.
  /// [extra] lines, such as a campaign stage clear, are paid on top.
  static MatchOutcome awardDonut(PlayerProfile profile, DonutMatchSummary match,
      {Random? random, List<RewardLine> extra = const []}) {
    final rewards = MatchRewards([...donutMatchRewards(match).lines, ...extra]);
    return _bank(profile, rewards, random, () => profile.recordDonutMatch(match, rewards));
  }

  /// Banks a finished offline Bad Batch game and rolls the slots.
  static MatchOutcome awardBadBatch(PlayerProfile profile, BadBatchSummary game, {Random? random}) {
    final rewards = badBatchRewards(game);
    return _bank(profile, rewards, random, () => profile.recordBadBatch(game, rewards));
  }

  static MatchOutcome _bank(PlayerProfile profile, MatchRewards rewards, Random? random, List<Rank> Function() record) {
    final xpBefore = profile.xp;
    final rankUps = record();
    final slot = rollSlots(random ?? Random());
    final slotRankUps = profile.recordSlots(slot);
    return MatchOutcome._(
      rewards: rewards,
      slot: slot,
      xpBefore: xpBefore,
      rankUps: rankUps,
      slotRankUps: slotRankUps,
    );
  }
}

enum _Phase { standings, rewards, slots }

/// The post-match panel: standings first, then the rewards tally with the
/// rank bar filling, then the slot machine. With no [outcome] (online games)
/// it's just the standings and [actions].
class MatchOverFlow extends StatefulWidget {
  const MatchOverFlow({
    super.key,
    required this.header,
    required this.standings,
    required this.actions,
    this.outcome,
  });

  /// Logo and headline.
  final Widget header;
  final Widget standings;

  /// Main menu / play again, shown at the end.
  final Widget actions;
  final MatchOutcome? outcome;

  @override
  State<MatchOverFlow> createState() => _MatchOverFlowState();
}

class _MatchOverFlowState extends State<MatchOverFlow> {
  _Phase _phase = _Phase.standings;
  bool _slotsDone = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcome = widget.outcome;
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: switch (_phase) {
          _Phase.standings => Column(
              key: const ValueKey('standings'),
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.header,
                const SizedBox(height: 20),
                widget.standings,
                const SizedBox(height: 20),
                if (outcome == null)
                  widget.actions
                else
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () => setState(() => _phase = _Phase.rewards),
                    icon: const Icon(Icons.redeem_rounded),
                    label: const Text('Collect rewards', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          _Phase.rewards => Column(
              key: const ValueKey('rewards'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Match rewards', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _RewardsTally(outcome: outcome!),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () => setState(() => _phase = _Phase.slots),
                  icon: const Icon(Icons.casino_rounded),
                  label: const Text('Bonus spin', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          _Phase.slots => Column(
              key: const ValueKey('slots'),
              mainAxisSize: MainAxisSize.min,
              children: [
                SlotMachineWidget(
                  result: outcome!.slot,
                  onDone: () {
                    if (mounted) setState(() => _slotsDone = true);
                  },
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: _slotsDone ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(ignoring: !_slotsDone, child: widget.actions),
                ),
              ],
            ),
        },
      ),
    );
  }
}

/// Reward lines dropping in one by one, then the rank bar filling.
class _RewardsTally extends StatefulWidget {
  const _RewardsTally({required this.outcome});

  final MatchOutcome outcome;

  @override
  State<_RewardsTally> createState() => _RewardsTallyState();
}

class _RewardsTallyState extends State<_RewardsTally> with SingleTickerProviderStateMixin {
  static const _lineDelay = Duration(milliseconds: 180);

  late final AnimationController _bar = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  int _shown = 0;
  bool _rankUpShown = false;

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  Future<void> _reveal() async {
    final lines = widget.outcome.rewards.lines;
    for (var i = 0; i < lines.length; i++) {
      await Future.delayed(_lineDelay);
      if (!mounted) return;
      SoundEffects.instance.play(Sfx.slide, volume: 0.5);
      setState(() => _shown = i + 1);
    }
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _bar.addListener(_checkRankUp);
    await _bar.forward();
  }

  void _checkRankUp() {
    if (_rankUpShown || !widget.outcome.rankedUp) return;
    // The moment the bar crosses the old rank's ceiling
    final o = widget.outcome;
    final next = nextRankFor(o.xpBefore)!;
    final crossAt = (next.xp - o.xpBefore) / (o.xpAfter - o.xpBefore);
    if (_bar.value >= crossAt.clamp(0.0, 1.0)) {
      _rankUpShown = true;
      SoundEffects.instance.play(Sfx.yourMove);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = widget.outcome;
    final lines = o.rewards.lines;
    final dim = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++)
          AnimatedOpacity(
            opacity: i < _shown ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: AnimatedSlide(
              offset: i < _shown ? Offset.zero : const Offset(0, 0.3),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(lines[i].label, style: theme.textTheme.bodyMedium)),
                    if (lines[i].crumbs > 0) ...[
                      AmountChip(amount: lines[i].crumbs, currency: Currency.crumbs, compact: true, prefix: '+'),
                      const SizedBox(width: 6),
                    ],
                    if (lines[i].glaze > 0) ...[
                      AmountChip(amount: lines[i].glaze, currency: Currency.glaze, compact: true, prefix: '+'),
                      const SizedBox(width: 6),
                    ],
                    AmountChip.xp(amount: lines[i].xp, compact: true, prefix: '+'),
                  ],
                ),
              ),
            ),
          ),
        if (o.rankUps.isNotEmpty)
          AnimatedOpacity(
            opacity: _rankUpShown ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Rank up: ${o.rankUps.last.title}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (o.rankUpCrumbs > 0) ...[
                    AmountChip(amount: o.rankUpCrumbs, currency: Currency.crumbs, compact: true, prefix: '+'),
                    const SizedBox(width: 6),
                  ],
                  if (o.rankUpGlaze > 0)
                    AmountChip(amount: o.rankUpGlaze, currency: Currency.glaze, compact: true, prefix: '+'),
                ],
              ),
            ),
          ),
        const Divider(height: 24),
        Row(
          children: [
            Text('Total', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 12),
            // Everything banked, rank-ups included; wraps rather than overflowing
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 6,
                children: [
                  AmountChip(amount: o.rewards.crumbs + o.rankUpCrumbs, currency: Currency.crumbs, prefix: '+'),
                  if (o.rewards.glaze + o.rankUpGlaze > 0)
                    AmountChip(amount: o.rewards.glaze + o.rankUpGlaze, currency: Currency.glaze, prefix: '+'),
                  AmountChip.xp(amount: o.rewards.xp, prefix: '+'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _bar,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_bar.value);
            final xp = (o.xpBefore + (o.xpAfter - o.xpBefore) * t).round();
            final rank = rankFor(xp);
            final next = nextRankFor(xp);
            final progress = rankProgress(xp);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    RankInsignia(rank: rank, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(rank.title,
                                key: ValueKey(rank.index),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          ),
                          Text(
                            next == null
                                ? 'Top rank'
                                : '${formatAmount(xp)} / ${formatAmount(next.xp)} XP to ${next.title}',
                            style: theme.textTheme.bodySmall?.copyWith(color: dim),
                          ),
                        ],
                      ),
                    ),
                    if (_rankUpShown)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('RANK UP',
                            style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: progress, minHeight: 10, color: xpColor),
                ),
              ],
            );
          },
        ),
        for (final item in o.unlockedItems) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.lock_open_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.name} unlocked. ${item.kind == ItemKind.gadget ? 'It\'s on your tool tray.' : 'Equip it from the shop.'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
        if (o.newInShop.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New in the shop: ${o.newInShop.map((item) => item.name).join(', ')}.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
