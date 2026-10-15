import 'package:donut_copy/donut_copy.dart';
import 'dart:async';

import 'package:donut_game/audit/ai_audit.dart';
import 'package:donut_game/audit/ai_inventory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _textColor = Color(0xFF00E5FF);
const _artColor = Color(0xFFFF2BD6);
const _soundColor = Color(0xFFFF9100);

/// Wraps the app: with the AI audit on, outlines every piece of text (cyan)
/// and every piece of AI art (magenta, labelled) on screen, and shows the
/// sounds and music playing (orange). Finds them in the render tree, so
/// nothing needs tagging but the game's own painters.
class AiAuditOverlay extends StatefulWidget {
  const AiAuditOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<AiAuditOverlay> createState() => _AiAuditOverlayState();
}

class _Mark {
  const _Mark(this.rect, this.art, this.label);

  final Rect rect;
  final bool art;
  final String? label;
}

class _AiAuditOverlayState extends State<AiAuditOverlay> {
  final _app = GlobalKey();
  Timer? _timer;
  List<_Mark> _marks = const [];

  AiAudit get _audit => AiAudit.instance;

  @override
  void initState() {
    super.initState();
    _audit.enabled.addListener(_toggle);
    _toggle();
  }

  @override
  void dispose() {
    _audit.enabled.removeListener(_toggle);
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    _timer?.cancel();
    if (_audit.enabled.value) {
      // Often enough to follow cards about; it's a developer tool
      _timer = Timer.periodic(const Duration(milliseconds: 300), (_) => _scan());
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    } else if (mounted) {
      setState(() => _marks = const []);
    }
  }

  void _scan() {
    final root = _app.currentContext?.findRenderObject();
    if (root is! RenderBox || !root.attached || !mounted) return;
    final marks = <_Mark>[];

    void visit(RenderObject node, {required bool inArt}) {
      if (!node.attached) return;
      // Hidden things aren't on screen
      if (node is RenderOffstage && node.offstage) return;
      if (node is RenderOpacity && node.opacity == 0) return;
      if (node is RenderAnimatedOpacity && node.opacity.value == 0) return;
      var art = inArt;
      if (node is RenderBox && node.hasSize && !art) {
        String? artName;
        if (node is RenderAiMarked) {
          artName = node.name;
        } else if (node is RenderCustomPaint) {
          final painter = node.painter ?? node.foregroundPainter;
          if (painter is AiArt) artName = painter.artName;
        }
        if (artName != null && AiInventory.isAi(artName)) {
          marks.add(_Mark(_rectOf(node, root), true, artName));
          art = true;
        } else if (node is RenderParagraph) {
          final text = node.text.toPlainText().trim();
          final font = node.text.style?.fontFamily ?? '';
          final icon = font.contains('Icons') || font == 'FluentIcons';
          if (text.isNotEmpty && !icon && _isAiText(text)) marks.add(_Mark(_rectOf(node, root), false, null));
        }
      }
      node.visitChildren((child) => visit(child, inArt: art));
    }

    visit(root, inArt: false);
    setState(() => _marks = marks);
  }

  /// Unwritten text: with codes showing, whatever shows a code; otherwise
  /// anything the text file hasn't written.
  bool _isAiText(String text) {
    if (Copy.showCodes) return _code.hasMatch(text);
    return !Copy.written.values.contains(text);
  }

  static final _code = RegExp(r'\[[A-Z]\d+\]');

  Rect _rectOf(RenderBox box, RenderBox root) =>
      MatrixUtils.transformRect(box.getTransformTo(root), Offset.zero & box.size);

  @override
  Widget build(BuildContext context) {
    // Above the app's pages, so its labels take the theme's font by hand
    // (but not Flow Block: the audit's own labels must stay readable)
    final themeFont = Theme.of(context).textTheme.bodySmall?.fontFamily;
    final font = themeFont == 'FlowBlock' ? null : themeFont;
    return ValueListenableBuilder(
      valueListenable: _audit.enabled,
      builder: (context, bool on, _) => Stack(
        textDirection: TextDirection.ltr,
        children: [
          KeyedSubtree(key: _app, child: widget.child),
          if (on) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder(
                  valueListenable: _audit.textMode,
                  builder: (context, AuditTextMode mode, _) =>
                      CustomPaint(painter: _MarksPainter(_marks, font, blocks: mode == AuditTextMode.blocks)),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: IgnorePointer(
                child: DefaultTextStyle(
                  style: TextStyle(fontFamily: font, decoration: TextDecoration.none),
                  child: _Summary(marks: _marks),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.marks, this.font, {required this.blocks});

  final List<_Mark> marks;
  final String? font;

  /// Covers text with solid blocks instead of outlining it.
  final bool blocks;

  @override
  void paint(Canvas canvas, Size size) {
    final text = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _textColor;
    final art = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _artColor;
    final block = Paint()..color = _textColor;
    for (final mark in marks.where((m) => !m.art)) {
      if (blocks) {
        canvas.drawRRect(RRect.fromRectAndRadius(mark.rect, const Radius.circular(3)), block);
      } else {
        canvas.drawRect(mark.rect.inflate(1), text);
      }
    }
    for (final mark in marks.where((m) => m.art)) {
      canvas.drawRect(mark.rect, art);
      final label = TextPainter(
        text: TextSpan(
          text: ' AI art: ${mark.label} ',
          style: TextStyle(fontFamily: font, fontSize: 10, color: Colors.white, backgroundColor: _artColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
          canvas, mark.rect.topLeft.translate(0, -label.height).clamp(Offset.zero, size.bottomRight(Offset.zero)));
    }
  }

  @override
  bool shouldRepaint(_MarksPainter old) => old.marks != marks || old.blocks != blocks;
}

extension on Offset {
  Offset clamp(Offset low, Offset high) => Offset(dx.clamp(low.dx, high.dx), dy.clamp(low.dy, high.dy));
}

/// What's highlighted, and what's playing.
class _Summary extends StatelessWidget {
  const _Summary({required this.marks});

  final List<_Mark> marks;

  @override
  Widget build(BuildContext context) {
    final audit = AiAudit.instance;
    Widget chip(String text, Color color) => Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(text,
              style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w700),
              textDirection: TextDirection.ltr),
        );
    return ListenableBuilder(
      listenable: Listenable.merge([audit.heard, audit.music]),
      builder: (context, _) {
        final track = audit.music.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final sound in audit.heard.value) chip(sound, _soundColor),
            if (track != null && AiInventory.isAi(track)) chip('music: $track', _soundColor),
            chip(
                'AI audit: ${marks.where((m) => !m.art).length} text, '
                '${marks.where((m) => m.art).length} art',
                Colors.white),
          ],
        );
      },
    );
  }
}
