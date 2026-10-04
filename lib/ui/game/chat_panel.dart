import 'package:donut_game/data/model/chat_message.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _quickReactions = ['\u{1F44D}', '\u{1F602}', '\u{1F631}', '\u{1F369}', 'GG', 'Nice one!'];

class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    required this.chat,
    required this.localName,
    required this.onSend,
    required this.open,
    required this.onClose,
  });

  /// The table's messages; shared by every game mode.
  final ValueListenable<List<ChatMessage>> chat;

  /// Your name, so your own messages sit on the right.
  final String? localName;
  final Future<void> Function(String text) onSend;
  final bool open;
  final VoidCallback onClose;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final message = (text ?? _input.text).trim();
    if (message.isEmpty) return;
    widget.onSend(message);
    if (text == null) _input.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: widget.open ? 320 : 0,
      decoration: BoxDecoration(
        color: colors.chrome,
        border: Border(left: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
      ),
      clipBehavior: Clip.hardEdge,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 320,
        maxWidth: 320,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Row(
                children: [
                  Text('Table talk', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(tooltip: 'Close', onPressed: widget.onClose, icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: widget.chat,
                builder: (context, List<ChatMessage> messages, _) => ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return _MessageTile(
                      message: message,
                      mine: !message.system && message.author == widget.localName,
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final reaction in _quickReactions)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(reaction, style: const TextStyle(fontSize: 13)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _send(reaction),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: TextField(
                controller: _input,
                focusNode: _focus,
                maxLength: 280,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Say something...',
                  counterText: '',
                  isDense: true,
                  suffixIcon: IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    if (message.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    final bubble = mine ? colors.accent : theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final ink = mine
        ? (ThemeData.estimateBrightnessForColor(colors.accent) == Brightness.dark ? Colors.white : Colors.black)
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(message.author,
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.accent)),
            ),
          Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bubble,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(mine ? 14 : 4),
                bottomRight: Radius.circular(mine ? 4 : 14),
              ),
            ),
            child: Text(message.text, style: theme.textTheme.bodyMedium?.copyWith(color: ink)),
          ),
        ],
      ),
    );
  }
}
