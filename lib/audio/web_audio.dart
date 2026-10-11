/// Sound effects and music through the browser's Web Audio API, on the web
/// only.
///
/// Media elements (what the audio plugin plays through in a browser) are
/// treated as media by phones: on iOS every sound took over Control Center's
/// Now Playing. Web Audio isn't listed there, starts sounds instantly, and
/// overlaps them freely. Elsewhere this does nothing.
library;

export 'web_audio_stub.dart' if (dart.library.js_interop) 'web_audio_web.dart';
