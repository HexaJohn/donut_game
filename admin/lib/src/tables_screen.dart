import 'package:donut_engine/donut_engine.dart';
import 'package:flutter/material.dart';

import 'model.dart';
import 'widgets.dart';

/// Every table the server holds (they're forgotten a day after their last
/// move), with the selected one in detail.
class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key, required this.model, required this.selected, required this.onSelect});

  final AdminModel model;
  final String? selected;
  final void Function(String code) onSelect;

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  bool _liveOnly = true;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final tables = _liveOnly ? model.activeTables : model.tables;
    final selected = model.tables.where((table) => table.code == widget.selected).firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 440,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text('Live (${model.activeTables.length})')),
                    ButtonSegment(value: false, label: Text('All today (${model.tables.length})')),
                  ],
                  selected: {_liveOnly},
                  onSelectionChanged: (value) => setState(() => _liveOnly = value.single),
                ),
              ),
              Expanded(
                child: tables.isEmpty
                    ? EmptyNote(_liveOnly ? 'No live tables.' : 'No tables in the last day.')
                    : ListView.builder(
                        itemCount: tables.length,
                        itemBuilder: (context, i) {
                          final table = tables[i];
                          final state = table.state;
                          final bots = state.seats.length - table.humans.length;
                          return ListTile(
                            selected: table.code == widget.selected,
                            title: Row(
                              children: [
                                Text(
                                  table.code,
                                  style: const TextStyle(fontFamily: 'Menlo', fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                KindChip(table: state),
                                const Spacer(),
                                Text(ago(table.modified), style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            subtitle: Text(
                              '${statusOf(state)}\n'
                              '${table.online.length}/${table.humans.length} people online'
                              '${bots > 0 ? ' · $bots bot${bots == 1 ? '' : 's'}' : ''}'
                              ' · host ${state.host?.name ?? '-'}',
                            ),
                            isThreeLine: true,
                            onTap: () => widget.onSelect(table.code),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? const EmptyNote('Pick a table to see who\'s there.', icon: Icons.table_restaurant_rounded)
              : TableDetail(table: selected),
        ),
      ],
    );
  }
}

/// One table: its players, where the game is, and its recent chat.
class TableDetail extends StatelessWidget {
  const TableDetail({super.key, required this.table});

  final LiveTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = table.state;
    String time(int? ms) => ms == null ? '-' : ago(DateTime.fromMillisecondsSinceEpoch(ms));
    final facts = {
      'Status': statusOf(state),
      'Host': state.host?.name ?? '-',
      'Target score': '${state.target}',
      'Trump': state.handNumber == 0 ? '-' : suitToString[state.trump] ?? '-',
      'Created': time(state.createdAt),
      'Last move': time(state.updatedAt),
      'Match started': time(state.matchStartedAt),
      if (state.champion != null) 'Champion': state.championName ?? state.seat(state.champion!)?.name ?? '-',
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Text(
              state.code,
              style: theme.textTheme.headlineMedium?.copyWith(fontFamily: 'Menlo', fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            KindChip(table: state),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 28,
          runSpacing: 10,
          children: [
            for (final MapEntry(:key, :value) in facts.entries)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(key, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text(value, style: theme.textTheme.bodyLarge),
                ],
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Seats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final seat in state.seats)
                ListTile(
                  leading: SeatAvatar(seat: seat),
                  title: Text('${seat.name}${seat.id == state.hostId ? '  (host)' : ''}${seat.human ? '' : '  (bot)'}'),
                  subtitle: Text(
                    [
                      if (seat.human) seat.connected ? 'Connected' : 'Away, a bot is playing for them',
                      if (seat.skip) 'Folded',
                      if (state.handNumber > 0 && state.phase != Phase.lobby) '${seat.hand.length} cards',
                    ].join(' · '),
                  ),
                  trailing: Text(
                    '${seat.score}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Chat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (state.chat.isEmpty)
          Text('Nothing yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
        else
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in state.chat.reversed.take(40).toList().reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: line['system'] == true
                          ? Text(
                              '${line['text']}',
                              style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
                            )
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${line['author']}: ',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: '${line['text']}'),
                                ],
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
