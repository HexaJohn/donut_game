import 'dart:io';

import 'package:donut_copy/donut_copy.dart';

/// Brings assets/copy/donut_text.txt up to date with the game's lines:
/// adds new codes, keeps everything written, and says how much is written.
///
///   dart run donut_copy:sync        (from packages/donut_copy)
void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : '../../assets/copy/donut_text.txt';
  final file = File(path);
  final existing = file.existsSync() ? file.readAsStringSync() : '';
  file
    ..createSync(recursive: true)
    ..writeAsStringSync(Copy.file(copyAreas, existing: existing));
  final written = Copy.parse(file.readAsStringSync());
  final lines = allLines.toList();
  final done = lines.where((line) => written.containsKey(line.code)).length;
  final codes = lines.map((line) => line.code).toList();
  final duplicates = codes.where((code) => codes.indexOf(code) != codes.lastIndexOf(code)).toSet();
  if (duplicates.isNotEmpty) stderr.writeln('Duplicate codes: ${duplicates.join(', ')}');
  stdout.writeln('$done of ${lines.length} lines written. ${file.path}');
}
