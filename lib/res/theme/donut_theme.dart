import 'package:donut_game/audio/click_splash.dart';
import 'package:flutter/material.dart';

enum ThemePreset {
  classic,
  donutLight,
  donutDark,
  midnightCasino,
  neonArcade,
  strawberrySprinkles,
  retroTerminal,
}

/// Game-specific colours that Material's [ColorScheme] has no slot for.
@immutable
class DonutColors extends ThemeExtension<DonutColors> {
  const DonutColors({
    required this.felt,
    required this.feltEdge,
    required this.cardFace,
    required this.cardEdge,
    required this.cardInk,
    required this.cardRed,
    required this.cardBack,
    required this.cardBackPattern,
    required this.accent,
    required this.seat,
    required this.chrome,
    this.glow = false,
  });

  /// Table surface.
  final Color felt;
  final Color feltEdge;
  final Color cardFace;
  final Color cardEdge;

  /// Spades and clubs.
  final Color cardInk;

  /// Hearts and diamonds.
  final Color cardRed;
  final Color cardBack;
  final Color cardBackPattern;

  /// Trump markers, active player and other highlights.
  final Color accent;
  final Color seat;

  /// Title bar and action bar background.
  final Color chrome;

  /// Neon-style glowing edges on cards and table.
  final bool glow;

  static DonutColors of(BuildContext context) => Theme.of(context).extension<DonutColors>()!;

  @override
  DonutColors copyWith({
    Color? felt,
    Color? feltEdge,
    Color? cardFace,
    Color? cardEdge,
    Color? cardInk,
    Color? cardRed,
    Color? cardBack,
    Color? cardBackPattern,
    Color? accent,
    Color? seat,
    Color? chrome,
    bool? glow,
  }) {
    return DonutColors(
      felt: felt ?? this.felt,
      feltEdge: feltEdge ?? this.feltEdge,
      cardFace: cardFace ?? this.cardFace,
      cardEdge: cardEdge ?? this.cardEdge,
      cardInk: cardInk ?? this.cardInk,
      cardRed: cardRed ?? this.cardRed,
      cardBack: cardBack ?? this.cardBack,
      cardBackPattern: cardBackPattern ?? this.cardBackPattern,
      accent: accent ?? this.accent,
      seat: seat ?? this.seat,
      chrome: chrome ?? this.chrome,
      glow: glow ?? this.glow,
    );
  }

  @override
  DonutColors lerp(ThemeExtension<DonutColors>? other, double t) {
    if (other is! DonutColors) return this;
    return DonutColors(
      felt: Color.lerp(felt, other.felt, t)!,
      feltEdge: Color.lerp(feltEdge, other.feltEdge, t)!,
      cardFace: Color.lerp(cardFace, other.cardFace, t)!,
      cardEdge: Color.lerp(cardEdge, other.cardEdge, t)!,
      cardInk: Color.lerp(cardInk, other.cardInk, t)!,
      cardRed: Color.lerp(cardRed, other.cardRed, t)!,
      cardBack: Color.lerp(cardBack, other.cardBack, t)!,
      cardBackPattern: Color.lerp(cardBackPattern, other.cardBackPattern, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      seat: Color.lerp(seat, other.seat, t)!,
      chrome: Color.lerp(chrome, other.chrome, t)!,
      glow: t < 0.5 ? glow : other.glow,
    );
  }
}

class _PresetSpec {
  const _PresetSpec({
    required this.name,
    required this.description,
    required this.brightness,
    required this.primary,
    required this.background,
    required this.surface,
    required this.colors,
    this.fontFamily,
  });

