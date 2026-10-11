class HandPoint {
  final double x;
  final double y;
  final double z;

  const HandPoint({
    required this.x,
    required this.y,
    required this.z,
  });

  factory HandPoint.fromMap(Map<dynamic, dynamic> map) {
    return HandPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: (map['z'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'HandPoint(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)})';
}