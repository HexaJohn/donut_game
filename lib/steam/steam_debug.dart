import 'package:donut_game/steam/steam.dart';
import 'package:flutter/material.dart';

/// What the game knows about Steam, for checking a Steam build. Opened by
/// long-pressing the version number on the home screen.
Future<void> showSteamDebug(BuildContext context) {
  final steam = SteamService.instance;
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final facts = {
        'Steam': steam.running ? 'Connected' : (steam.problem ?? 'Not connected'),
        if (steam.running) ...{
          'App ID': '${steam.appId}',
          'Player': steam.personaName ?? '-',
          'Steam ID': '${steam.steamId}',
        },
      };
      return AlertDialog(
        title: const Text('Steam'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final MapEntry(:key, :value) in facts.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 80, child: Text(key, style: theme.textTheme.labelLarge)),
                    Expanded(child: SelectableText(value)),
                  ]),
                ),
              const SizedBox(height: 12),
              Text('Activity', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ValueListenableBuilder(
                  valueListenable: steam.log,
                  builder: (context, List<String> lines, _) => lines.isEmpty
                      ? const Text('Nothing yet.')
                      : ListView(
                          reverse: true,
                          children: [
                            for (final line in lines.reversed)
                              Text(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      );
    },
  );
}
