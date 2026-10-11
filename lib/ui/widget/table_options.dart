import 'package:donut_game/ai/bot_brain.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/res/rules.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:flutter/material.dart';

/// Bot difficulty and starting points, as chips.
class TableOptionsPicker extends StatelessWidget {
  const TableOptionsPicker(
      {super.key, required this.skill, required this.target, required this.onSkill, required this.onTarget});

  final BotSkill skill;
  final int target;
  final ValueChanged<BotSkill> onSkill;
  final ValueChanged<int> onTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Bot difficulty', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final option in BotSkill.values)
            ChoiceChip(
              label: Text(option.label),
              selected: option == skill,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onSkill(option),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(skill.blurb, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ),
        const SizedBox(height: 12),
        Text('Starting points', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final points in startingScoreChoices)
            ChoiceChip(
              label: Text('$points'),
              selected: points == target,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              // Snug, so all six fit on one line on a phone
              padding: const EdgeInsets.symmetric(horizontal: 2),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              onSelected: (_) => onTarget(points),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Everyone counts down from here. Fewer points, shorter match.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ),
      ],
    );
  }
}

/// The party host's table settings: bot difficulty and starting points.
Future<void> showTableSettings(BuildContext context, GameController controller) {
  final settings = Settings.instance;
  var skill = controller.tableBotSkill ?? settings.botSkill;
  var target = controller.game.targetScore;
  return showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Table settings'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: TableOptionsPicker(
              skill: skill,
              target: target,
              onSkill: (value) => setState(() => skill = value),
              onTarget: (value) => setState(() => target = value),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              controller.changeTable(skill: skill, target: target);
              // Remembered for the next table this player opens
              settings
                ..botSkill = skill
                ..startingPoints = target
                ..save();
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    ),
  );
}
