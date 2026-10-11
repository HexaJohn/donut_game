import 'package:flutter/material.dart';

import 'model.dart';
import 'widgets.dart';

const reasonLabels = {
  'harassment': 'Harassment',
  'hate': 'Hate speech',
  'sexual': 'Sexual content',
  'name': 'Offensive name',
  'cheating': 'Cheating',
  'spam': 'Spam',
  'other': 'Other',
};

/// Players' reports, newest first, with the chat around them; and the
/// players currently banned.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.model});

  final AdminModel model;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selected;
  bool _busy = false;

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final theme = Theme.of(context);
    final selected = model.reports.where((report) => report.key == _selected).firstOrNull;
    final bans = model.bans.where((ban) => ban.active).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 400,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Open reports (${model.reports.length})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (model.reports.isEmpty)
                const SizedBox(height: 120, child: EmptyNote('No reports.', icon: Icons.verified_user_rounded)),
              for (final report in model.reports)
                ListTile(
                  selected: report.key == _selected,
                  leading: Icon(Icons.flag_rounded, color: theme.colorScheme.error),
                  title: Text('${report.reportedName} · ${reasonLabels[report.reason] ?? report.reason}'),
                  subtitle: Text('by ${report.reporterName} at ${report.code} · ${ago(report.time)}'),
                  onTap: () => setState(() => _selected = report.key),
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Banned (${bans.length})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (bans.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Nobody.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ),
              for (final ban in bans)
                ListTile(
                  leading: const Icon(Icons.block_rounded),
                  title: Text(ban.name),
                  subtitle: Text(
                    '${reasonLabels[ban.reason] ?? ban.reason} · '
                    '${ban.until == null ? 'for good' : 'until ${ban.until!.toLocal().toString().substring(0, 16)}'}',
                  ),
                  trailing: TextButton(
                    onPressed: _busy ? null : () => _act(() => model.unban(ban)),
                    child: const Text('Unban'),
                  ),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? const EmptyNote('Pick a report to review it.', icon: Icons.flag_outlined)
              : _ReportDetail(
                  report: selected,
                  busy: _busy,
                  onDismiss: () => _act(() async {
                    await model.dismiss(selected);
                    setState(() => _selected = null);
                  }),
                  onBan: (length) => _act(() async {
                    await model.ban(selected, length);
                    setState(() => _selected = null);
                  }),
                ),
        ),
      ],
    );
  }
}

class _ReportDetail extends StatelessWidget {
  const _ReportDetail({required this.report, required this.busy, required this.onDismiss, required this.onBan});

  final Report report;
  final bool busy;
  final VoidCallback onDismiss;
  final void Function(Duration? length) onBan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${report.reportedName}: ${reasonLabels[report.reason] ?? report.reason}',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Reported by ${report.reporterName} at ${report.public ? 'public table' : 'party'} ${report.code}, '
          '${report.time.toLocal().toString().substring(0, 16)}',
        ),
        if (report.note != null) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(padding: const EdgeInsets.all(12), child: Text('"${report.note}"')),
          ),
        ],
        const SizedBox(height: 20),
        Text('Chat before the report', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: report.chat.isEmpty
                ? Text('Nobody said anything.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in report.chat)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${line['author']}: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: line['author'] == report.reportedName ? theme.colorScheme.error : null,
                                  ),
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
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : onDismiss,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Dismiss'),
            ),
            FilledButton.tonal(
              onPressed: busy ? null : () => onBan(const Duration(days: 1)),
              child: const Text('Ban 1 day'),
            ),
            FilledButton.tonal(
              onPressed: busy ? null : () => onBan(const Duration(days: 7)),
              child: const Text('Ban 7 days'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
              onPressed: busy ? null : () => onBan(null),
              child: const Text('Ban for good'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'A ban keeps this install out of online play; offline play is unaffected. Reports are deleted after 30 days.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
