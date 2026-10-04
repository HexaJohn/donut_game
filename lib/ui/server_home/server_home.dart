import 'dart:async';

import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ws_server.dart';
import 'package:flutter/material.dart';

class ServerHome extends StatelessWidget {
  const ServerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donut Server',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(ThemePreset.donutLight),
      home: const ServerGUI(),
    );
  }
}

class ServerGUI extends StatefulWidget {
  const ServerGUI({super.key});

  @override
  State<ServerGUI> createState() => _ServerGUIState();
}

class _ServerGUIState extends State<ServerGUI> {
  late final Timer _refresh;

  @override
  void initState() {
    super.initState();
    // The game runs on its own loop and HTTP handlers; just redraw regularly
    _refresh = Timer.periodic(const Duration(milliseconds: 500), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _refresh.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 360, child: _TablePanel(game: serverGame, onChanged: () => setState(() {}))),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Log', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(),
                        decoration: const InputDecoration(hintText: 'Run Command:', isDense: true),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: serverGame.flipFlop,
                          builder: (context, value, child) {
                            final lines = serverGame.log.keys.toList().reversed.toList();
                            return ListView.builder(
                              itemCount: lines.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(lines[index],
                                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Consolas')),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Who's at the table, with controls to seat and remove bots.
class _TablePanel extends StatelessWidget {
  const _TablePanel({required this.game, required this.onChanged});

  final Game game;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final players = game.players;
    final canChange = game.canChangeBots;
    final full = players.length >= Game.maxPlayers;
    final hasBots = players.any((element) => !element.human);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Table', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${players.length}/${Game.maxPlayers} seats', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _describe(game.state.value),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final player in players)
                    _PlayerRow(
                      player: player,
                      onRemove: !player.human && canChange
                          ? () {
                              game.removeBot(player);
                              onChanged();
                            }
                          : null,
                    ),
                ],
              ),
            ),
            if (!canChange)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Bots can join or leave between hands.',
                    textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canChange && hasBots
                        ? () {
                            game.removeBot();
                            onChanged();
                          }
                        : null,
                    icon: const Icon(Icons.person_remove_rounded),
                    label: const Text('Remove bot'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canChange && !full
                        ? () {
                            game.addBotToTable();
                            onChanged();
                          }
                        : null,
                    icon: const Icon(Icons.smart_toy_rounded),
                    label: const Text('Add bot'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _describe(GameState state) => switch (state) {
        GameState.waitingForPlayers => 'Waiting for players (3 needed)',
        GameState.waitingToDeal => 'In the lobby, waiting for everyone to be ready',
        GameState.gameOver => 'Match over',
        _ => 'Hand in progress',
      };
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, this.onRemove});

  final GamePlayer player;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        child: Icon(player.human ? Icons.person_rounded : Icons.smart_toy_rounded, size: 18),
      ),
      title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${player.human ? 'Player' : 'Bot'} · ${player.score.value} points'
        '${player.human && player.voteToDeal ? ' · ready' : ''}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: onRemove == null
          ? null
          : IconButton(tooltip: 'Remove ${player.name}', icon: const Icon(Icons.close_rounded), onPressed: onRemove),
    );
  }
}
