import '../models/hand_point.dart';
import '../models/image_size.dart';

abstract class IHandTrackingService {
  Future<List<HandPoint>> extractHandLandmarks(String imagePath);

  Future<ImageSize> getImageSize(String imagePath);
}
