import 'dart:math';

import 'package:flutter/material.dart';

class SeismicWave extends StatefulWidget {
  final bool active;
  final Color color;
  final double height;
  const SeismicWave({
    super.key,
    required this.active,
    required this.color,
    this.height = 120,
  });

  @override
  State<SeismicWave> createState() => _SeismicWaveState();
}

class _SeismicWaveState extends State<SeismicWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _WavePainter(
            t: _c.value,
            active: widget.active,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  final bool active;
  final Color color;
  _WavePainter({required this.t, required this.active, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = active ? 3 : 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final amp = active ? size.height * 0.42 : size.height * 0.10;
    final phase = t * 2 * pi;

    for (double x = 0; x <= size.width; x += 2) {
      final n = x / size.width;
      double y = sin(n * 6 * pi + phase) * amp * 0.5;
      if (active) {
        y += sin(n * 22 * pi - phase * 3) * amp * 0.5;
        y += sin(n * 40 * pi + phase * 2) * amp * 0.2;
      } else {
        y += sin(n * 3 * pi - phase) * amp * 0.4;
      }
      final taper = sin(n * pi);
      y *= taper;
      if (x == 0) {
        path.moveTo(x, mid + y);
      } else {
        path.lineTo(x, mid + y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.t != t || old.active != active || old.color != color;
}
