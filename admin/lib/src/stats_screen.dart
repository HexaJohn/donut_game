import 'package:flutter/material.dart';

import 'model.dart';
import 'widgets.dart';

/// The server's daily counts: players, matches, hands.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.model});

  final AdminModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().toUtc();
    final window = [for (var n = 29; n >= 0; n--) today.subtract(Duration(days: n)).toIso8601String().substring(0, 10)];
    final byDay = {for (final day in model.days) day.day: day};
    DayStats dayOf(String day) => byDay[day] ?? DayStats(day, const {}, const {});
    final finished = model.total('matchesFinished');
    final average = finished == 0 ? '-' : '${(model.total('matchMinutes') / finished).toStringAsFixed(1)} min';
    final shown = model.days.reversed.take(30).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatCard(label: 'Players today', value: '${dayOf(window.last).players.length}', note: 'unique installs'),
            StatCard(label: 'Players, 7 days', value: '${model.playersOver(7)}', note: 'unique installs'),
            StatCard(label: 'Players, 30 days', value: '${model.playersOver(30)}', note: 'unique installs'),
            StatCard(
              label: 'Matches',
              value: '${model.total('matchesStartedParty') + model.total('matchesStartedPublic')}',
              note: 'started, all time',
            ),
            StatCard(label: 'Hands', value: '${model.total('hands')}', note: 'dealt, all time'),
            StatCard(label: 'Average match', value: average, note: '$finished finished'),
            StatCard(label: 'Chat messages', value: '${model.total('chats')}', note: 'all time'),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _Chart(
              title: 'Players per day',
              labels: window,
              series: [for (final d in window) dayOf(d).players.length.toDouble()],
              color: theme.colorScheme.primary,
            ),
            _Chart(
              title: 'Matches per day',
              labels: window,
              series: [for (final d in window) dayOf(d).matches.toDouble()],
              color: theme.colorScheme.tertiary,
            ),
            _Chart(
              title: 'Hands per day',
              labels: window,
              series: [for (final d in window) dayOf(d)['hands'].toDouble()],
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('By day', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          const SizedBox(height: 120, child: EmptyNote('No games recorded yet.'))
        else
          Card(
            margin: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Day (UTC)')),
                  DataColumn(label: Text('Players'), numeric: true),
                  DataColumn(label: Text('Parties'), numeric: true),
                  DataColumn(label: Text('Public tables'), numeric: true),
                  DataColumn(label: Text('Matches'), numeric: true),
                  DataColumn(label: Text('Finished'), numeric: true),
                  DataColumn(label: Text('Hands'), numeric: true),
                  DataColumn(label: Text('Matchmade'), numeric: true),
                  DataColumn(label: Text('Chats'), numeric: true),
                  DataColumn(label: Text('Mid-hand drops'), numeric: true),
                ],
                rows: [
                  for (final day in shown)
                    DataRow(
                      cells: [
                        DataCell(Text(day.day)),
                        for (final value in [
                          day.players.length,
                          day['tablesParty'],
                          day['tablesPublic'],
                          day.matches,
                          day['matchesFinished'],
                          day['hands'],
                          day['joinedByMatchmaking'],
                          day['chats'],
                          day['droppedMidHand'],
                        ])
                          DataCell(Text('$value')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Counts only. Unique players come from hashed install ids the server deletes after 30 days, '
          'so player numbers only reach back that far.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.title, required this.labels, required this.series, required this.color});

  final String title;
  final List<String> labels;
  final List<double> series;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peak = series.fold<double>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      width: 380,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('peak ${peak.toInt()}', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _BarsPainter(series, color, theme.colorScheme.outlineVariant),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(labels.first.substring(5), style: theme.textTheme.labelSmall),
                  const Spacer(),
                  Text(labels.last.substring(5), style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.series, this.color, this.baseline);

  final List<double> series;
  final Color color;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = series.fold<double>(1, (a, b) => a > b ? a : b);
    final slot = size.width / series.length;
    final paint = Paint()..color = color;
    for (var i = 0; i < series.length; i++) {
      final height = series[i] / peak * (size.height - 2);
      if (height <= 0) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * slot + slot * 0.15, size.height - height, slot * 0.7, height),
          const Radius.circular(2),
        ),
        paint,
      );
    }
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), Paint()..color = baseline);
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.series != series || old.color != color;
}
