/// Not a browser: sound effects use the audio plugin instead.
class WebAudio {
  WebAudio._();
  static final WebAudio instance = WebAudio._();

  bool get supported => false;

  Future<void> load(String asset) async {}

  void play(String asset, double level) {}

  WebLoop? loop(String asset) => null;

  void unlock() {}

  void nowPlaying(String title) {}
}

/// A looping sound whose level can be changed while it plays.
abstract class WebLoop {
  set level(double value);
  void stop();
}
