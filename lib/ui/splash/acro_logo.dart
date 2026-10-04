import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _mark = 'assets/logos/acro-mark.svg';
const _acro = 'assets/logos/acro-wordmark-acro.svg';
const _bars = 'assets/logos/acro-wordmark-bars.svg';
const _visuals = 'assets/logos/acro-wordmark-visuals.svg';
const _tm = 'assets/logos/acro-wordmark-tm.svg';

/// The wordmark layers share one 1011 x 299 canvas so they stack exactly.
const double _wordmarkAspect = 1011 / 299;

/// Where the bars sit on that canvas, as fractions of its height.
const double _barTop = 139 / 299;
const double _barBottom = 163 / 299;

/// Loads every logo layer into flutter_svg's cache so nothing pops in late.
Future<void> precacheAcroLogo() => Future.wait([
      for (final asset in [_mark, _acro, _bars, _visuals, _tm])
        () {
          final loader = SvgAssetLoader(asset);
          return svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
        }(),
    ]);

/// Total running time of [AcroLogoAnimation].
const Duration acroLogoDuration = Duration(milliseconds: 2400);

/// The Acro Visuals intro: the mark appears, steps back, then the bars draw
/// out from the centre and the words rise and drop out from behind them.
class AcroLogoAnimation extends StatefulWidget {
  const AcroLogoAnimation({super.key, required this.color, this.width = 520});

  final Color color;
  final double width;

  @override
  State<AcroLogoAnimation> createState() => _AcroLogoAnimationState();
}

class _AcroLogoAnimationState extends State<AcroLogoAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: acroLogoDuration)..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progress of [_controller] through [begin]..[end], eased.
  double _phase(double begin, double end, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((_controller.value - begin) / (end - begin)).clamp(0.0, 1.0));

  Widget _layer(String asset) => SvgPicture.asset(
        asset,
        width: widget.width,
        height: widget.width / _wordmarkAspect,
        colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
      );

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = width / _wordmarkAspect;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final markIn = _phase(0, 0.25, Curves.easeOutBack);
        final markOut = _phase(0.32, 0.46, Curves.easeInCubic);
        final bars = _phase(0.4, 0.62);
        final acro = _phase(0.52, 0.78);
        final visuals = _phase(0.58, 0.84);
        final tm = _phase(0.84, 1);

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The mark, centred, before the wordmark builds
              if (markOut < 1)
                Center(
                  child: Opacity(
                    opacity: (markIn.clamp(0.0, 1.0) * (1 - markOut)).toDouble(),
                    child: Transform.scale(
                      scale: (0.8 + 0.2 * markIn) * (1 - 0.15 * markOut),
                      child: SvgPicture.asset(
                        _mark,
                        height: height * 0.9,
                        colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              // Bars draw outwards from the middle
              ClipRect(clipper: _CentreWipe(bars), child: _layer(_bars)),
              // ACRO rises up out of the bar line
              ClipRect(
                clipper: const _Band(0, _barTop),
                child: Transform.translate(
                  offset: Offset(0, (1 - acro) * height * _barTop),
                  child: _layer(_acro),
                ),
              ),
              // VISUALS drops down out of it
              ClipRect(
                clipper: const _Band(_barBottom, 1),
                child: Transform.translate(
                  offset: Offset(0, -(1 - visuals) * height * (1 - _barBottom)),
                  child: _layer(_visuals),
                ),
              ),
              Opacity(opacity: tm, child: _layer(_tm)),
            ],
          ),
        );
      },
    );
  }
}

/// Clips to a horizontal band between [top] and [bottom] (fractions of height).
class _Band extends CustomClipper<Rect> {
  const _Band(this.top, this.bottom);

  final double top;
  final double bottom;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-size.width, size.height * top, size.width * 2, size.height * bottom);

  @override
  bool shouldReclip(_Band oldClipper) => oldClipper.top != top || oldClipper.bottom != bottom;
}

/// Reveals from the centre outwards as [t] goes from 0 to 1.
class _CentreWipe extends CustomClipper<Rect> {
  const _CentreWipe(this.t);

  final double t;

  @override
  Rect getClip(Size size) {
    final half = size.width / 2 * t;
    return Rect.fromLTRB(size.width / 2 - half, 0, size.width / 2 + half, size.height);
  }

  @override
  bool shouldReclip(_CentreWipe oldClipper) => oldClipper.t != t;
}
