import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models.dart';
import '../stimulus.dart';
import '../widgets/wearable_glow.dart';
import 'results_screen.dart';

/// El teléfono hace de wearable durante la ventana de 10 minutos.
///
/// - En reposo la pantalla queda negra.
/// - En momentos aleatorios se dispara un estímulo (rojo, amarillo o verde)
///   con su luz y su patrón de vibración.
/// - Al tocar la pantalla se apaga el estímulo y se guarda el tiempo de reacción.
/// - Mantener presionada la esquina superior derecha termina la sesión antes.
class WearableScreen extends StatefulWidget {
  const WearableScreen({super.key});

  @override
  State<WearableScreen> createState() => _WearableScreenState();
}

class _WearableScreenState extends State<WearableScreen> {
  final _engine = StimulusEngine();
  final _rand = Random();
  final _session = Stopwatch();
  final _reaction = Stopwatch();
  final List<Trial> _trials = [];
  final List<Timer> _timers = [];

  Trial? _active;
  Timer? _timeoutTimer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _engine.init().then((_) {
      if (mounted) _start();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timeoutTimer?.cancel();
    _engine.stop();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _start() {
    final colors = _randomColors();
    final times = _randomTimes();
    _session.start();
    for (int i = 0; i < times.length; i++) {
      _timers.add(Timer(times[i], () => _fire(i + 1, colors[i], times[i])));
    }
    // Fin de la sesión al cumplirse los 10 minutos.
    _timers.add(Timer(SessionConfig.sessionDuration, _finish));
  }

  /// Reparte los estímulos en partes iguales entre rojo/amarillo/verde y los baraja.
  List<Urgency> _randomColors() => List.generate(
        SessionConfig.stimuliCount,
        (i) => Urgency.values[i % Urgency.values.length],
      )..shuffle(_rand);

  /// Momentos aleatorios dentro de la ventana, respetando una separación mínima
  /// y dejando margen al final para que el último estímulo alcance a terminar.
  List<Duration> _randomTimes() {
    const n = SessionConfig.stimuliCount;
    const startMargin = 15; // segundos para que la persona se acomode
    final total = SessionConfig.sessionDuration.inSeconds;
    final gap = SessionConfig.minGap.inSeconds;
    final end = total - SessionConfig.timeout.inSeconds;
    final free = max(0, end - startMargin - (n - 1) * gap);

    final base = List.generate(n, (_) => _rand.nextInt(free + 1))..sort();
    return [
      for (int i = 0; i < n; i++) Duration(seconds: startMargin + base[i] + i * gap),
    ];
  }

  void _fire(int index, Urgency u, Duration offset) {
    if (!mounted || _finished) return;
    if (_active != null) _end(detected: false); // seguridad, no debería pasar

    _active = Trial(index: index, urgency: u, offset: offset);
    _engine.start(StimulusProfile.of(u));
    _reaction
      ..reset()
      ..start();
    _timeoutTimer = Timer(SessionConfig.timeout, () => _end(detected: false));
    setState(() {});
  }

  void _end({required bool detected}) {
    final t = _active;
    if (t == null) return;
    _reaction.stop();
    _timeoutTimer?.cancel();
    _engine.stop();
    t.reactionMs = detected ? _reaction.elapsedMilliseconds : null;
    _trials.add(t);
    _active = null;
    if (mounted) setState(() {});
  }

  void _finish() {
    if (_finished || !mounted) return;
    _end(detected: false);
    _finished = true;
    for (final t in _timers) {
      t.cancel();
    }
    _session.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(trials: _trials, elapsed: _session.elapsed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return PopScope(
      canPop: false, // evita salir por accidente con el gesto "atrás"
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: active != null ? (_) => _end(detected: true) : null,
              child: WearableGlow(
                profile: active == null ? null : StimulusProfile.of(active.urgency),
              ),
            ),
            // Esquina oculta: mantener presionado para terminar antes.
            Positioned(
              top: 0,
              right: 0,
              width: 80,
              height: 80,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: _finish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
