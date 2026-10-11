/// Masks slurs and swearing in what players type (chat and nicknames), so
/// strangers matched together don't see it. Deliberately small and
/// predictable: whole words for swearing (so "class" and "Scunthorpe" pass),
/// anywhere in a word for slurs, after undoing common disguises (l33t,
/// repeated letters, separators).
library;

/// Swear words, matched as whole words in any of these forms.
const _swears = {
  'fuck', 'fucks', 'fucked', 'fucker', 'fuckers', 'fucking', 'fuckin', 'motherfucker', 'motherfuckers', 'fck', 'fuk',
  'shit', 'shits', 'shitty', 'shitting', 'bullshit', 'shithead',
  'bitch', 'bitches', 'bitching', 'bitchy',
  'cunt', 'cunts',
  'dick', 'dicks', 'dickhead',
  'cock', 'cocks', 'cocksucker',
  'pussy', 'pussies',
  'asshole', 'assholes', 'arsehole', 'ass',
  'bastard', 'bastards',
  'whore', 'whores', 'slut', 'sluts',
  'wanker', 'wankers', 'twat', 'twats',
  'porn', 'rape', 'raped', 'rapist',
  'kys',
  // Slurs that are also parts of everyday words ("spice", "raccoon")
  'spic', 'spics', 'coon', 'coons', 'paki', 'pakis', 'chink', 'chinks', 'dyke', 'dykes', 'retard', 'retards',
  'retarded',
};

/// Slurs, masked wherever they turn up inside a word.
const _slurs = {'nigger', 'nigga', 'faggot', 'fagot', 'tranny', 'kike', 'wetback', 'gook', 'beaner', 'raghead'};

const _leet = {'0': 'o', '1': 'i', '!': 'i', '3': 'e', '4': 'a', '@': 'a', '5': 's', r'$': 's', '7': 't', '8': 'b'};

/// The word as a filter sees it: lower case, disguises undone, repeats
/// squeezed ("fuuuuck" -> "fuck").
String _plain(String word, {bool squeeze = true}) {
  final out = StringBuffer();
  String? last;
  for (final rune in word.toLowerCase().split('')) {
    final c = _leet[rune] ?? rune;
    if (!RegExp(r'[a-z]').hasMatch(c)) continue;
    if (squeeze && c == last) continue;
    out.write(c);
    last = c;
  }
  return out.toString();
}

bool _bad(String word) {
  if (word.isEmpty) return false;
  // Squeezing turns "ass" into "as", so swears are checked both ways
  final plain = _plain(word, squeeze: false), squeezed = _plain(word);
  if (_swears.contains(plain) || _swears.contains(squeezed)) return true;
  // Exact spelling only: squeezing slurs would also catch "Niger"
  return _slurs.any(plain.contains);
}

/// [text] with every bad word replaced by asterisks of the same length.
/// Also catches words spelled out with gaps ("f u c k", "f.u.c.k").
String cleanText(String text) {
  final tokens = RegExp(r'\S+').allMatches(text).toList();
  if (tokens.isEmpty) return text;
  final masked = List<bool>.filled(tokens.length, false);
  for (var i = 0; i < tokens.length; i++) {
    if (_bad(tokens[i].group(0)!)) masked[i] = true;
  }
  // Runs of single letters, read as one word
  for (var start = 0; start < tokens.length; start++) {
    if (_plain(tokens[start].group(0)!).length != 1) continue;
    var end = start;
    while (end + 1 < tokens.length && _plain(tokens[end + 1].group(0)!).length == 1) {
      end++;
    }
    if (end > start) {
      final joined = [for (var i = start; i <= end; i++) tokens[i].group(0)!].join();
      if (_bad(joined)) {
        for (var i = start; i <= end; i++) {
          masked[i] = true;
        }
      }
    }
    start = end;
  }
  // Words with separators inside ("f.u.c.k", "f-u-c-k"), checked as a whole
  final out = StringBuffer();
  var at = 0;
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    out.write(text.substring(at, token.start));
    final word = token.group(0)!;
    final parts = word.split(RegExp(r'[^A-Za-z0-9@$!]+')).where((part) => part.isNotEmpty);
    final hidden = masked[i] || parts.any(_bad);
    out.write(hidden ? '*' * word.length : word);
    at = token.end;
  }
  out.write(text.substring(at));
  return out.toString();
}

/// Whether a nickname needs changing before others can see it.
bool isOffensiveName(String name) => cleanText(name) != name;
