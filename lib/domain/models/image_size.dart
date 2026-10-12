class ImageSize {
  final int width;
  final int height;

  const ImageSize({required this.width, required this.height});

  factory ImageSize.fromMap(Map<dynamic, dynamic> map) {
    return ImageSize(
      width: (map['width'] as num).toInt(),
      height: (map['height'] as num).toInt(),
    );
  }

  @override
  String toString() => 'ImageSize($width x $height)';
}
