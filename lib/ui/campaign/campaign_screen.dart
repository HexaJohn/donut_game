import 'package:donut_game/ai/bot_brain.dart';
import 'package:donut_game/campaign/backdrops.dart';
import 'package:donut_game/campaign/campaign.dart';
import 'package:donut_game/campaign/campaign_controller.dart';
import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/ui/career/currency.dart';
import 'package:donut_game/ui/career/shop_tab.dart';
import 'package:donut_game/ui/game/board.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/home/routes.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/material.dart';

Future<void> showCampaign(BuildContext context) => Navigator.of(context).push(gameRoute(const CampaignScreen()));

/// The tour: pick a difficulty, then a stage. Each venue opens once the one
/// before is beaten.
class CampaignScreen extends StatelessWidget {
  const CampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = PlayerProfile.instance;
    final maxStars = allStages.length * Difficulty.values.last.stars;
    return Scaffold(
      body: Column(
        children: [
          DonutTitleBar(title: campaignTitle(), onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListenableBuilder(
              listenable: profile,
              builder: (context, _) {
                final difficulty = profile.campaignDifficulty;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(campaignTourTitle(),
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                              Text(
                                campaignTourBlurb(),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.star_rounded, color: _starColor),
                        const SizedBox(width: 4),
                        Text(campaignStarCount({'stars': profile.campaignStars, 'max': maxStars}),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<Difficulty>(
                      segments: [
                        for (final d in Difficulty.values)
                          ButtonSegment(
                            value: d,
                            label: Text(d.label),
                            // Stars only where there's room for them beside the label
                            icon: MediaQuery.sizeOf(context).width < 480
                                ? null
                                : StageStars(stars: d.stars, of: d.stars, size: 14),
                          ),
                      ],
                      showSelectedIcon: false,
                      selected: {difficulty},
                      onSelectionChanged: (value) => profile.campaignDifficulty = value.first,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 20),
                      child: Text(difficulty.blurb,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    ),
                    for (final venue in campaign) ...[
                      _VenueCard(venue: venue, profile: profile, difficulty: difficulty),
                      const SizedBox(height: 20),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const Color _starColor = Color(0xFFFFC233);

/// [stars] filled stars out of [of].
class StageStars extends StatelessWidget {
  const StageStars({super.key, required this.stars, this.of = 3, this.size = 18});

  final int stars;
  final int of;
  final double size;

  @override
  Widget build(BuildContext context) {
    final empty = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < of; i++)
          Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size, color: i < stars ? _starColor : empty),
      ],
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({required this.venue, required this.profile, required this.difficulty});

  final Venue venue;
  final PlayerProfile profile;
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = profile.isStageUnlocked(venue.stages.first);
    final cleared = venue.stages.where((stage) => profile.bestClear(stage) != null).length;
    final table = itemById(venue.environment);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Backdrop(id: venue.backdrop),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 150,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(venue.name,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(venue.blurb,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 16,
                  child: Tooltip(
                    message: campaignPlayedOn.of('table', table?.name ?? campaignHouseFelt()),
                    child: EnvironmentSwatch(id: venue.environment, width: 110, height: 62),
                  ),
                ),
                if (!open)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
                        const SizedBox(height: 6),
                        Text(campaignVenueLocked(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                if (open)
                  Positioned(
                    right: 16,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(campaignVenueCleared({'cleared': cleared, 'total': venue.stages.length}),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final stage in venue.stages) _StageTile(stage: stage, profile: profile, difficulty: difficulty),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage, required this.profile, required this.difficulty});

  final Stage stage;
  final PlayerProfile profile;
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dim = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final unlocked = profile.isStageUnlocked(stage);
    final best = profile.bestClear(stage);
    final reward = stageClearRewards(stage, difficulty, best).firstOrNull;
    final boss = theme.colorScheme.error;

    return Opacity(
      opacity: unlocked ? 1 : 0.5,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: stage.boss ? boss.withValues(alpha: 0.5) : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            width: stage.boss ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(stage.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                if (stage.boss)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: boss, borderRadius: BorderRadius.circular(999)),
                    child: Text(campaignBossBadge(),
                        style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.2)),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                StageStars(stars: best?.stars ?? 0),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(campaignStageTarget.of('target', stage.target),
                      overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: dim)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final opponent in stage.opponents)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    PlayerAvatar(player: opponent.seat(difficulty), size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(opponent.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                    ),
                    _SkillChip(skill: opponent.skill.shifted(difficulty.skillShift)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 26),
              child: reward == null
                  ? Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(campaignClearedOn.of('difficulty', best!.label),
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                        ),
                      ],
                    )
                  : Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        AmountChip.xp(amount: reward.xp, compact: true, prefix: '+'),
                        AmountChip(amount: reward.crumbs, currency: Currency.crumbs, compact: true, prefix: '+'),
                        if (reward.glaze > 0)
                          AmountChip(amount: reward.glaze, currency: Currency.glaze, compact: true, prefix: '+'),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: unlocked
                    ? () => Navigator.of(context).push(
                        gameRoute(GameScreen(controller: CampaignGameController(stage: stage, difficulty: difficulty))))
                    : null,
                icon: Icon(unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded),
                label: Text(unlocked ? (best == null ? campaignPlay() : campaignReplay()) : campaignStageLocked()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill});

  final BotSkill skill;

  @override
  Widget build(BuildContext context) {
    final color = switch (skill) {
      BotSkill.rookie => const Color(0xFF4CAF50),
      BotSkill.regular => const Color(0xFF26A69A),
      BotSkill.amateur => const Color(0xFF2196F3),
      BotSkill.pro => const Color(0xFFFF9800),
      BotSkill.shark => const Color(0xFFE53935),
    };
    return Tooltip(
      message: skill.blurb,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
        child: Text(skill.label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
      ),
    );
  }
}
