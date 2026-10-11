import 'package:flutter/material.dart';

import 'model.dart';
import 'widgets.dart';

/// The apps' anonymous gameplay counts ("app.*" in the daily stats), all
/// days added together.
class AppUsageSection extends StatelessWidget {
  const AppUsageSection({super.key, required this.model});

  final AdminModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = <String, int>{};
    for (final day in model.days) {
      for (final MapEntry(:key, :value) in day.counts.entries) {
        if (key.startsWith('app.')) totals[key.substring(4)] = (totals[key.substring(4)] ?? 0) + value;
      }
    }
    if (totals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No gameplay counts from the app yet. They arrive once players run this version.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    int t(String key) => totals[key] ?? 0;
    String percent(int part, int whole) => whole == 0 ? '-' : '${(part * 100 / whole).round()}%';
    final sessions = t('session.count');
    final offline = t('match.quick.finished') + t('match.campaign.finished');
    final online = t('match.party.finished') + t('match.public.finished') + t('match.gamecenter.finished');
    final quickWon = [
      for (final e in totals.entries)
        if (e.key.startsWith('quick.') && e.key.endsWith('.won')) e.value,
    ].fold(0, (a, b) => a + b);
    final quickLost = [
      for (final e in totals.entries)
        if (e.key.startsWith('quick.') && e.key.endsWith('.lost')) e.value,
    ].fold(0, (a, b) => a + b);

    // campaign.<stage id, may contain dots>.<difficulty>.<won|lost>
    final campaign = <String, ({int won, int lost})>{};
    for (final MapEntry(:key, :value) in totals.entries) {
      if (!key.startsWith('campaign.')) continue;
      final parts = key.substring(9).split('.');
      if (parts.length < 3) continue;
      final result = parts.removeLast();
      final difficulty = parts.removeLast();
      final row = '${parts.join('.')} · $difficulty';
      final was = campaign[row] ?? (won: 0, lost: 0);
      campaign[row] = result == 'won' ? (won: was.won + value, lost: was.lost) : (won: was.won, lost: was.lost + value);
    }
    Map<String, int> group(String prefix) => Map.fromEntries(
      (totals.entries
              .where((e) => e.key.startsWith(prefix))
              .map((e) => MapEntry(e.key.substring(prefix.length), e.value)))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatCard(label: 'Sessions', value: '$sessions', note: 'times the app was opened'),
            StatCard(
              label: 'Average session',
              value: sessions == 0 ? '-' : '${(t('session.minutes') / sessions).toStringAsFixed(1)} min',
            ),
            StatCard(label: 'Offline matches', value: '$offline', note: 'vs bots and campaign'),
            StatCard(label: 'Online matches', value: '$online', note: 'party, public, Game Center'),
            StatCard(label: 'Wins vs bots', value: percent(quickWon, quickWon + quickLost), note: 'quick games'),
            StatCard(label: 'Rank-ups', value: '${t('rank.up')}'),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            _CountTable(
              title: 'Campaign (won / lost)',
              rows: {
                for (final e in (campaign.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
                  e.key: '${e.value.won} / ${e.value.lost}  (${percent(e.value.won, e.value.won + e.value.lost)})',
              },
            ),
            _CountTable(
              title: 'Matches started',
              rows: {
                for (final kind in ['quick', 'campaign', 'party', 'public', 'gamecenter'])
                  kind: '${t('match.$kind.started')} (${t('match.$kind.finished')} finished)',
              },
            ),
            _CountTable(title: 'Online entry', rows: group('online.').map((k, v) => MapEntry(k, '$v'))),
            _CountTable(title: 'Gadgets picked up', rows: group('gadget.').map((k, v) => MapEntry(k, '$v'))),
            _CountTable(title: 'Shop purchases', rows: group('shop.').map((k, v) => MapEntry(k, '$v'))),
            _CountTable(
              title: 'Platforms & versions',
              rows: {...group('platform.'), ...group('version.')}.map((k, v) => MapEntry(k, '$v days')),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountTable extends StatelessWidget {
  const _CountTable({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 340,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (rows.isEmpty)
                Text('None yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
              else
                for (final MapEntry(:key, :value) in rows.entries.take(20))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(key, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
