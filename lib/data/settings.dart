import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String appVersion = '2.1.0';
const int defaultPort = 27960;

/// User preferences that survive restarts.
class Settings {
  Settings._();
  static final Settings instance = Settings._();

  SharedPreferences? _prefs;

  final ValueNotifier<ThemePreset> theme = ValueNotifier(ThemePreset.donutLight);
  String nickname = '';
  String serverHost = '127.0.0.1';
  int serverPort = defaultPort;
  int bots = 3;

  /// Volumes run 0.0 to 1.0. Muting keeps the level for when it's unmuted.
  final ValueNotifier<double> musicVolume = ValueNotifier(0.4);
  final ValueNotifier<bool> musicMuted = ValueNotifier(false);
  final ValueNotifier<double> sfxVolume = ValueNotifier(0.8);
  final ValueNotifier<bool> sfxMuted = ValueNotifier(false);

  double get effectiveMusicVolume => musicMuted.value ? 0 : musicVolume.value;
  double get effectiveSfxVolume => sfxMuted.value ? 0 : sfxVolume.value;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // Storage unavailable: run with defaults
      return;
    }
    final prefs = _prefs!;
    final themeName = prefs.getString('theme');
    theme.value = ThemePreset.values.firstWhere(
      (element) => element.name == themeName,
      orElse: () => ThemePreset.donutLight,
    );
    nickname = prefs.getString('nickname') ?? '';
    serverHost = prefs.getString('serverHost') ?? serverHost;
    serverPort = prefs.getInt('serverPort') ?? serverPort;
    bots = prefs.getInt('bots') ?? bots;
    musicVolume.value = prefs.getDouble('musicVolume') ?? musicVolume.value;
    musicMuted.value = prefs.getBool('musicMuted') ?? false;
    sfxVolume.value = prefs.getDouble('sfxVolume') ?? sfxVolume.value;
    sfxMuted.value = prefs.getBool('sfxMuted') ?? false;
  }

  void saveAudio() {
    _prefs
      ?..setDouble('musicVolume', musicVolume.value)
      ..setBool('musicMuted', musicMuted.value)
      ..setDouble('sfxVolume', sfxVolume.value)
      ..setBool('sfxMuted', sfxMuted.value);
  }

  void setTheme(ThemePreset preset) {
    theme.value = preset;
    _prefs?.setString('theme', preset.name);
  }

  void save() {
    _prefs
      ?..setString('nickname', nickname)
      ..setString('serverHost', serverHost)
      ..setInt('serverPort', serverPort)
      ..setInt('bots', bots);
  }
}
