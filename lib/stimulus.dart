import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'models.dart';

/// Define cómo "se siente" cada urgencia: color, ritmo de luz y patrón de vibración.
///
/// La luz y la vibración comparten el mismo patrón para que estén sincronizadas:
/// `pattern` alterna [espera, vibra, espera, vibra, ...] en milisegundos y se
/// repite cada `cycle`. Ajusta estos valores para iterar en el testeo.
class StimulusProfile {
  const StimulusProfile({
    required this.color,
    required this.cycle,
    required this.pattern,
    required this.intensities,
    required this.fadeMs,
    required this.floor,
  });

  final Color color;
  final Duration cycle;
  final List<int> pattern;

  /// Intensidad 1–255 por segmento (0 en los segmentos de espera).
  /// Solo se respeta en teléfonos con control de amplitud (la mayoría de Android).
  final List<int> intensities;

  /// 0 = parpadeo seco (estroboscópico). >0 = luz que sube y baja suave.
  final int fadeMs;

  /// Brillo mínimo de la luz entre pulsos (0–1).
  final double floor;

  static StimulusProfile of(Urgency u) => switch (u) {
        // ROJO: doble pulso fuerte y rápido, parpadeo seco. Pensado para interrumpir.
        Urgency.alta => const StimulusProfile(
            color: Color(0xFFFF2D2D),
            cycle: Duration(milliseconds: 900),
            pattern: [0, 180, 120, 180],
            intensities: [0, 255, 0, 255],
            fadeMs: 0,
            floor: 0.0,
          ),
        // AMARILLO: doble pulso medio cada 2 s, luz con transición suave.
        Urgency.media => const StimulusProfile(
            color: Color(0xFFFFC21A),
            cycle: Duration(milliseconds: 2000),
            pattern: [150, 300, 250, 300],
            intensities: [0, 150, 0, 150],
            fadeMs: 180,
            floor: 0.05,
          ),
        // VERDE: un pulso suave cada 4 s, luz que "respira".
        Urgency.baja => const StimulusProfile(
            color: Color(0xFF2EE66B),
            cycle: Duration(milliseconds: 4000),
            pattern: [1200, 600],
            intensities: [0, 70],
            fadeMs: 1200,
            floor: 0.15,
          ),
      };

  /// Brillo (0–1) en el instante `tMs` dentro del ciclo.
  double brightnessAt(double tMs) {
    double v = floor;
    int cursor = 0;
    for (int i = 0; i < pattern.length; i++) {
      final seg = pattern[i];
      if (i.isOdd) {
        final s = cursor.toDouble();
        final e = (cursor + seg).toDouble();
        double b;
        if (fadeMs <= 0) {
          b = (tMs >= s && tMs < e) ? 1 : 0;
        } else if (tMs < s - fadeMs || tMs > e + fadeMs) {
          b = 0;
        } else if (tMs < s) {
          b = 1 - (s - tMs) / fadeMs;
        } else if (tMs <= e) {
          b = 1;
        } else {
          b = 1 - (tMs - e) / fadeMs;
        }
        if (fadeMs > 0) b = Curves.easeInOut.transform(b.clamp(0.0, 1.0));
        v = max(v, floor + (1 - floor) * b);
      }
      cursor += seg;
    }
    return v;
  }
}

/// Controla la vibración en bucle mientras el estímulo está activo.
class StimulusEngine {
  Timer? _timer;
  bool _hasVibrator = false;
  bool _hasAmplitude = false;

  bool get hasVibrator => _hasVibrator;
  bool get hasAmplitude => _hasAmplitude;

  Future<void> init() async {
    try {
      _hasVibrator = await Vibration.hasVibrator() == true;
      _hasAmplitude = await Vibration.hasAmplitudeControl() == true;
    } catch (_) {
      _hasVibrator = false; // p. ej. en web o escritorio
    }
  }

  void start(StimulusProfile p) {
    stop();
    void pulse() {
      if (_hasVibrator) {
        if (_hasAmplitude) {
          Vibration.vibrate(pattern: p.pattern, intensities: p.intensities);
        } else {
          Vibration.vibrate(pattern: p.pattern);
        }
      } else {
        HapticFeedback.heavyImpact();
      }
    }

    pulse();
    _timer = Timer.periodic(p.cycle, (_) => pulse());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_hasVibrator) Vibration.cancel();
  }
}
