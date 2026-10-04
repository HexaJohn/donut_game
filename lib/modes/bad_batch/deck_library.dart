import 'dart:convert';

import 'package:donut_game/data/settings.dart';
import 'package:donut_game/modes/bad_batch/bb_builtin_deck.dart';
import 'package:donut_game/modes/bad_batch/bb_cards.dart';
import 'package:donut_game/modes/bad_batch/crcast.dart';
import 'package:flutter/foundation.dart';

/// The decks this device knows about: the built-in one plus any imported from
/// CrCast. Imports are cached in [Settings] so they work offline afterwards.
class DeckLibrary {
  DeckLibrary._();
  static final DeckLibrary instance = DeckLibrary._();

  final Settings _settings = Settings.instance;

  /// Imported decks by code, in the order they were added.
  final ValueNotifier<Map<String, Deck>> imported = ValueNotifier({});
  bool _loaded = false;

  /// Reads cached imports. Safe to call more than once.
  void load() {
    if (_loaded) return;
    _loaded = true;
    final decks = <String, Deck>{};
    for (final code in _settings.bbDeckCodes) {
      final json = _settings.cachedDeck(code);
      if (json == null) continue;
      try {
        decks[code] = Deck.fromJson(jsonDecode(json));
      } catch (e) {
        debugPrint('DeckLibrary: cached $code unreadable: $e');
      }
    }
    imported.value = decks;
  }

  /// Imports a deck from a CrCast code or link. Throws a readable message.
  Future<Deck> add(String input) async {
    load();
    final code = CrCast.parseCode(input);
    if (code == null) throw 'That doesn\'t look like a CrCast deck code or link.';
    final deck = await CrCast.fetch(code);
    _settings.cacheDeck(code, jsonEncode(deck.toJson()));
    if (!_settings.bbDeckCodes.contains(code)) _settings.bbDeckCodes = [..._settings.bbDeckCodes, code];
    _settings.saveBadBatch();
    imported.value = {...imported.value, code: deck};
    return deck;
  }

  void remove(String code) {
    _settings.bbDeckCodes = _settings.bbDeckCodes.where((element) => element != code).toList();
    _settings.forgetDeck(code);
    _settings.saveBadBatch();
    imported.value = {...imported.value}..remove(code);
  }

  /// Everything that goes into a game: the built-in deck if it's switched
  /// on, then every import.
  List<Deck> get activeDecks {
    load();
    return [if (_settings.bbBuiltinDeck) builtinDeck, ...imported.value.values];
  }
}
