import 'package:flutter/services.dart';
import '../../domain/models/hand_point.dart';
import '../../domain/services/i_hand_tracking_service.dart';

class MediaPipeHandTrackingService implements IHandTrackingService {
  // Canal de comunicação com o código nativo (Kotlin/Swift) onde o MediaPipe estará rodando
  static const MethodChannel _channel = MethodChannel('br.edu.ifpe.mobile.mediapipe/hand_tracking');

  @override
  Future<List<HandPoint>> extractHandLandmarks(String imagePath) async {
    try {
      // Chama o método nativo passando o caminho da imagem selecionada
      final List<dynamic>? result = await _channel.invokeMethod(
        'extractLandmarks',
        {'imagePath': imagePath},
      );

      if (result == null || result.isEmpty) {
        return [];
      }

      // Mapeia o retorno nativo para a nossa entidade de domínio
      return result.map((pointData) => HandPoint.fromMap(pointData as Map<dynamic, dynamic>)).toList();
    } on PlatformException catch (e) {
      throw Exception('Falha ao processar imagem no MediaPipe: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado na extração dos pontos: $e');
    }
  }
}