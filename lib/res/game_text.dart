import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/res/game_text_watch_stub.dart'
    if (dart.library.io) 'package:donut_game/res/game_text_watch_io.dart' as watch;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The game's text file (assets/copy/donut_text.txt), loaded at start-up.
/// In debug builds it stays live: a hot reload re-reads it, and with
/// --dart-define=DONUT_TEXT_FILE=<path> (the VS Code launch profiles set it)
/// saving the file updates the running game at once.
class GameText {
  GameText._();

  static const asset = 'assets/copy/donut_text.txt';

  /// The file on disk to watch while developing, if set.
  static const _source = String.fromEnvironment('DONUT_TEXT_FILE');

  static Future<void> load() async {
    try {
      // Hot reload brings the new file into the app, but the bundle keeps
      // the old one cached
      rootBundle.evict(asset);
      Copy.load(await rootBundle.loadString(asset, cache: false));
    } catch (_) {}
  }

  /// Starts watching the source file, in debug builds that name it.
  static void watchSource() {
    if (!kDebugMode || _source.isEmpty) return;
    watch.watchFile(_source, (contents) {
      Copy.load(contents);
      _redrawEverything();
    });
  }

  static bool _redrawing = false;

  /// Rebuilds the whole app, so every line picks up its new text.
  static void _redrawEverything() {
    _redrawing = true;
    WidgetsBinding.instance.reassembleApplication().whenComplete(() => _redrawing = false);
  }
}

/// Re-reads the text file on every hot reload (debug builds), then redraws
/// the app with it.
class GameTextReloader extends StatefulWidget {
  const GameTextReloader({super.key, required this.child});

  final Widget child;

  @override
  State<GameTextReloader> createState() => _GameTextReloaderState();
}

class _GameTextReloaderState extends State<GameTextReloader> {
  @override
  void reassemble() {
    super.reassemble();
    // A redraw this class asked for doesn't need the file again
    if (GameText._redrawing) return;
    GameText.load().then((_) => GameText._redrawEverything());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
