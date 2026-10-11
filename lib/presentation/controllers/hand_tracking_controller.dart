import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/hand_point.dart';
import '../../domain/services/i_hand_tracking_service.dart';

enum TrackingState { initial, loading, success, error }

class HandTrackingController {
  final IHandTrackingService _trackingService;
  final ImagePicker _imagePicker;

  final ValueNotifier<TrackingState> state = ValueNotifier(TrackingState.initial);
  final ValueNotifier<List<HandPoint>> handPoints = ValueNotifier([]);
  final ValueNotifier<String?> selectedImagePath = ValueNotifier(null);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  HandTrackingController(this._trackingService, {ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  Future<void> pickImageAndProcess() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (image == null) return; // Usuário cancelou a seleção

      selectedImagePath.value = image.path;
      state.value = TrackingState.loading;

      final points = await _trackingService.extractHandLandmarks(image.path);

      handPoints.value = points;
      state.value = TrackingState.success;

    } catch (e) {
      errorMessage.value = e.toString();
      state.value = TrackingState.error;
    }
  }

  void dispose() {
    state.dispose();
    handPoints.dispose();
    selectedImagePath.dispose();
    errorMessage.dispose();
  }
}