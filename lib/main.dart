import 'package:flutter/material.dart';

import 'models.dart';
import 'screens/wearable_screen.dart';

void main() => runApp(const WearableSimApp());

class WearableSimApp extends StatelessWidget {
  const WearableSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wearable Sim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6E9C7F),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const StartScreen(),
    );
  }
}

/// Pantalla inicial: un solo botón. Al presionar, el teléfono pasa a ser el wearable.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final min = SessionConfig.sessionDuration.inMinutes;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.sensors, size: 56, color: Colors.white38),
              const SizedBox(height: 24),
              Text(
                'Simulador de wearable',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Durante $min minutos el wearable vibrará y se iluminará '
                '${SessionConfig.stimuliCount} veces en momentos aleatorios.\n\n'
                'Toca la pantalla apenas notes un estímulo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, height: 1.4),
              ),
              const SizedBox(height: 40),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WearableScreen()),
                ),
                child: const Text('Iniciar ($min min)'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Brillo y vibración al máximo · "No molestar" desactivado\n'
                'Para terminar antes: mantén presionada la esquina superior derecha',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