  final String name;
  final String description;
  final Brightness brightness;
  final Color primary;
  final Color background;
  final Color surface;
  final DonutColors colors;
  final String? fontFamily;
}

const _monoFonts = ['Consolas', 'Menlo', 'Courier New', 'monospace'];

final Map<ThemePreset, _PresetSpec> _presets = {
  ThemePreset.classic: _PresetSpec(
    name: 'Classic',
    description: 'The original v1 look',
    brightness: Brightness.light,
    primary: Colors.red,
    background: Colors.grey.shade200,
    surface: Colors.grey.shade100,
    colors: DonutColors(
      felt: Colors.green.shade900,
      feltEdge: const Color(0xFF0B3D10),
      cardFace: Colors.white,
      cardEdge: Colors.black26,
      cardInk: Colors.black,
      cardRed: Colors.red,
      cardBack: Colors.red.shade700,
      cardBackPattern: Colors.red.shade300,
      accent: Colors.red,
      seat: Colors.white,
      chrome: Colors.grey.shade200,
    ),
  ),
  ThemePreset.donutLight: const _PresetSpec(
    name: 'Donut Light',
    description: 'Fresh out of the oven',
    brightness: Brightness.light,
    primary: Color(0xFFE0457B),
    background: Color(0xFFFBF6F0),
    surface: Color(0xFFFFFFFF),
    colors: DonutColors(
      felt: Color(0xFF1F5E4A),
      feltEdge: Color(0xFF164638),
      cardFace: Color(0xFFFFFDF9),
      cardEdge: Color(0x22000000),
      cardInk: Color(0xFF1E1B22),
      cardRed: Color(0xFFD7263D),
      cardBack: Color(0xFFE0457B),
      cardBackPattern: Color(0xFFF7B9CF),
      accent: Color(0xFFE0457B),
      seat: Color(0xFFFFFFFF),
      chrome: Color(0xFFF4ECE3),
    ),
  ),
  ThemePreset.donutDark: const _PresetSpec(
    name: 'Donut Dark',
    description: 'Late-night snack',
    brightness: Brightness.dark,
    primary: Color(0xFFFF6B9D),
    background: Color(0xFF121216),
    surface: Color(0xFF1C1C22),
    colors: DonutColors(
      felt: Color(0xFF143D33),
      feltEdge: Color(0xFF0B261F),
      cardFace: Color(0xFFF4F1EC),
      cardEdge: Color(0x33000000),
      cardInk: Color(0xFF16161A),
      cardRed: Color(0xFFE03A52),
      cardBack: Color(0xFF2A1F33),
      cardBackPattern: Color(0xFFFF6B9D),
      accent: Color(0xFFFF6B9D),
      seat: Color(0xFF24242C),
      chrome: Color(0xFF0D0D10),
    ),
  ),
  ThemePreset.midnightCasino: const _PresetSpec(
    name: 'Midnight Casino',
    description: 'High rollers only',
    brightness: Brightness.dark,
    primary: Color(0xFFD4AF37),
    background: Color(0xFF0E1424),
    surface: Color(0xFF161E33),
    colors: DonutColors(
      felt: Color(0xFF5B1A2A),
      feltEdge: Color(0xFF3D0F1B),
      cardFace: Color(0xFFFFFBF0),
      cardEdge: Color(0x55D4AF37),
      cardInk: Color(0xFF111111),
      cardRed: Color(0xFFB3001B),
      cardBack: Color(0xFF0E1424),
      cardBackPattern: Color(0xFFD4AF37),
      accent: Color(0xFFD4AF37),
      seat: Color(0xFF1B2440),
      chrome: Color(0xFF0A0F1C),
    ),
  ),
  ThemePreset.neonArcade: const _PresetSpec(
    name: 'Neon Arcade',
    description: 'Insert coin',
    brightness: Brightness.dark,
    primary: Color(0xFF00F0FF),
    background: Color(0xFF07070C),
    surface: Color(0xFF111120),
    colors: DonutColors(
      felt: Color(0xFF120A24),
      feltEdge: Color(0xFFFF2BD6),
      cardFace: Color(0xFF0D0D18),
      cardEdge: Color(0xFF00F0FF),
      cardInk: Color(0xFF00F0FF),
      cardRed: Color(0xFFFF2BD6),
      cardBack: Color(0xFF120A24),
      cardBackPattern: Color(0xFF00F0FF),
      accent: Color(0xFFFF2BD6),
      seat: Color(0xFF151528),
      chrome: Color(0xFF07070C),
      glow: true,
    ),
  ),
  ThemePreset.strawberrySprinkles: const _PresetSpec(
    name: 'Strawberry Sprinkles',
    description: 'Extra frosting',
    brightness: Brightness.light,
    primary: Color(0xFF8B4A2B),
    background: Color(0xFFFFE4EE),
    surface: Color(0xFFFFF5F9),
    colors: DonutColors(
      felt: Color(0xFFF48FB1),
      feltEdge: Color(0xFFC2185B),
      cardFace: Color(0xFFFFFFFF),
      cardEdge: Color(0x338B4A2B),
      cardInk: Color(0xFF4E2A1A),
      cardRed: Color(0xFFD81B60),
      cardBack: Color(0xFF8B4A2B),
      cardBackPattern: Color(0xFFFFD54F),
      accent: Color(0xFF8B4A2B),
      seat: Color(0xFFFFFFFF),
      chrome: Color(0xFFFFD6E5),
    ),
  ),
  ThemePreset.retroTerminal: const _PresetSpec(
    name: 'Retro Terminal',
    description: '> donut.exe',
    brightness: Brightness.dark,
    primary: Color(0xFF33FF66),
    background: Color(0xFF000000),
    surface: Color(0xFF050F07),
    fontFamily: 'Consolas',
    colors: DonutColors(
      felt: Color(0xFF001A08),
      feltEdge: Color(0xFF33FF66),
      cardFace: Color(0xFF000000),
      cardEdge: Color(0xFF33FF66),
      cardInk: Color(0xFF33FF66),
      cardRed: Color(0xFFFFB000),
      cardBack: Color(0xFF001A08),
      cardBackPattern: Color(0xFF33FF66),
      accent: Color(0xFFFFB000),
      seat: Color(0xFF020A04),
      chrome: Color(0xFF000000),
      glow: true,
    ),
  ),
};

extension ThemePresetInfo on ThemePreset {
  String get label => _presets[this]!.name;
  String get description => _presets[this]!.description;
  Brightness get brightness => _presets[this]!.brightness;
  DonutColors get colors => _presets[this]!.colors;
  Color get primary => _presets[this]!.primary;
  Color get background => _presets[this]!.background;
}

ThemeData buildTheme(ThemePreset preset) {
  final spec = _presets[preset]!;
  final scheme = ColorScheme.fromSeed(
    seedColor: spec.primary,
    brightness: spec.brightness,
  ).copyWith(
    primary: spec.primary,
    surface: spec.surface,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: spec.brightness,
    scaffoldBackgroundColor: spec.background,
    canvasColor: spec.background,
    fontFamily: spec.fontFamily,
    fontFamilyFallback: spec.fontFamily != null ? _monoFonts : null,
    extensions: [spec.colors],
  );
  return base.copyWith(
    // Every ripple (buttons, chips, menus...) also clicks
    splashFactory: ClickSplashFactory(base.splashFactory),
    cardTheme: CardThemeData(
      color: spec.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tooltipTheme: TooltipThemeData(waitDuration: const Duration(milliseconds: 400)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.onSurface.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}
