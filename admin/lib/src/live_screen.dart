import 'package:flutter/material.dart';

import 'model.dart';
import 'widgets.dart';

/// Who's connected right now, and where.
class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key, required this.model, required this.onOpenTable});

  final AdminModel model;
  final void Function(String code) onOpenTable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final live = model.activeTables;
    final online = [
      for (final table in live)
        for (final seat in table.online) (seat, table),
    ]..sort((a, b) => a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase()));
    final inPublic = online.where((entry) => entry.$2.state.public).length;
    final playing = online.where((entry) => entry.$2.state.handNumber > 0).length;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatCard(label: 'Online now', value: '${online.length}', note: 'people at live tables'),
            StatCard(label: 'Playing', value: '$playing', note: 'in a match'),
            StatCard(label: 'Live tables', value: '${live.length}', note: 'moved in the last 15 min'),
            StatCard(label: 'In public games', value: '$inPublic', note: 'matchmade'),
            StatCard(label: 'Open connections', value: '${model.openConnections}', note: 'sockets to the server'),
          ],
        ),
        const SizedBox(height: 24),
        Text('People online', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (online.isEmpty)
          const SizedBox(height: 200, child: EmptyNote('Nobody\'s online right now.', icon: Icons.nights_stay_rounded))
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (seat, table) in online)
                  ListTile(
                    leading: SeatAvatar(seat: seat),
                    title: Text(seat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${statusOf(table.state)} · score ${seat.score}'
                      '${table.state.hostId == seat.id ? ' · host' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KindChip(table: table.state),
                        const SizedBox(width: 10),
                        Text(
                          table.code,
                          style: const TextStyle(fontFamily: 'Menlo', fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 64,
                          child: Text(ago(table.modified), textAlign: TextAlign.end, style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                    onTap: () => onOpenTable(table.code),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
