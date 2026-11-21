import 'dart:io';

import 'package:donut_engine/donut_engine.dart' show Suit, Value;
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/progression/environments.dart';
import 'package:donut_game/progression/ranks.dart';
import 'package:donut_game/res/art_replacement.dart';
import 'package:flutter_test/flutter_test.dart';

/// The art_replacement folder: every folder bundled, every file named for
/// art the game draws.
void main() {
  final root = Directory(ArtReplacement.folder);
  final files = root.existsSync()
      ? root
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.replaceAll(r'\', '/'))
          .where((path) => ArtReplacement.types.contains(path.split('.').last.toLowerCase()))
          .toList()
      : <String>[];

  test('every folder of art is in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final folders = {for (final path in files) path.substring(0, path.lastIndexOf('/') + 1)};
    final missing = folders.where((folder) => !pubspec.contains('- $folder\n')).toList()..sort();
    expect(missing, isEmpty, reason: 'add these under flutter: assets: in pubspec.yaml');
  });

  test('every file replaces something', () {
    final known = _artNames();
    final unknown = [
      for (final path in files)
        if (!_matches(path.substring(ArtReplacement.folder.length + 1, path.lastIndexOf('.')), known)) path
    ];
    expect(unknown, isEmpty, reason: 'named like nothing in test/art_export_test.dart\'s export');
  });
}

bool _matches(String name, Set<String> known) {
  if (known.contains(name)) return true;
  // Rank badges go by their number, with any label after it
  final rank = RegExp(r'^ranks/(\d\d)(_.*)?$').firstMatch(name);
  return rank != null && int.parse(rank.group(1)!) < ranks.length;
}

Set<String> _artNames() {
  final ids = catalog.map((item) => item.id);
  return {
    for (final id in ['bakery', 'market', 'diner', 'riverboat', 'orbital', 'grand']) 'backdrops/$id',
    for (final env in environments) 'tables/${artSlug(env.id)}',
    for (final id in ids.where((id) => id.startsWith('pattern.'))) 'card_backs/${artSlug(id)}',
    for (final style in {'classic', ...ids.where((id) => id.startsWith('face.')).map(artSlug)})
      for (final suit in Suit.values)
        for (final value in Value.values) 'card_faces/$style/${suit.name}_${value.name}',
    'card_faces/sprinkle_edge',
    for (final suit in Suit.values) 'suits/${suit.name}',
    for (final shape in EmblemShape.values) 'emblems/${shape.name}',
    'logo/donut',
    'table_tools/revolver',
    'table_tools/revolver_firing',
    for (final n in [1, 2, 3, 4]) 'table_tools/bullet_hole_$n',
    for (final n in [1, 2, 3, 4, 5]) 'table_tools/marker_$n',
    'table_tools/eraser',
    'table_tools/flashbang',
    'table_tools/flashbang_lit',
  };
}
