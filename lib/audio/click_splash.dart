import 'package:donut_game/audio/sfx.dart';
import 'package:flutter/material.dart';

/// Makes every ink ripple click: buttons, chips, menu items, list tiles and
/// anything else built on InkWell plays a click the moment it's pressed.
/// Disabled controls don't ripple, so they stay silent.
class ClickSplashFactory extends InteractiveInkFeatureFactory {
  const ClickSplashFactory(this.inner);

  /// The ripple that actually gets drawn.
  final InteractiveInkFeatureFactory inner;

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    SoundEffects.instance.play(Sfx.click);
    return inner.create(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}
