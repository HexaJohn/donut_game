/// A black prompt card. [pieces] is the text split at each blank, so a card
/// with one blank has two pieces; a question with the answer at the end has
/// an empty last piece.
class PromptCard {
  PromptCard(this.pieces) : assert(pieces.length >= 2);

  final List<String> pieces;

  /// How many answers it takes.
  int get pick => pieces.length - 1;

  /// The prompt with blanks shown as underlines.
  String get display => pieces.join('_____');

  /// The prompt with [answers] dropped into the blanks.
  String fill(List<String> answers) {
    final buffer = StringBuffer();
    for (var i = 0; i < pieces.length; i++) {
      buffer.write(pieces[i]);
      if (i < answers.length && i < pick) {
        buffer.write(spaceBefore(pieces[i]));
        buffer.write(cleanAnswer(answers[i], last: i == pick - 1 && pieces[i + 1].trim().isEmpty));
      }
    }
    return buffer.toString().trim();
  }

  /// Question cards ("What's that smell?") have no space before their blank;
  /// sentence cards ("ended because of ") already do.
  static String spaceBefore(String piece) => piece.isEmpty || piece.endsWith(' ') ? '' : ' ';

  /// Answers read as part of the sentence: no full stop mid-line, but kept
  /// when the answer ends the card.
  static String cleanAnswer(String answer, {bool last = false}) {
    final trimmed = answer.trim();
    if (last) return trimmed;
    return trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  Map<String, dynamic> toJson() => {'pieces': pieces};

  static PromptCard fromJson(Map<String, dynamic> json) => PromptCard(List<String>.from(json['pieces']));

  /// Built-in cards are written with "_" for each blank.
  static PromptCard parse(String text) {
    final pieces = text.split('_');
    return PromptCard(pieces.length >= 2 ? pieces : [text, '']);
  }
}

/// A white answer card. A [blank] card's [text] is written by whoever plays it.
class ResponseCard {
  const ResponseCard(this.text, {this.blank = false});

  final String text;
  final bool blank;

  ResponseCard written(String text) => ResponseCard(text, blank: false);

  Map<String, dynamic> toJson() => {'text': text, if (blank) 'blank': true};

  static ResponseCard fromJson(Map<String, dynamic> json) =>
      ResponseCard(json['text'] ?? '', blank: json['blank'] == true);
}

/// A named set of cards: the built-in deck or one imported from CrCast.
class Deck {
  const Deck({required this.code, required this.name, required this.prompts, required this.responses});

  /// CrCast deck code, or "builtin".
  final String code;
  final String name;
  final List<PromptCard> prompts;
  final List<ResponseCard> responses;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'prompts': prompts.map((e) => e.toJson()).toList(),
        'responses': responses.map((e) => e.toJson()).toList(),
      };

  static Deck fromJson(Map<String, dynamic> json) => Deck(
        code: json['code'] ?? '',
        name: json['name'] ?? '',
        prompts: [for (final p in json['prompts'] ?? []) PromptCard.fromJson(p)],
        responses: [for (final r in json['responses'] ?? []) ResponseCard.fromJson(r)],
      );
}
