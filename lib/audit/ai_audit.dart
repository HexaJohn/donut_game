import 'dart:async';

import 'package:donut_game/audit/ai_inventory.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Marks a painter as AI-made art, for the AI audit overlay.
mixin AiArt on CustomPainter {
  /// What the overlay calls it.
  String get artName => runtimeType.toString();
}

/// Marks a widget's drawing as AI-made art, for art that isn't a single
/// painter (card faces, art painted to an image first).
class AiMarked extends SingleChildRenderObjectWidget {
  const AiMarked({super.key, required this.name, super.child});

  final String name;

  @override
  RenderAiMarked createRenderObject(BuildContext context) => RenderAiMarked(name);

  @override
  void updateRenderObject(BuildContext context, RenderAiMarked renderObject) => renderObject.name = name;
}

class RenderAiMarked extends RenderProxyBox {
  RenderAiMarked(this.name);

  String name;
}

/// How the AI audit shows text.
enum AuditTextMode {
  /// Outlined, still readable.
  outline,

  /// Covered with solid blocks.
  blocks,

  /// Set in Flow Block, so words keep their shape but can't be read.
  flow,
}

/// The AI audit: whether the overlay is on, and the sounds just heard.
class AiAudit {
  AiAudit._();
  static final AiAudit instance = AiAudit._();

  static const _prefsKey = 'dev.aiAudit';
  static const _modeKey = 'dev.aiAuditText';

  /// On with --dart-define=AI_AUDIT=true, or from the developer panel.
  final ValueNotifier<bool> enabled = ValueNotifier(const bool.fromEnvironment('AI_AUDIT'));

  final ValueNotifier<AuditTextMode> textMode = ValueNotifier(AuditTextMode.outline);

  /// Whether text should be set in Flow Block right now.
  bool get flowText => enabled.value && textMode.value == AuditTextMode.flow;

  /// Sounds played in the last moment, newest last.
  final ValueNotifier<List<String>> heard = ValueNotifier(const []);

  /// The music track playing, if any.
  final ValueNotifier<String?> music = ValueNotifier(null);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefsKey) == true) enabled.value = true;
      textMode.value =
          AuditTextMode.values.where((mode) => mode.name == prefs.getString(_modeKey)).firstOrNull ?? textMode.value;
    } catch (_) {}
  }

  void setEnabled(bool on) {
    enabled.value = on;
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(_prefsKey, on)).catchError((_) => false);
  }

  /// [theme], with every text style set in Flow Block while that mode is
  /// on: words keep their shape but can't be read.
  ThemeData theme(ThemeData theme) => !flowText
      ? theme
      : theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'FlowBlock'),
          primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'FlowBlock'),
        );

  void setTextMode(AuditTextMode mode) {
    textMode.value = mode;
    SharedPreferences.getInstance().then((prefs) => prefs.setString(_modeKey, mode.name)).catchError((_) => false);
  }

  /// A sound effect just played.
  void sound(String name) {
    if (!enabled.value || !AiInventory.isAi(name)) return;
    final label = 'sound: $name';
    heard.value = [...heard.value, label].reversed.take(4).toList().reversed.toList();
    Timer(const Duration(milliseconds: 2500), () {
      final list = [...heard.value]..remove(label);
      heard.value = list;
    });
  }

  /// The music changed.
  void playing(String? track) => music.value = track;
}
