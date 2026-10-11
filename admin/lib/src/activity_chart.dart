import 'package:flutter/material.dart';

import 'model.dart';

/// Recent activity in 15-minute windows: pick how far back and what to show.
class ActivityChart extends StatefulWidget {
  const ActivityChart({super.key, required this.model});

  final AdminModel model;

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
  static const _ranges = {'6 hours': Duration(hours: 6), '24 hours': Duration(hours: 24), '7 days': Duration(days: 7)};
  static final _metrics = <String, int Function(QuarterStats)>{
    'Players': (q) => q.players,
    'Matches': (q) =>
        q['matchesStartedParty'] +
        q['matchesStartedPublic'] +
        q['app.match.quick.started'] +
        q['app.match.campaign.started'],
    'Hands': (q) => q['hands'],
    'Launches': (q) => q['app.launch'],
    'Chats': (q) => q['chats'],
    'Reports': (q) => q['reports'],
  };
  String _metric = 'Players';
  bool _average = true;

  /// How many windows the average line spans, by range: an hour over 6
  /// hours, two over a day, a whole day over a week.
  static int _span(Duration range) => range.inDays >= 7 ? 96 : (range.inHours > 6 ? 8 : 4);

  static String _spanLabel(int windows) => '${windows * 15 ~/ 60}-hour';

  /// Each point is the mean of it and the windows just before it (fewer at
  /// the very start, where there aren't enough yet).
  static List<double> _rolling(List<int> values, int span) {
    final out = <double>[];
    var sum = 0;
    for (var i = 0; i < values.length; i++) {
      sum += values[i];
      if (i >= span) sum -= values[i - span];
      out.add(sum / (i < span ? i + 1 : span));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = widget.model;
    final range = model.activityRange;
    // Every window in the range, empty ones included, so gaps show as gaps
    final now = DateTime.now().toUtc();
    final end = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute ~/ 15 * 15);
    final count = range.inMinutes ~/ 15;
    final byStart = {for (final q in model.quarters) q.start: q};
    final starts = [for (var i = count - 1; i >= 0; i--) end.subtract(Duration(minutes: 15 * i))];
    final read = _metrics[_metric]!;
    final values = [for (final start in starts) byStart[start] == null ? 0 : read(byStart[start]!)];
    final peak = values.fold(0, (a, b) => a > b ? a : b);
    final total = values.fold(0, (a, b) => a + b);
    String clock(DateTime t) {
      final local = t.toLocal();
      final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      return range.inHours > 24 ? '${local.month}/${local.day} $time' : time;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Recent activity', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                SegmentedButton<Duration>(
                  segments: [
                    for (final MapEntry(:key, :value) in _ranges.entries) ButtonSegment(value: value, label: Text(key)),
                  ],
                  selected: {range},
                  onSelectionChanged: (value) => model.showActivity(value.single),
                ),
                FilterChip(
                  label: Text('${_spanLabel(_span(range))} average'),
                  selected: _average,
                  visualDensity: VisualDensity.compact,
                  onSelected: (on) => setState(() => _average = on),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final metric in _metrics.keys)
                      ChoiceChip(
                        label: Text(metric),
                        selected: metric == _metric,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setState(() => _metric = metric),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$_metric per 15 minutes · peak $peak'
              '${_metric == 'Players' ? '' : ' · $total in all'}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LayoutBuilder(
                builder: (context, constraints) => MouseRegion(
                  child: Tooltip(
                    message: 'Bars are 15-minute windows, local time',
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 160),
                      painter: _WindowBars(
                        values,
                        theme.colorScheme.primary.withValues(alpha: _average ? 0.55 : 1),
                        theme.colorScheme.outlineVariant,
                        average: _average ? _rolling(values, _span(range)) : null,
                        averageColor: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(clock(starts.first), style: theme.textTheme.labelSmall),
                const Spacer(),
                Text(clock(starts[starts.length ~/ 2]), style: theme.textTheme.labelSmall),
                const Spacer(),
                Text('now', style: theme.textTheme.labelSmall),
              ],
            ),
            if (model.quarters.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '15-minute history starts from when the server began keeping it.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WindowBars extends CustomPainter {
  _WindowBars(this.values, this.color, this.baseline, {this.average, required this.averageColor});

  /// The rolling average, drawn as a line over the bars.
  final List<double>? average;
  final Color averageColor;

  final List<int> values;
  final Color color;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final peak = values.fold<int>(1, (a, b) => a > b ? a : b);
    final slot = size.width / values.length;
    final paint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final height = values[i] / peak * (size.height - 2);
      final width = slot > 3 ? slot * 0.8 : slot;
      canvas.drawRect(Rect.fromLTWH(i * slot + (slot - width) / 2, size.height - height, width, height), paint);
    }
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), Paint()..color = baseline);
    final line = average;
    if (line != null) {
      final path = Path();
      for (var i = 0; i < line.length; i++) {
        final point = Offset(i * slot + slot / 2, size.height - line[i] / peak * (size.height - 2));
        i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = averageColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_WindowBars old) =>
      old.values != values || old.color != color || old.average != average || old.averageColor != averageColor;
}
