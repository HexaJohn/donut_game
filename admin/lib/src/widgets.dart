import 'package:donut_engine/donut_engine.dart';
import 'package:flutter/material.dart';

import 'model.dart';

/// "12s ago", "4m ago", "2h ago".
String ago(DateTime time) {
  final gap = DateTime.now().difference(time);
  if (gap.inSeconds < 60) return '${gap.inSeconds.clamp(0, 59)}s ago';
  if (gap.inMinutes < 60) return '${gap.inMinutes}m ago';
  if (gap.inHours < 48) return '${gap.inHours}h ago';
  return '${gap.inDays}d ago';
}

/// What a table is doing, in words.
String statusOf(TableState table) => switch (table.status) {
  GameState.waitingToDeal ||
  GameState.waiting => table.handNumber == 0 ? 'In the lobby' : 'Between hands (${table.handNumber} played)',
  GameState.waitingForPlayers => 'Waiting for players',
  GameState.dealing => 'Dealing hand ${table.handNumber}',
  GameState.swapping ||
  GameState.waitingToSwap ||
  GameState.waitingForPlayerToSwap => 'Swapping, hand ${table.handNumber}',
  GameState.playing ||
  GameState.waitingForPlayer ||
  GameState.waitingForNextRound => 'Playing hand ${table.handNumber}',
  GameState.gameOver => 'Match over',
};

/// The top of every screen: title, when it last refreshed, and refresh.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.model, required this.title});

  final AdminModel model;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
          child: Row(
            children: [
              Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (model.updated != null) Text('Updated ${ago(model.updated!)}', style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh now',
                onPressed: model.loading ? null : () => model.refresh(stats: true),
                icon: model.loading
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        if (model.error != null)
          Container(
            width: double.infinity,
            color: theme.colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(model.error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

/// A number with a label, for the tops of screens.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              if (note != null)
                Text(note!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A player's initial on their emblem colour (a bot gets a robot).
class SeatAvatar extends StatelessWidget {
  const SeatAvatar({super.key, required this.seat, this.size = 32});

  final Seat seat;
  final double size;

  @override
  Widget build(BuildContext context) {
    final emblem = seat.emblem;
    final background = emblem?['bg'] is int
        ? Color(emblem!['bg'] as int)
        : HSLColor.fromAHSL(1, (seat.name.hashCode % 360).toDouble(), 0.5, 0.5).toColor();
    final foreground = emblem?['fg'] is int ? Color(emblem!['fg'] as int) : Colors.white;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: seat.human ? background : Colors.blueGrey,
          child: seat.human
              ? Text(
                  seat.name.isEmpty ? '?' : seat.name.characters.first.toUpperCase(),
                  style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: size * 0.42),
                )
              : Icon(Icons.smart_toy_rounded, color: Colors.white, size: size * 0.55),
        ),
        if (seat.human)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: seat.connected ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Public" or "Party", as a small chip.
class KindChip extends StatelessWidget {
  const KindChip({super.key, required this.table});

  final TableState table;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final public = table.public;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: public ? scheme.tertiaryContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        public ? 'Public' : 'Party',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: public ? scheme.onTertiaryContainer : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Shown when a list is empty.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key, this.icon = Icons.hourglass_empty_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: muted),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: muted)),
        ],
      ),
    );
  }
}
