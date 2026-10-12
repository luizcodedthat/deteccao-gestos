import 'package:flutter_test/flutter_test.dart';

import '../lib/domain/models/gesture.dart';
import '../lib/domain/models/hand_point.dart';
import '../lib/domain/services/gesture_recognition_service.dart';

HandPoint p(double x, double y) => HandPoint(x: x, y: y, z: 0);

/// 21 pontos; cada dedo recebe (A, B, C) com o ângulo em B dado em [estendido].
List<HandPoint> mao(List<bool> estendido) {
  final pts = List<HandPoint>.generate(21, (i) => p(0.5, 0.9 - 0.01 * i));
  const trincas = [
    [5, 6, 7],
    [9, 10, 11],
    [13, 14, 15],
    [17, 18, 19],
  ];
  for (var k = 0; k < 4; k++) {
    final x = 0.3 + 0.1 * k;
    pts[trincas[k][0]] = p(x, 0.6);
    pts[trincas[k][1]] = p(x, 0.5);
    // reto (180°) ou dobrado em 90°
    pts[trincas[k][2]] = estendido[k] ? p(x, 0.4) : p(x + 0.08, 0.5);
  }
  return pts;
}

void main() {
  const servico = GestureRecognitionService();
  const l = kLimiarGestos;

  group('calculateAngle', () {
    test('segmentos opostos dão 180°', () {
      final a = GestureRecognitionService.calculateAngle(p(0, 0), p(0.5, 0), p(1, 0), 100, 100);
      expect(a, closeTo(180.0, 1e-6));
    });

    test('segmentos perpendiculares dão 90°', () {
      final a = GestureRecognitionService.calculateAngle(p(0.5, 0), p(0.5, 0.5), p(1, 0.5), 100, 100);
      expect(a, closeTo(90.0, 1e-6));
    });

    test('corrige a proporção da imagem (x * largura, y * altura)', () {
      final quadrada = GestureRecognitionService.calculateAngle(p(0, 0), p(0.5, 0.5), p(1, 0), 100, 100);
      final larga = GestureRecognitionService.calculateAngle(p(0, 0), p(0.5, 0.5), p(1, 0), 200, 100);
      expect(quadrada, closeTo(90.0, 1e-6));
      expect(larga, closeTo(126.8699, 1e-3));
    });

    test('pontos coincidentes devolvem null', () {
      final a = GestureRecognitionService.calculateAngle(p(0.5, 0.5), p(0.5, 0.5), p(1, 1), 100, 100);
      expect(a, isNull);
    });
  });

  group('classifyAngles (casos do contrato)', () {
    Gesture f(List<double?> a) => servico.classifyAngles(
      HandAngles(indicador: a[0], medio: a[1], anelar: a[2], minimo: a[3]),
    );

    test('4 dedos estendidos', () => expect(f([l + 25, l + 25, l + 25, l + 25]), Gesture.palmaAberta));
    test('4 dedos dobrados', () => expect(f([l - 40, l - 40, l - 40, l - 40]), Gesture.punhoFechado));
    test('indicador e médio estendidos', () => expect(f([l + 25, l + 25, l - 40, l - 40]), Gesture.paz));
    test('só indicador estendido', () => expect(f([l + 25, l - 40, l - 40, l - 40]), Gesture.naoReconhecido));
    test('anelar e mínimo estendidos', () => expect(f([l - 40, l - 40, l + 25, l + 25]), Gesture.naoReconhecido));
    test('exatamente no limiar conta como estendido', () => expect(f([l, l, l, l]), Gesture.palmaAberta));
    test('ângulo ausente', () => expect(f([l + 25, l + 25, l + 25, null]), Gesture.naoReconhecido));
    test('sem mão', () => expect(f([null, null, null, null]), Gesture.naoReconhecido));
  });

  group('recognize (landmarks → gesto)', () {
    test('palma aberta', () {
      expect(servico.recognize(mao([true, true, true, true]), 100, 100).gesture, Gesture.palmaAberta);
    });

    test('punho fechado', () {
      expect(servico.recognize(mao([false, false, false, false]), 100, 100).gesture, Gesture.punhoFechado);
    });

    test('paz', () {
      expect(servico.recognize(mao([true, true, false, false]), 100, 100).gesture, Gesture.paz);
    });

    test('lista vazia (sem mão) é não reconhecido', () {
      expect(servico.recognize(const [], 100, 100).gesture, Gesture.naoReconhecido);
    });

    test('dimensões inválidas são não reconhecido', () {
      expect(servico.recognize(mao([true, true, true, true]), 0, 100).gesture, Gesture.naoReconhecido);
    });
  });
}