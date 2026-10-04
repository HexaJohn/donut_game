import 'dart:ui';

/// One marker or eraser stroke on the table. Points and [width] are fractions
/// of the felt, so drawings line up on every screen whatever its size.
class InkStroke {
  InkStroke({
    required this.id,
    required this.author,
    required this.color,
    required this.width,
    required this.erase,
    List<Offset>? points,
  }) : points = points ?? [];

  final String id;
  final String author;

  /// ARGB, as in [Color.toARGB32].
  final int color;

  /// Line width as a fraction of the felt's width.
  final double width;

  /// Rubs out ink drawn before it instead of drawing.
  final bool erase;
  final List<Offset> points;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'color': color,
        'width': width,
        'erase': erase,
        'points': [
          for (final p in points) ...[_round(p.dx), _round(p.dy)]
        ],
      };

  static InkStroke fromJson(Map<String, dynamic> json) {
    final flat = (json['points'] as List? ?? []).cast<num>();
    return InkStroke(
      id: json['id'] ?? '',
      author: json['author'] ?? '',
      color: json['color'] ?? 0xFF000000,
      width: (json['width'] as num? ?? 0.004).toDouble(),
      erase: json['erase'] == true,
      points: [for (var i = 0; i + 1 < flat.length; i += 2) Offset(flat[i].toDouble(), flat[i + 1].toDouble())],
    );
  }

  /// Four decimal places is well under a pixel and keeps updates small.
  static double _round(double v) => (v * 10000).round() / 10000;
}
