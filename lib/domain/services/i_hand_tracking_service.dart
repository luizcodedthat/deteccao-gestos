import '../models/hand_point.dart';

abstract class IHandTrackingService {

  Future<List<HandPoint>> extractHandLandmarks(String imagePath);
}