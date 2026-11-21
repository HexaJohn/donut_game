import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Hand-made art that takes the place of the code-drawn (AI-made) art.
///
/// Each file sits in art_replacement/ at the path test/art_export_test.dart
/// renders the painting it replaces to, as a .png, .jpg, .jpeg or .webp:
/// art_replacement/tables/oak.jpg is drawn instead of the oak table's
/// painter. Art with no file keeps its painter.
///
/// Flutter only bundles the folders pubspec.yaml lists, one line per folder
/// (subfolders aren't included), so a new folder needs its own line;
/// test/art_replacement_test.dart checks none is missing.
class ArtReplacement {
  ArtReplacement._();

  static const folder = 'art_replacement';
  static const types = {'png', 'jpg', 'jpeg', 'webp'};

  /// Asset path by art name ('tables/oak').
  static Map<String, String> _assets = const {};

  /// Finds the replacements bundled with the app. Before anything is drawn.
  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      use(manifest.listAssets());
    } catch (e) {
      debugPrint('Art replacements not loaded: $e');
    }
  }

  /// Takes these asset paths as the bundled files.
  @visibleForTesting
  static void use(Iterable<String> assets) {
    _assets = {
      for (final path in assets)
        if (path.startsWith('$folder/') && types.contains(path.split('.').last.toLowerCase()))
          path.substring(folder.length + 1, path.lastIndexOf('.')): path,
    };
  }

  /// The asset that replaces [name], or null to keep drawing it.
  static String? find(String name) => _assets[name];

  /// The first replacement whose name starts with [prefix], for art whose
  /// file names carry a readable label after a fixed part.
  static String? findStartingWith(String prefix) {
    for (final MapEntry(:key, :value) in _assets.entries) {
      if (key.startsWith(prefix)) return value;
    }
    return null;
  }
}

/// The id without its catalog kind: 'env.oak' is 'oak'.
String artSlug(String id) => id.replaceFirst(RegExp(r'^\w+\.'), '');

/// An art replacement, decoded at about the size it's shown so a large photo
/// doesn't sit in memory at full resolution.
class ReplacedArt extends StatelessWidget {
  const ReplacedArt(this.asset, {super.key, this.fit = BoxFit.cover, this.tint, this.opacity = 1});

  final String asset;
  final BoxFit fit;

  /// Paints every pixel this colour, keeping the art's shape and
  /// transparency: for single-colour art the game colours itself (suits,
  /// rank badges).
  final Color? tint;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
      final h = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
      // The longer side, so a cover crop still has the pixels; in steps, so
      // resizing the window doesn't decode it again at every size
      final longest = (w > h ? w : h) * ratio;
      final decode = longest <= 0 ? null : ((longest / 256).ceil() * 256).clamp(256, 4096);
      return Opacity(
        opacity: opacity,
        child: Image.asset(
          asset,
          fit: fit,
          width: w > 0 ? w : null,
          height: h > 0 ? h : null,
          cacheWidth: decode,
          color: tint,
          colorBlendMode: tint == null ? null : BlendMode.srcIn,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        ),
      );
    });
  }
}
