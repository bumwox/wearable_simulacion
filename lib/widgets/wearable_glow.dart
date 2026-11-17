import 'package:flutter/material.dart';

import '../stimulus.dart';

/// Representación visual del wearable: un dispositivo circular con anillo LED
/// y un halo de luz que llena la pantalla (simula la luz emitida en el pecho).
class WearableGlow extends StatefulWidget {
  const WearableGlow({
    super.key,
    required this.profile,
    this.showLight = true,
    this.showDevice = true,
  });

  /// null = wearable apagado / en reposo.
  final StimulusProfile? profile;
  final bool showLight;

  /// Dibuja el dispositivo al centro. Si es false, solo queda el halo de color.
  final bool showDevice;

  @override
  State<WearableGlow> createState() => _WearableGlowState();
}

class _WearableGlowState extends State<WearableGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant WearableGlow old) {
    super.didUpdateWidget(old);
    if (old.profile != widget.profile || old.showLight != widget.showLight) {
      _sync();
    }
  }

  void _sync() {
    final p = widget.profile;
    if (p != null && widget.showLight) {
      _c.duration = p.cycle;
      _c
        ..value = 0
        ..repeat();
    } else {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = widget.profile;
        double b = 0.0;
        Color color = const Color(0xFF3A3A3A);
        if (p != null && widget.showLight) {
          b = p.brightnessAt(_c.value * p.cycle.inMilliseconds);
          color = p.color;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            // Halo ambiental
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.0,
                  colors: [
                    color.withValues(alpha: 0.75 * b),
                    color.withValues(alpha: 0.25 * b),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            if (widget.showDevice) Center(child: _device(color, b)),
          ],
        );
      },
    );
  }

  Widget _device(Color color, double b) {
    const size = 170.0;
    final ring = Color.lerp(const Color(0xFF2A2A2A), color, b)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF151515),
        border: Border.all(color: ring, width: 12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.9 * b),
            blurRadius: 20 + 60 * b,
            spreadRadius: 4 + 20 * b,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(const Color(0xFF2A2A2A), Colors.white, b * 0.8),
          ),
        ),
      ),
    );
  }
}
