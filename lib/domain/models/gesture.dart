enum Gesture {
  palmaAberta('palma_aberta', 'Palma aberta'),
  punhoFechado('punho_fechado', 'Punho fechado'),
  paz('paz', 'Paz'),
  naoReconhecido('nao_reconhecido', 'Gesto não reconhecido');

  const Gesture(this.id, this.rotulo);

  final String id;

  final String rotulo;
}

class HandAngles {
  final double? indicador;
  final double? medio;
  final double? anelar;
  final double? minimo;

  const HandAngles({this.indicador, this.medio, this.anelar, this.minimo});

  List<double?> get valores => [indicador, medio, anelar, minimo];
}

class GestureResult {
  final Gesture gesture;
  final HandAngles angles;

  const GestureResult({required this.gesture, required this.angles});
}
