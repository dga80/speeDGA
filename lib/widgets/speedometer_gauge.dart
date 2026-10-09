import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/speedga_theme.dart';

class SpeedometerGauge extends StatelessWidget {
  final double currentSpeed;
  final double maxSpeed;
  final double? avgSpeed;
  final double maxScale; // por defecto 60 km/h

  const SpeedometerGauge({
    super.key,
    required this.currentSpeed,
    required this.maxSpeed,
    this.avgSpeed,
    this.maxScale = 60.0,
  });

  String _getZoneName(double speed) {
    if (speed < 0.8) return 'DETENIDO';
    if (speed < 18.0) return 'ZONA RECUPERACIÓN';
    if (speed < 30.0) return 'ZONA RESISTENCIA';
    if (speed < 42.0) return 'ZONA RITMO / TEMPO';
    if (speed < 50.0) return 'ZONA UMBRAL';
    return 'ZONA ANAERÓBICA';
  }

  Color _getZoneColor(double speed) {
    if (speed < 0.8) return SpeeDGATheme.textMuted;
    if (speed < 18.0) return SpeeDGATheme.aeroCyan;
    if (speed < 30.0) return SpeeDGATheme.neonLime;
    if (speed < 42.0) return SpeeDGATheme.electricCyan;
    if (speed < 50.0) return SpeeDGATheme.warningAmber;
    return SpeeDGATheme.pulseRed;
  }

  @override
  Widget build(BuildContext context) {
    final double safeSpeed = currentSpeed.clamp(0.0, 120.0);
    final double progress = (safeSpeed / maxScale).clamp(0.0, 1.0);
    final zoneName = _getZoneName(safeSpeed);
    final zoneColor = _getZoneColor(safeSpeed);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(constraints.maxWidth * 0.85, 310.0);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Arco visual de fondo y progreso neon
              CustomPaint(
                size: Size(size, size),
                painter: _GaugeArcPainter(
                  progress: progress,
                  accentColor: zoneColor,
                ),
              ),

              // 2. Etiqueta de Zona de Rendimiento superior
              Positioned(
                top: size * 0.12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: SpeeDGATheme.darkCard.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SpeeDGATheme.darkBorder, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: zoneColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        zoneName,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: zoneColor,
                          fontFamily: SpeeDGATheme.fontJetBrainsMono,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Dígitos gigantes de velocidad central
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    safeSpeed.toStringAsFixed(1),
                    style: TextStyle(
                      fontFamily: SpeeDGATheme.fontSpaceGrotesk,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w900,
                      color: SpeeDGATheme.neonLime,
                      letterSpacing: -2.5,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "KM / H",
                        style: TextStyle(
                          fontFamily: SpeeDGATheme.fontJetBrainsMono,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.5,
                          color: SpeeDGATheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: SpeeDGATheme.darkCardElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: SpeeDGATheme.darkBorder),
                        ),
                        child: const Text(
                          "GPS",
                          style: TextStyle(
                            fontFamily: SpeeDGATheme.fontJetBrainsMono,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: SpeeDGATheme.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 4. Indicador inferior de velocidad máxima
              Positioned(
                bottom: size * 0.10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: SpeeDGATheme.darkCard.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SpeeDGATheme.darkBorder.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "MÁX: ",
                        style: TextStyle(
                          fontFamily: SpeeDGATheme.fontJetBrainsMono,
                          fontSize: 10,
                          color: SpeeDGATheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${maxSpeed.toStringAsFixed(1)} km/h",
                        style: const TextStyle(
                          fontFamily: SpeeDGATheme.fontSpaceGrotesk,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: SpeeDGATheme.textPrimary,
                        ),
                      ),
                      if (avgSpeed != null && avgSpeed! > 1.0) ...[
                        const Text(
                          "  |  MED: ",
                          style: TextStyle(
                            fontFamily: SpeeDGATheme.fontJetBrainsMono,
                            fontSize: 10,
                            color: SpeeDGATheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${avgSpeed!.toStringAsFixed(1)}",
                          style: const TextStyle(
                            fontFamily: SpeeDGATheme.fontSpaceGrotesk,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: SpeeDGATheme.aeroCyan,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugeArcPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _GaugeArcPainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Ángulo del arco (250 grados)
    const startAngle = 145 * math.pi / 180;
    const sweepAngle = 250 * math.pi / 180;

    // 1. Pista de fondo oscura
    final bgPaint = Paint()
      ..color = const Color(0xFF14191E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // 2. Marcas o ticks sutiles en la circunferencia interior
    final tickPaint = Paint()
      ..color = const Color(0xFF222B38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 20; i++) {
      final angle = startAngle + (sweepAngle * (i / 20));
      final innerRadius = radius - 14;
      final outerRadius = radius - 9;
      final p1 = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    if (progress <= 0.005) return;

    // 3. Gradiente para el arco activo (Lime -> Cyan -> Red)
    final sweepProgress = sweepAngle * progress;

    final gradientShader = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: const [
        SpeeDGATheme.neonLime,
        SpeeDGATheme.aeroCyan,
        SpeeDGATheme.warningAmber,
        SpeeDGATheme.pulseRed,
      ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Trazo nítido principal (sin glow exterior)
    final progressPaint = Paint()
      ..shader = gradientShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepProgress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugeArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
  }
}
