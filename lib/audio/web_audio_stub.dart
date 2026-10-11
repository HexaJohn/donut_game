/// Not a browser: sound effects use the audio plugin instead.
class WebAudio {
  WebAudio._();
  static final WebAudio instance = WebAudio._();

  bool get supported => false;

  Future<void> load(String asset) async {}

  void play(String asset, double level) {}

  WebLoop? loop(String asset) => null;

  void unlock() {}

  Future<WebTrack?> track(String asset, {required bool loop, void Function()? onEnded}) async => null;

  void pauseMusic() {}

  void resumeMusic() {}
}

/// A music track playing; its level can be changed as it plays.
abstract class WebTrack {
  set level(double value);
  void stop();
}

/// A looping sound whose level can be changed while it plays.
abstract class WebLoop {
  set level(double value);
  void stop();
}
