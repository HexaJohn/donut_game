import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paints [painter] into an image once and shows that, so a busy static scene
/// (a backdrop, a felt texture) costs one texture draw a frame instead of
/// replaying hundreds of shapes. Phones redraw the whole screen on every
/// frame of any animation, so this is most of the cost of each frame.
///
/// Repaints when [cacheKey] or the size changes. Size changes that come in a
/// burst, like a panel sliding open, stretch the old image until they settle.
class RasterizedPaint extends StatefulWidget {
  const RasterizedPaint({super.key, required this.painter, required this.cacheKey});

  final CustomPainter painter;

  /// Everything the picture depends on besides its size.
  final Object cacheKey;

  @override
  State<RasterizedPaint> createState() => _RasterizedPaintState();
}

class _RasterizedPaintState extends State<RasterizedPaint> {
  static const _settle = Duration(milliseconds: 250);

  ui.Image? _image;
  Size? _size;
  double? _ratio;
  Object? _key;
  DateTime _paintedAt = DateTime(0);
  Timer? _later;

  @override
  void dispose() {
    _later?.cancel();
    _image?.dispose();
    super.dispose();
  }

  void _paint(Size size, double ratio) {
    _later?.cancel();
    _size = size;
    _ratio = ratio;
    _key = widget.cacheKey;
    _paintedAt = DateTime.now();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    widget.painter.paint(canvas, size);
    final picture = recorder.endRecording();
    final image = picture.toImageSync((size.width * ratio).ceil(), (size.height * ratio).ceil());
    picture.dispose();
    _image?.dispose();
    _image = image;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      if (size.isEmpty || !size.isFinite) return const SizedBox.expand();
      final stale = _image == null || _key != widget.cacheKey || _ratio != ratio;
      if (stale) {
        _paint(size, ratio);
      } else if (size != _size) {
        if (DateTime.now().difference(_paintedAt) >= _settle) {
          _paint(size, ratio);
        } else {
          // Still resizing: stretch what we have, repaint once it settles
          _later?.cancel();
          _later = Timer(_settle, () {
            if (mounted) setState(() => _size = null);
          });
        }
      }
      return RawImage(image: _image, width: size.width, height: size.height, fit: BoxFit.fill);
    });
  }
}
