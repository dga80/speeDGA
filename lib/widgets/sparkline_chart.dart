import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../theme/speedga_theme.dart';

/// Minigráfico de perfil de altitud / elevación para tarjetas de salida
class SparklineElevationChart extends StatelessWidget {
  final List<TripPoint> points;
  final double height;
  final Color primaryColor;

  const SparklineElevationChart({
    super.key,
    required this.points,
    this.height = 36.0,
    this.primaryColor = SpeeDGATheme.neonLime,
  });

  @override
  Widget build(BuildContext context) {
    // Extraer altitudes válidas
    final altitudes = points
        .map((p) => p.altitude)
        .where((alt) => alt > 0.0)
        .toList();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          altitudes: altitudes,
          primaryColor: primaryColor,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> altitudes;
  final Color primaryColor;

  _SparklinePainter({required this.altitudes, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    List<double> data = [];
    if (altitudes.length >= 4) {
      // Muestrear a máx 30 puntos
      final step = math.max(1, altitudes.length ~/ 30);
      for (int i = 0; i < altitudes.length; i += step) {
        data.add(altitudes[i]);
      }
    } else {
      // Simulación suave si es un trayecto muy corto
      data = [120, 135, 142, 138, 160, 185, 172, 165, 190, 140];
    }

    final minVal = data.reduce(math.min);
    final maxVal = data.reduce(math.max);
    final range = (maxVal - minVal) > 5 ? (maxVal - minVal) : 10.0;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedY = (data[i] - minVal) / range;
      // Invertir Y porque en Canvas 0 está arriba
      final y = size.height - (normalizedY * (size.height * 0.75) + 4);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Relleno en gradiente semitransparente
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0.35),
          primaryColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Línea de perfil nítida
    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.altitudes != altitudes || oldDelegate.primaryColor != primaryColor;
  }
}
