import 'dart:async';
import 'dart:convert';

import 'package:donut_game/modes/bad_batch/bb_cards.dart';
import 'package:http/http.dart' as http;

/// Imports community decks from CrCast (crcast.cc, also at cast.clrtd.com).
class CrCast {
  static const _api = 'https://api.crcast.cc/v1/cc/decks';

  /// Pulls a deck code out of whatever was pasted: a bare code, or a link
  /// like https://cast.clrtd.com/deck/ZQW8G. Null if there isn't one.
  static String? parseCode(String input) {
    final text = input.trim();
    final fromLink = RegExp(r'/deck/([A-Za-z0-9]{5})\b').firstMatch(text);
    if (fromLink != null) return fromLink.group(1)!.toUpperCase();
    if (RegExp(r'^[A-Za-z0-9]{5}$').hasMatch(text)) return text.toUpperCase();
    return null;
  }

  /// Downloads deck [code]. Throws a readable message if it can't.
  static Future<Deck> fetch(String code) async {
    final http.Response response;
    try {
      response = await http.get(Uri.parse('$_api/$code/all')).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw 'CrCast took too long to answer.';
    } catch (e) {
      throw 'Could not reach CrCast. Check your internet connection.';
    }
    if (response.statusCode == 404) throw 'No deck with code $code.';
    if (response.statusCode != 200) throw 'CrCast returned an error (${response.statusCode}).';

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json['error'] != 0) throw json['message'] ?? 'CrCast could not load that deck.';
    // Prompts are lists of text pieces with a blank between each
    final prompts = <PromptCard>[
      for (final call in json['calls'] ?? [])
        if (call['text'] is List && (call['text'] as List).length >= 2) PromptCard(List<String>.from(call['text'])),
    ];
    final responses = <ResponseCard>[
      for (final response in json['responses'] ?? [])
        if (response['text'] is List && (response['text'] as List).isNotEmpty)
          ResponseCard((response['text'] as List).join(' ').trim()),
    ];
    if (prompts.isEmpty && responses.isEmpty) throw 'That deck has no cards.';
    return Deck(
      code: code,
      name: (json['name'] as String? ?? code).trim(),
      prompts: prompts,
      responses: responses,
    );
  }
}
