/// A shot in the table. [x] and [y] run 0..1 across the felt, so a hole lands
/// in the same spot on every screen whatever its size.
class BulletHole {
  const BulletHole(this.x, this.y, {required this.shooter, required this.seed});

  final double x;
  final double y;
  final String shooter;

  /// Varies the crack pattern and angle, so holes don't all look alike.
  final int seed;

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'shooter': shooter, 'seed': seed};

  static BulletHole fromJson(Map<String, dynamic> json) => BulletHole(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        shooter: json['shooter'] ?? '',
        seed: json['seed'] ?? 0,
      );

  @override
  bool operator ==(Object other) => other is BulletHole && other.seed == seed && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y, seed);
}
