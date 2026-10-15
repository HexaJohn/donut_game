/// One piece of text players see, with a code it's known by.
///
/// [ai] is the AI-written original. Once the game's text file gives the
/// code text of its own (see [Copy]), that's used instead, everywhere,
/// online included. Text with `{slots}` has them filled in when shown.
class Line {
  const Line(this.code, this.ai);

  /// Short, stable code: an area letter and a number, like `H1`.
  final String code;

  /// The AI-written original, used until it's replaced.
  final String ai;

  /// Whether the text file replaces this line.
  bool get written => Copy.written.containsKey(code);

  /// The `{slots}` this line's text must keep.
  List<String> get slots => [for (final match in _slot.allMatches(ai)) match.group(0)!];

  static final _slot = RegExp(r'\{[a-zA-Z0-9_]+\}');

  /// The text to show, with [args] filled into its `{slots}`.
  String call([Map<String, Object?> args = const {}]) {
    final own = Copy.written[code];
    if (own == null && Copy.showCodes) return '[$code]';
    var text = own ?? ai;
    if (args.isEmpty) return text;
    for (final MapEntry(:key, :value) in args.entries) {
      text = text.replaceAll('{$key}', '$value');
    }
    return text;
  }

  /// [call] with one slot, for the common case.
  String of(String slot, Object? value) => call({slot: value});

  @override
  String toString() => call();
}

/// The game's text: what the text file has replaced, and how unwritten
/// text is shown.
class Copy {
  Copy._();

  /// Text from the text file, by code.
  static Map<String, String> written = {};

  /// Shows unwritten lines as their codes (the AI audit), so the AI
  /// originals aren't read.
  static bool showCodes = false;

  /// Reads the text file: lines of `CODE {slots} | text`; `#` starts a
  /// comment; blank text leaves the line unwritten. `\n` in text is a line
  /// break.
  static Map<String, String> parse(String file) {
    final texts = <String, String>{};
    for (final raw in file.split('\n')) {
      final line = raw.trimRight();
      if (line.trimLeft().startsWith('#')) continue;
      final bar = line.indexOf('|');
      if (bar < 0) continue;
      final code = line.substring(0, bar).trim().split(RegExp(r'\s+')).first;
      final text = line.substring(bar + 1).trim().replaceAll(r'\n', '\n');
      if (code.isNotEmpty && text.isNotEmpty) texts[code] = text;
    }
    return texts;
  }

  static void load(String file) => written = parse(file);

  /// The text file for [lines], keeping what [existing] has written, with
  /// codes and slots only: none of the AI text.
  static String file(Iterable<(String, List<Line>)> areas, {String existing = ''}) {
    final kept = parse(existing);
    final out = StringBuffer()
      ..writeln('# Donut: every piece of text players see, by code.')
      ..writeln('# Write your text after the | on a line. Blank means not written yet.')
      ..writeln('# {slots} are filled in by the game: keep each one somewhere in your text.')
      ..writeln('# Use \\n for a line break. Turn on the AI audit (long-press the version')
      ..writeln('# number) to see each code where it appears.')
      ..writeln();
    final known = <String>{};
    for (final (area, lines) in areas) {
      out.writeln('# $area');
      for (final line in lines) {
        known.add(line.code);
        final slots = line.slots.toSet().join(' ');
        final text = (kept[line.code] ?? '').replaceAll('\n', r'\n');
        out.writeln('${line.code}${slots.isEmpty ? '' : ' $slots'} |${text.isEmpty ? '' : ' $text'}');
      }
      out.writeln();
    }
    final gone = kept.keys.where((code) => !known.contains(code)).toList();
    if (gone.isNotEmpty) {
      out.writeln('# No longer used by the game (kept so nothing you wrote is lost)');
      for (final code in gone) {
        out.writeln('$code | ${kept[code]!.replaceAll('\n', r'\n')}');
      }
    }
    return out.toString();
  }

  /// Finds which line [text] came from (with its slots filled in), for text
  /// that arrives already written, like the online table's announcements.
  static Line? recognize(String text, Iterable<Line> lines) {
    for (final line in lines) {
      if (_pattern(line).hasMatch(text)) return line;
    }
    return null;
  }

  static final Map<String, RegExp> _patterns = {};

  static RegExp _pattern(Line line) => _patterns.putIfAbsent(line.code, () {
        final parts = line.ai.split(Line._slot).map(RegExp.escape).join('.+?');
        return RegExp('^$parts\$', dotAll: true);
      });
}
