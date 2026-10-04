import 'package:donut_game/modes/bad_batch/bb_cards.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:flutter/material.dart';

/// Width to height of every Bad Batch card.
const double bbCardAspect = 0.72;

/// Text that shrinks to fit its card instead of overflowing.
class _FitText extends StatelessWidget {
  const _FitText(this.span, {required this.width});

  final InlineSpan span;
  final double width;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: Text.rich(span)),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.color, required this.scale});

  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DonutLogo(size: 12 * scale, shadow: false, frosting: color),
        SizedBox(width: 4 * scale),
        Text('Bad Batch',
            style: TextStyle(color: color, fontSize: 9 * scale, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ],
    );
  }
}

/// The black prompt card. Given [answers], it shows them dropped into the
/// blanks (picked out in the accent colour).
class BbPromptCard extends StatelessWidget {
  const BbPromptCard({super.key, required this.prompt, required this.width, this.answers});

  final PromptCard prompt;
  final double width;
  final List<String>? answers;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    final scale = width / 160;
    final style = TextStyle(color: Colors.white, fontSize: 17 * scale, fontWeight: FontWeight.w700, height: 1.25);
    final spans = <InlineSpan>[];
    for (var i = 0; i < prompt.pieces.length; i++) {
      spans.add(TextSpan(text: prompt.pieces[i]));
      if (i < prompt.pick) {
        final answer = answers != null && i < answers!.length ? answers![i].trim() : null;
        final last = i == prompt.pick - 1 && prompt.pieces[i + 1].trim().isEmpty;
        spans.add(answer == null
            ? const TextSpan(text: '______')
            : TextSpan(
                text: '${PromptCard.spaceBefore(prompt.pieces[i])}${PromptCard.cleanAnswer(answer, last: last)}',
                style: TextStyle(color: colors.accent),
              ));
      }
    }
    return Container(
      width: width,
      height: width / bbCardAspect,
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF111114),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _FitText(TextSpan(style: style, children: spans), width: width - 24 * scale)),
          Row(
            children: [
              Expanded(child: _CardFooter(color: Colors.white70, scale: scale)),
              if (prompt.pick > 1)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10 * scale)),
                  child: Text('PICK ${prompt.pick}',
                      style: TextStyle(color: Colors.black, fontSize: 9 * scale, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A white answer card.
class BbAnswerCard extends StatelessWidget {
  const BbAnswerCard({
    super.key,
    required this.card,
    required this.width,
    this.order,
    this.faceDown = false,
    this.highlighted = false,
    this.dimmed = false,
    this.writtenText,
  });

  final ResponseCard card;
  final double width;

  /// Position in your selection (1, 2...), shown as a badge.
  final int? order;
  final bool faceDown;
  final bool highlighted;
  final bool dimmed;

  /// What you've written on a blank card you're about to play.
  final String? writtenText;

  @override
  Widget build(BuildContext context) {
    final colors = DonutColors.of(context);
    final scale = width / 160;
    final height = width / bbCardAspect;
    if (faceDown) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(color: Colors.black12),
          boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DonutLogo(size: 40 * scale, shadow: false, frosting: colors.accent),
            SizedBox(height: 6 * scale),
            Text('Bad Batch',
                style: TextStyle(color: Colors.black54, fontSize: 12 * scale, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    final blankUnwritten = card.blank && (writtenText == null || writtenText!.isEmpty);
    final text = card.blank ? (writtenText ?? '') : card.text;
    return AnimatedOpacity(
      opacity: dimmed ? 0.45 : 1,
      duration: const Duration(milliseconds: 250),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: highlighted || order != null ? colors.accent : (card.blank ? Colors.black26 : Colors.black12),
            width: highlighted || order != null ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: highlighted ? colors.accent.withValues(alpha: 0.45) : const Color(0x33000000),
              offset: const Offset(0, 2),
              spreadRadius: highlighted ? 4 : 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: blankUnwritten
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, size: 26 * scale, color: Colors.black38),
                              SizedBox(height: 4 * scale),
                              Text('Blank card\nwrite your own',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: 12 * scale,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                      : _FitText(
                          TextSpan(
                            text: text,
                            style: TextStyle(
                                color: Colors.black, fontSize: 16 * scale, fontWeight: FontWeight.w700, height: 1.25),
                          ),
                          width: width - 24 * scale,
                        ),
                ),
                Row(
                  children: [
                    Expanded(child: _CardFooter(color: Colors.black45, scale: scale)),
                    if (card.blank && !blankUnwritten)
                      Icon(Icons.edit_rounded, size: 12 * scale, color: Colors.black38),
                    if (order != null)
                      Container(
                        width: 22 * scale,
                        height: 22 * scale,
                        margin: EdgeInsets.only(left: 4 * scale),
                        decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('$order',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12 * scale)),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
