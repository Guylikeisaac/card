import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Slowly drifting vertical light beams — the SyncUp "curtain" backdrop.
class CurtainBackground extends StatefulWidget {
  const CurtainBackground({super.key});

  @override
  State<CurtainBackground> createState() => _CurtainBackgroundState();
}

class _CurtainBackgroundState extends State<CurtainBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 20))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(painter: _CurtainPainter(_c), size: Size.infinite),
      );
}

class _Beam {
  const _Beam(this.x, this.w, this.alpha, this.phase, this.sway, this.len);
  final double x, w, alpha, phase, sway, len;
}

class _CurtainPainter extends CustomPainter {
  _CurtainPainter(this.anim) : super(repaint: anim);
  final Animation<double> anim;

  static const _beams = [
    _Beam(0.06, 0.20, 0.08, 0.0, 0.010, 1.0),
    _Beam(0.28, 0.10, 0.14, 1.3, 0.016, 0.9),
    _Beam(0.45, 0.06, 0.22, 2.1, 0.010, 0.8),
    _Beam(0.55, 0.32, 0.05, 5.0, 0.020, 1.0),
    _Beam(0.64, 0.14, 0.11, 0.7, 0.020, 1.0),
    _Beam(0.79, 0.08, 0.26, 2.8, 0.012, 0.85),
    _Beam(0.92, 0.16, 0.14, 4.0, 0.015, 1.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E0F12), Color(0xFF07080A), Color(0xFF050506)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    final t = anim.value * 2 * math.pi;
    for (final b in _beams) {
      final x = b.x * size.width + math.sin(t + b.phase) * b.sway * size.width;
      final w = b.w * size.width;
      final r = Rect.fromLTWH(x - w / 2, 0, w, size.height * b.len);
      final a = b.alpha * (0.7 + 0.3 * math.sin(t * 2 + b.phase));
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(colors: [
            const Color(0x00A3A6AC),
            const Color(0xFFA3A6AC).withValues(alpha: a),
            const Color(0x00A3A6AC),
          ]).createShader(r),
      );
    }

    // Beams fade out towards the floor.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF050506).withValues(alpha: 0.6),
            const Color(0xFF050506),
          ],
          stops: const [0.2, 0.6, 1],
        ).createShader(rect),
    );
    // Vignette.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CurtainPainter old) => false;
}
