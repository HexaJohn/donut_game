import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/res/rules.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/tutorial/tutorial_controller.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/home/routes.dart';
import 'package:donut_game/ui/widget/dialogs.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:flutter/material.dart';

/// Opens the tutorial: a practice hand against two bots.
Future<void> startTutorial(BuildContext context) {
  PlayerProfile.instance.markTutorialSeen();
  return Navigator.of(context).push(gameRoute(GameScreen(controller: TutorialController())));
}

/// For a first-time player: offers the tutorial, or lets them skip it.
Future<void> offerTutorial(BuildContext context) async {
  PlayerProfile.instance.markTutorialSeen();
  final play = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DonutLogo(size: 88),
                const SizedBox(height: 16),
                Text(dialogsTutorialWelcome(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(dialogsTutorialInvite(),
                    textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
                const SizedBox(height: 20),
                Row(children: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(dialogsTutorialSkip())),
                  const Spacer(),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(dialogsTutorialStart())),
                ]),
              ],
            ),
          ),
        ),
      );
    },
  );
  if (play == true && context.mounted) await startTutorial(context);
}

/// The tutorial's coaching, under the table.
class TutorialCoachBar extends StatelessWidget {
  const TutorialCoachBar({super.key, required this.controller});

  final TutorialController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    return ValueListenableBuilder(
      valueListenable: controller.coach,
      builder: (context, String? line, _) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: line == null
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                color: theme.colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.school_rounded, size: 22, color: colors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        line,
                        style:
                            theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Over the table once the practice hand is played: how it went, and on to
/// a real match.
class TutorialDonePanel extends StatelessWidget {
  const TutorialDonePanel({super.key, required this.controller});

  final TutorialController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = controller.game;
    final local = controller.localPlayer;
    final lines = [
      if (local.donuts.value > 0)
        dialogsTutorialDonut.of('points', donutPenalty)
      else if (local.matchTricks > 0)
        dialogsTutorialTricks({'n': local.matchTricks, 'total': cardsPerHand}),
      for (final player in game.players)
        if (player != local && player.donuts.value > 0)
          dialogsTutorialBotDonut({'name': player.name, 'points': donutPenalty}),
      dialogsTutorialNextUp.of('points', startingScore),
    ];
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DonutLogo(size: 72),
                    const SizedBox(height: 12),
                    Text(dialogsTutorialDone(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    for (final line in lines) ...[
                      const SizedBox(height: 10),
                      Text(line, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(onPressed: () => showRulesDialog(context), child: Text(dialogsTutorialFullRules())),
                        OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(dialogsTutorialMenu())),
                        FilledButton(
                          onPressed: () {
                            final settings = Settings.instance;
                            Navigator.of(context).pushReplacement(gameRoute(GameScreen(
                                controller: OfflineGameController(
                                    nickname: settings.nickname, bots: settings.bots, skill: settings.botSkill))));
                          },
                          child: Text(dialogsTutorialPlayBots()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
