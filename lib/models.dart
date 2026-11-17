import 'package:flutter/material.dart';

/// Nivel de urgencia que representa cada estímulo.
enum Urgency { alta, media, baja }

extension UrgencyX on Urgency {
  String get label => switch (this) {
        Urgency.alta => 'Urgente',
        Urgency.media => 'Poco urgente',
        Urgency.baja => 'Nada urgente',
      };

  String get colorName => switch (this) {
        Urgency.alta => 'Rojo',
        Urgency.media => 'Amarillo',
        Urgency.baja => 'Verde',
      };

  Color get color => switch (this) {
        Urgency.alta => const Color(0xFFFF2D2D),
        Urgency.media => const Color(0xFFFFC21A),
        Urgency.baja => const Color(0xFF2EE66B),
      };
}

/// Parámetros de la sesión. Cámbialos aquí si quieres otra duración o cantidad.
class SessionConfig {
  /// Ventana total del test.
  static const sessionDuration = Duration(minutes: 10);

  /// Cantidad de estímulos dentro de la ventana (se reparten entre los 3 colores).
  static const stimuliCount = 6;

  /// Separación mínima entre dos estímulos.
  static const minGap = Duration(seconds: 45);

  /// Si la persona no toca la pantalla en este tiempo, el estímulo se apaga
  /// y queda como "no detectado".
  static const timeout = Duration(seconds: 30);
}

/// Un estímulo disparado y la reacción de la persona.
class Trial {
  Trial({required this.index, required this.urgency, required this.offset});

  final int index;
  final Urgency urgency;

  /// Momento del disparo desde que empezó la sesión.
  final Duration offset;

  /// null = no reaccionó antes del timeout.
  int? reactionMs;

  bool get detected => reactionMs != null;

  static String mmss(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  static const csvHeader = 'estimulo,color,minuto_disparo,tiempo_reaccion_ms,detectado';

  String toCsvRow() => [
        index,
        urgency.colorName.toLowerCase(),
        mmss(offset),
        reactionMs ?? '',
        detected ? 1 : 0,
      ].join(',');
}
