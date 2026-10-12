import 'dart:io';
import 'package:flutter/material.dart';
import '../controllers/hand_tracking_controller.dart';
import '../../data/services/mediapipe_hand_tracking_service.dart';
import '../../domain/models/gesture.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HandTrackingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = HandTrackingController(MediaPipeHandTrackingService());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatAngle(double? value) => value == null ? '—' : '${value.toStringAsFixed(0)}°';

  Widget _buildGestureCard(BuildContext context, GestureResult result) {
    final reconhecido = result.gesture != Gesture.naoReconhecido;
    final colors = Theme.of(context).colorScheme;
    final angles = result.angles;

    return Card(
      color: reconhecido ? colors.primaryContainer : colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              result.gesture.rotulo,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(result.gesture.id, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              'Indicador ${_formatAngle(angles.indicador)} · Médio ${_formatAngle(angles.medio)}\n'
                  'Anelar ${_formatAngle(angles.anelar)} · Mínimo ${_formatAngle(angles.minimo)}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestos em Foto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _controller.pickImageAndProcess,
              child: const Text('Selecionar Imagem da Galeria'),
            ),
            const SizedBox(height: 24),

            // Área de resultado gerida reativamente
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _controller.state,
                builder: (context, state, _) {
                  if (state == TrackingState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state == TrackingState.error) {
                    return Center(
                      child: Text(
                        _controller.errorMessage.value ?? 'Erro',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (state == TrackingState.success) {
                    final points = _controller.handPoints.value;
                    final imagePath = _controller.selectedImagePath.value;
                    final result = _controller.gestureResult.value;

                    if (points.isEmpty) {
                      return const Center(child: Text('Nenhuma mão detectada na imagem.'));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (imagePath != null)
                          SizedBox(
                            height: 180,
                            child: Image.file(File(imagePath), fit: BoxFit.contain),
                          ),
                        const SizedBox(height: 12),
                        if (result != null) _buildGestureCard(context, result),
                        const SizedBox(height: 12),
                        Text(
                          '${points.length} pontos detectados:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: points.length,
                            itemBuilder: (context, index) {
                              final point = points[index];
                              return ListTile(
                                leading: CircleAvatar(child: Text('${index + 1}')),
                                title: Text('X: ${point.x.toStringAsFixed(3)} | Y: ${point.y.toStringAsFixed(3)}'),
                                subtitle: Text('Z: ${point.z.toStringAsFixed(3)}'),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return const Center(child: Text('Selecione uma imagem para começar o teste.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}