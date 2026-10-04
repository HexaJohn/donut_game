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

  // Bad Batch
  List<String> bbDeckCodes = [];
  bool bbBuiltinDeck = true;
  bool bbXDeck = false;
  int bbPointsToWin = 7;
  int bbBlankCards = 3;

  /// Has confirmed they're an adult and fine with offensive humour.
  bool adultConfirmed = false;

  /// The mode a server starts in, as chosen in the server window.
  String serverMode = 'donut';

  // Acrotron, the AI player running on a local Ollama
  String ollamaUrl = 'http://localhost:11434';
  String ollamaModel = 'gemma3:4b';

  /// Empty means the default personality.
  String acrotronPersonality = '';

  /// 0..1: how often it chimes in uninvited.
  double acrotronChattiness = 0.35;
  bool seatAcrotronOffline = false;

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
    bbDeckCodes = prefs.getStringList('bbDeckCodes') ?? [];
    bbBuiltinDeck = prefs.getBool('bbBuiltinDeck') ?? true;
    bbXDeck = prefs.getBool('bbXDeck') ?? false;
    bbPointsToWin = prefs.getInt('bbPointsToWin') ?? bbPointsToWin;
    bbBlankCards = prefs.getInt('bbBlankCards') ?? bbBlankCards;
    adultConfirmed = prefs.getBool('adultConfirmed') ?? false;
    serverMode = prefs.getString('serverMode') ?? serverMode;
    ollamaUrl = prefs.getString('ollamaUrl') ?? ollamaUrl;
    ollamaModel = prefs.getString('ollamaModel') ?? ollamaModel;
    acrotronPersonality = prefs.getString('acrotronPersonality') ?? '';
    acrotronChattiness = prefs.getDouble('acrotronChattiness') ?? acrotronChattiness;
    seatAcrotronOffline = prefs.getBool('seatAcrotronOffline') ?? false;
  }

  void saveAcrotron() {
    _prefs
      ?..setString('ollamaUrl', ollamaUrl)
      ..setString('ollamaModel', ollamaModel)
      ..setString('acrotronPersonality', acrotronPersonality)
      ..setDouble('acrotronChattiness', acrotronChattiness)
      ..setBool('seatAcrotronOffline', seatAcrotronOffline);
  }

  void saveBadBatch() {
    _prefs
      ?..setStringList('bbDeckCodes', bbDeckCodes)
      ..setBool('bbBuiltinDeck', bbBuiltinDeck)
      ..setBool('bbXDeck', bbXDeck)
      ..setInt('bbPointsToWin', bbPointsToWin)
      ..setInt('bbBlankCards', bbBlankCards)
      ..setBool('adultConfirmed', adultConfirmed)
      ..setString('serverMode', serverMode);
  }

  /// Downloaded decks are kept so they still work offline.
  String? cachedDeck(String code) => _prefs?.getString('deck.$code');
  void cacheDeck(String code, String json) => _prefs?.setString('deck.$code', json);
  void forgetDeck(String code) => _prefs?.remove('deck.$code');

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
