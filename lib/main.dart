import 'package:flutter/material.dart';
import 'presentation/pages/home_page.dart';

void main() {
  runApp(const MediaPipePoCApp());
}

class MediaPipePoCApp extends StatelessWidget {
  const MediaPipePoCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaPipe PoC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}