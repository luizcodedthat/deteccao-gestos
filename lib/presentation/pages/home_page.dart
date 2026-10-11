import 'dart:io';
import 'package:flutter/material.dart';
import '../controllers/hand_tracking_controller.dart';
import '../../data/services/mediapipe_hand_tracking_service.dart';

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
    // Injeção de dependência manual simples para a PoC
    _controller = HandTrackingController(MediaPipeHandTrackingService());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MediaPipe Hand Tracking PoC')),
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

                    if (points.isEmpty) {
                      return const Center(child: Text('Nenhuma mão detectada na imagem.'));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${points.length} pontos detectados:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
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