import 'dart:math';

import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:flutter/material.dart';

enum _Layer { background, foreground, accent }

/// Builds the player's emblem: shape, icon, three colours. Every change is
/// saved as it's made.
class EmblemEditor extends StatefulWidget {
  const EmblemEditor({super.key});

  @override
  State<EmblemEditor> createState() => _EmblemEditorState();
}

class _EmblemEditorState extends State<EmblemEditor> {
  final profile = PlayerProfile.instance;
  _Layer _layer = _Layer.background;

  Emblem get emblem => profile.emblem;

  void _update(Emblem Function(Emblem) change) => profile.setEmblem(change(emblem));

  Color get _layerColor => switch (_layer) {
        _Layer.background => emblem.background,
        _Layer.foreground => emblem.foreground,
        _Layer.accent => emblem.accent,
      };

  void _setLayerColor(Color color) => _update((e) => switch (_layer) {
        _Layer.background => e.copyWith(background: color),
        _Layer.foreground => e.copyWith(foreground: color),
        _Layer.accent => e.copyWith(accent: color),
      });

  void _randomise() {
    final random = Random();
    final icons = emblemIcons.keys.toList();
    Color pick() => emblemPalette[random.nextInt(emblemPalette.length)];
    _update((e) => Emblem(
          shape: EmblemShape.values[random.nextInt(EmblemShape.values.length)],
          icon: icons[random.nextInt(icons.length)],
          background: pick(),
          foreground: pick(),
          accent: pick(),
          ring: random.nextDouble() < 0.7,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        final preview = _preview(theme);
        final controls = _controls(theme);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 260, child: preview),
                    const SizedBox(width: 32),
                    Expanded(child: controls),
                  ],
                )
              : Column(children: [preview, const SizedBox(height: 24), controls]),
        );
      }),
    );
  }

  Widget _preview(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
          ),
          child: EmblemWidget(emblem: emblem, size: 180, shadow: true),
        ),
        const SizedBox(height: 16),
        // How it looks on a seat placard
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              EmblemWidget(emblem: emblem, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('At the table',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Text('20', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _randomise,
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Surprise me'),
        ),
      ],
    );
  }

  Widget _controls(ThemeData theme) {
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text.toUpperCase(),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Shape'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final shape in EmblemShape.values)
              _ShapeChip(
                shape: shape,
                emblem: emblem,
                selected: shape == emblem.shape,
                onTap: () => _update((e) => e.copyWith(shape: shape)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        heading('Icon'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final entry in emblemIcons.entries)
              _IconTile(
                icon: entry.value,
                selected: entry.key == emblem.icon,
                onTap: () => _update((e) => e.copyWith(icon: entry.key)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        heading('Colours'),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<_Layer>(
                segments: [
                  ButtonSegment(
                      value: _Layer.background, label: const Text('Shape'), icon: _Swatch(emblem.background)),
                  ButtonSegment(
                      value: _Layer.foreground, label: const Text('Icon'), icon: _Swatch(emblem.foreground)),
                  ButtonSegment(value: _Layer.accent, label: const Text('Ring'), icon: _Swatch(emblem.accent)),
                ],
                selected: {_layer},
                onSelectionChanged: (value) => setState(() => _layer = value.first),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final color in emblemPalette)
              _ColorTile(
                color: color,
                selected: color == _layerColor,
                onTap: () => _setLayerColor(color),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _HslSliders(color: _layerColor, onChanged: _setLayerColor),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ring around the edge'),
          value: emblem.ring,
          onChanged: (value) => _update((e) => e.copyWith(ring: value)),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
        ),
      );
}

class _ShapeChip extends StatelessWidget {
  const _ShapeChip({required this.shape, required this.emblem, required this.selected, required this.onTap});

  final EmblemShape shape;
  final Emblem emblem;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: shape.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.15),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: CustomPaint(
            painter: EmblemPainter(Emblem(
              shape: shape,
              background: theme.colorScheme.onSurface.withValues(alpha: selected ? 0.8 : 0.35),
              accent: theme.colorScheme.primary,
              ring: false,
            )),
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.selected, required this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.15) : null,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(icon, size: 22, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? onColor : Colors.black.withValues(alpha: 0.15), width: selected ? 2.5 : 1),
        ),
        child: selected ? Icon(Icons.check_rounded, size: 16, color: onColor) : null,
      ),
    );
  }
}

/// Hue, saturation and lightness sliders for any colour the palette lacks.
class _HslSliders extends StatelessWidget {
  const _HslSliders({required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final theme = Theme.of(context);
    Widget row(String label, double value, double max, ValueChanged<double> change, {Gradient? gradient}) => Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: theme.textTheme.bodySmall)),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (gradient != null)
                    Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(4)),
                    ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: gradient != null ? Colors.transparent : null,
                      inactiveTrackColor: gradient != null ? Colors.transparent : null,
                    ),
                    child: Slider(value: value.clamp(0, max), min: 0, max: max, onChanged: change),
                  ),
                ],
              ),
            ),
          ],
        );
    return Column(
      children: [
        row(
          'Hue',
          hsl.hue,
          360,
          (v) => onChanged(hsl.withHue(v).withSaturation(max(hsl.saturation, 0.05)).toColor()),
          gradient: LinearGradient(colors: [for (var h = 0; h <= 360; h += 60) HSLColor.fromAHSL(1, h.toDouble(), 1, 0.5).toColor()]),
        ),
        row('Saturation', hsl.saturation, 1, (v) => onChanged(hsl.withSaturation(v).toColor())),
        row('Lightness', hsl.lightness, 1, (v) => onChanged(hsl.withLightness(v).toColor())),
      ],
    );
  }
}
