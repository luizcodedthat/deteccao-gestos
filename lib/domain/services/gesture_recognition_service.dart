import 'dart:math' as math;

import '../models/gesture.dart';
import '../models/hand_point.dart';

const double kLimiarGestos = 170.0;

class GestureRecognitionService {
  final double limiar;

  const GestureRecognitionService({this.limiar = kLimiarGestos});

  static const List<List<int>> _trincas = [
    [5, 6, 7],
    [9, 10, 11],
    [13, 14, 15],
    [17, 18, 19],
  ];

  GestureResult recognize(List<HandPoint> pontos, int largura, int altura) {
    if (pontos.length != 21 || largura <= 0 || altura <= 0) {
      return const GestureResult(
        gesture: Gesture.naoReconhecido,
        angles: HandAngles(),
      );
    }
    final angulos = extractAngles(pontos, largura, altura);
    return GestureResult(gesture: classifyAngles(angulos), angles: angulos);
  }

  HandAngles extractAngles(List<HandPoint> pontos, int largura, int altura) {
    final a = _trincas
        .map((t) => calculateAngle(pontos[t[0]], pontos[t[1]], pontos[t[2]], largura, altura))
        .toList();
    return HandAngles(indicador: a[0], medio: a[1], anelar: a[2], minimo: a[3]);
  }

  static double? calculateAngle(
    HandPoint a,
    HandPoint b,
    HandPoint c,
    int largura,
    int altura,
  ) {
    final v1x = (a.x - b.x) * largura;
    final v1y = (a.y - b.y) * altura;
    final v2x = (c.x - b.x) * largura;
    final v2y = (c.y - b.y) * altura;

    final den = math.sqrt(v1x * v1x + v1y * v1y) * math.sqrt(v2x * v2x + v2y * v2y);
    if (den < 1e-6) return null;

    final cos = ((v1x * v2x + v1y * v2y) / den).clamp(-1.0, 1.0).toDouble();
    return math.acos(cos) * 180.0 / math.pi;
  }

  Gesture classifyAngles(HandAngles angulos) {
    final valores = angulos.valores;
    if (valores.any((v) => v == null || v.isNaN || v.isInfinite)) {
      return Gesture.naoReconhecido;
    }

    final estendido = valores.map((v) => v! >= limiar).toList();
    final indicador = estendido[0];
    final medio = estendido[1];
    final anelar = estendido[2];
    final minimo = estendido[3];

    if (indicador && medio && anelar && minimo) return Gesture.palmaAberta;
    if (indicador && medio && !anelar && !minimo) return Gesture.paz;
    if (!indicador && !medio && !anelar && !minimo) return Gesture.punhoFechado;
    return Gesture.naoReconhecido;
  }
}
