import 'package:flutter/services.dart';
import '../../domain/models/hand_point.dart';
import '../../domain/models/image_size.dart';
import '../../domain/services/i_hand_tracking_service.dart';

class MediaPipeHandTrackingService implements IHandTrackingService {
  static const MethodChannel _channel = MethodChannel('br.edu.ifpe.mobile.mediapipe/hand_tracking');

  @override
  Future<List<HandPoint>> extractHandLandmarks(String imagePath) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod(
        'extractLandmarks',
        {'imagePath': imagePath},
      );

      if (result == null || result.isEmpty) {
        return [];
      }

      return result.map((pointData) => HandPoint.fromMap(pointData as Map<dynamic, dynamic>)).toList();
    } on PlatformException catch (e) {
      throw Exception('Falha ao processar imagem no MediaPipe: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado na extração dos pontos: $e');
    }
  }

  @override
  Future<ImageSize> getImageSize(String imagePath) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'getImageSize',
        {'imagePath': imagePath},
      );

      if (result == null) {
        throw Exception('Resposta vazia ao ler as dimensões da imagem.');
      }

      return ImageSize.fromMap(result);
    } on PlatformException catch (e) {
      throw Exception('Falha ao ler as dimensões da imagem: ${e.message}');
    }
  }
}