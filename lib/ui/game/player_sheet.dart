import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/ui/game/board.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:flutter/material.dart';

/// Mute, block or report another player at an online table.
Future<void> showPlayerOptions(BuildContext context, GameController controller, GamePlayer player) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([controller.muted, Settings.instance.blocked]),
        builder: (context, _) {
          final settings = Settings.instance;
          final blocked = settings.blocked.value.containsKey(player.id);
          final muted = controller.muted.value.contains(player.id);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: PlayerAvatar(player: player),
                title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const Divider(height: 1),
              if (!blocked)
                ListTile(
                  leading: Icon(muted ? Icons.volume_up_rounded : Icons.volume_off_rounded),
                  title: Text(muted ? tableUnmuteChat() : tableMuteChat()),
                  subtitle: Text(tableThisGameOnly()),
                  onTap: () => controller.setMuted(player, !muted),
                ),
              ListTile(
                leading: Icon(blocked ? Icons.check_circle_outline_rounded : Icons.block_rounded),
                title: Text(blocked ? tableUnblock() : tableBlock()),
                subtitle: Text(blocked ? tableUnblockHint() : tableBlockHint()),
                onTap: () {
                  if (blocked) {
                    settings.unblock(player.id);
                  } else {
                    settings.block(player.id, player.name);
                  }
                  controller.refilterChat();
                },
              ),
              if (controller.canReport)
                ListTile(
                  leading: Icon(Icons.flag_rounded, color: Theme.of(context).colorScheme.error),
                  title: Text(tableReport()),
                  subtitle: Text(tableReportHint()),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await showReportDialog(context, controller, player);
                  },
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    ),
  );
}

const _reasons = {
  'harassment': tableReasonHarassment,
  'hate': tableReasonHate,
  'sexual': tableReasonSexual,
  'name': tableReasonName,
  'cheating': tableReasonCheating,
  'spam': tableReasonSpam,
  'other': tableReasonOther,
};

/// Asks why, then sends the report.
Future<void> showReportDialog(BuildContext context, GameController controller, GamePlayer player) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final note = TextEditingController();
  var reason = 'harassment';
  var sending = false;
  String? problem;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(tableReportTitle.of('name', player.name)),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioGroup<String>(
                  groupValue: reason,
                  onChanged: (value) => setState(() => reason = value ?? reason),
                  child: Column(children: [
                    for (final MapEntry(:key, :value) in _reasons.entries)
                      RadioListTile<String>(
                          value: key, title: Text(value()), dense: true, contentPadding: EdgeInsets.zero),
                  ]),
                ),
                TextField(
                  controller: note,
                  maxLength: 300,
                  maxLines: 2,
                  decoration: InputDecoration(hintText: tableReportNoteHint()),
                ),
                if (problem != null) Text(problem!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tableCancel())),
          FilledButton(
            onPressed: sending
                ? null
                : () async {
                    setState(() => sending = true);
                    final failed = await controller.report(player, reason, note: note.text.trim());
                    if (!context.mounted) return;
                    if (failed == null) {
                      Navigator.of(context).pop();
                      messenger?.showSnackBar(SnackBar(content: Text(tableReportSent())));
                    } else {
                      setState(() {
                        sending = false;
                        problem = failed;
                      });
                    }
                  },
            child: Text(tableSendReport()),
          ),
        ],
      ),
    ),
  );
  note.dispose();
}

/// The players this player blocked, to unblock.
Future<void> showBlockedPlayers(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tableBlockedPlayers()),
      content: SizedBox(
        width: 340,
        child: ValueListenableBuilder(
          valueListenable: Settings.instance.blocked,
          builder: (context, Map<String, String> blocked, _) => blocked.isEmpty
              ? Text(tableNobodyBlocked())
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final MapEntry(key: id, value: name) in blocked.entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.block_rounded),
                        title: Text(name),
                        trailing:
                            TextButton(onPressed: () => Settings.instance.unblock(id), child: Text(tableUnblock())),
                      ),
                  ],
                ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tableDone()))],
    ),
  );
}
