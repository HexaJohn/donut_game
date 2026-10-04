import 'package:donut_game/audio/music_player.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/res/rules.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:flutter/material.dart';

const _rules = <(String, List<String>)>[
  (
    'The goal',
    [
      '3 or more players. Everyone starts on $startingScore points.',
      'Every trick you take knocks a point off. First to 0 wins.',
      'Take no tricks in a hand and you get a donut: +$donutPenalty points.',
    ]
  ),
  (
    'Dealing',
    [
      'Everyone gets $cardsPerHand cards. The dealer\'s last card sets the trump suit.',
      'On your turn, swap up to $maxSwaps cards for new ones, or fold.',
      'You can\'t fold if you folded the last $maxConsecutiveFolds hands.',
    ]
  ),
  (
    'Playing',
    [
      'The player after the dealer leads any card.',
      'Everyone else must follow the lead suit if they can.',
      'If you can\'t follow, play anything. A trump beats every other suit.',
      'Highest card of the lead suit (or highest trump) takes the trick and leads next.',
    ]
  ),
  (
    'Sudden death',
    [
      'If several players reach 0 in the same hand, they play on alone.',
      'After each sudden death hand, whoever took the fewest tricks is out.',
      'Last one standing wins.',
    ]
  ),
];

Future<void> showRulesDialog(BuildContext context) {
  final theme = Theme.of(context);
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            Row(
              children: [
                DonutLogo(size: 36, frosting: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('How to play', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            for (final (title, lines) in _rules) ...[
              const SizedBox(height: 20),
              Text(title.toUpperCase(),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7, right: 10),
                        child: Icon(Icons.circle, size: 6, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      Expanded(child: Text(line, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showThemePicker(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ValueListenableBuilder(
            valueListenable: Settings.instance.theme,
            builder: (context, ThemePreset selected, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final preset in ThemePreset.values)
                      _ThemeTile(
                        preset: preset,
                        selected: preset == selected,
                        onTap: () => Settings.instance.setTheme(preset),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.preset, required this.selected, required this.onTap});

  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = preset.colors;
    final onBackground = preset.brightness == Brightness.dark ? Colors.white : Colors.black87;
    Widget miniCard(String text, Color ink) => Container(
          width: 26,
          height: 36,
          decoration: BoxDecoration(
            color: colors.cardFace,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colors.cardEdge),
          ),
          alignment: Alignment.center,
          child: Text(text, style: TextStyle(color: ink, fontSize: 13, fontFamily: 'FluentIcons')),
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 184,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: preset.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? preset.primary : onBackground.withValues(alpha: 0.12),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: colors.felt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.feltEdge, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  miniCard('♠', colors.cardInk),
                  const SizedBox(width: 4),
                  miniCard('♥', colors.cardRed),
                  const SizedBox(width: 4),
                  Container(
                    width: 26,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.cardBack,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.cardBackPattern.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(preset.label,
                      style: TextStyle(color: onBackground, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                if (selected) Icon(Icons.check_circle, size: 16, color: preset.primary),
              ],
            ),
            Text(preset.description, style: TextStyle(color: onBackground.withValues(alpha: 0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

Future<void> showSoundSettings(BuildContext context) {
  final settings = Settings.instance;
  return showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sound', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _VolumeRow(
                  label: 'Music',
                  icon: Icons.music_note_rounded,
                  volume: settings.musicVolume,
                  muted: settings.musicMuted,
                ),
                ValueListenableBuilder(
                  valueListenable: MusicPlayer.instance.nowPlaying,
                  builder: (context, String? track, _) => track == null
                      ? const SizedBox(height: 8)
                      : Padding(
                          padding: const EdgeInsets.only(left: 48, bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.graphic_eq_rounded, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('Now playing: ${MusicPlayer.displayNames[track] ?? track}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                              ),
                              // The menu theme is a single loop, so only games can skip
                              if (MusicPlayer.instance.mode.value == MusicMode.game)
                                TextButton.icon(
                                  onPressed: MusicPlayer.instance.skip,
                                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                                  label: const Text('Next'),
                                ),
                            ],
                          ),
                        ),
                ),
                _VolumeRow(
                  label: 'Effects',
                  icon: Icons.graphic_eq_rounded,
                  volume: settings.sfxVolume,
                  muted: settings.sfxMuted,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(settings.saveAudio);
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.label, required this.icon, required this.volume, required this.muted});

  final String label;
  final IconData icon;
  final ValueNotifier<double> volume;
  final ValueNotifier<bool> muted;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([volume, muted]),
      builder: (context, _) {
        final off = muted.value || volume.value == 0;
        return Row(
          children: [
            IconButton(
              tooltip: muted.value ? 'Unmute $label' : 'Mute $label',
              onPressed: () => muted.value = !muted.value,
              icon: Icon(off ? Icons.volume_off_rounded : icon),
            ),
            SizedBox(width: 64, child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            Expanded(
              child: Slider(
                value: volume.value,
                onChanged: (value) {
                  volume.value = value;
                  if (muted.value && value > 0) muted.value = false;
                },
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(muted.value ? 'Off' : '${(volume.value * 100).round()}%',
                  textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        );
      },
    );
  }
}
