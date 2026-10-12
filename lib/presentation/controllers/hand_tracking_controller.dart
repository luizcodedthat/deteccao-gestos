import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/gesture.dart';
import '../../domain/models/hand_point.dart';
import '../../domain/services/gesture_recognition_service.dart';
import '../../domain/services/i_hand_tracking_service.dart';

enum TrackingState { initial, loading, success, error }

class HandTrackingController {
  final IHandTrackingService _trackingService;
  final GestureRecognitionService _gestureService;
  final ImagePicker _imagePicker;

  final ValueNotifier<TrackingState> state = ValueNotifier(TrackingState.initial);
  final ValueNotifier<List<HandPoint>> handPoints = ValueNotifier([]);
  final ValueNotifier<GestureResult?> gestureResult = ValueNotifier(null);
  final ValueNotifier<String?> selectedImagePath = ValueNotifier(null);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  HandTrackingController(
      this._trackingService, {
        GestureRecognitionService? gestureService,
        ImagePicker? imagePicker,
      })  : _gestureService = gestureService ?? const GestureRecognitionService(),
        _imagePicker = imagePicker ?? ImagePicker();

  Future<void> pickImageAndProcess() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      selectedImagePath.value = image.path;
      state.value = TrackingState.loading;

      final points = await _trackingService.extractHandLandmarks(image.path);
      final size = await _trackingService.getImageSize(image.path);

      handPoints.value = points;
      gestureResult.value = _gestureService.recognize(points, size.width, size.height);
      errorMessage.value = null;
      state.value = TrackingState.success;

    } catch (e) {
      errorMessage.value = e.toString();
      state.value = TrackingState.error;
    }
  }

  void dispose() {
    state.dispose();
    handPoints.dispose();
    gestureResult.dispose();
    selectedImagePath.dispose();
    errorMessage.dispose();
  }
}