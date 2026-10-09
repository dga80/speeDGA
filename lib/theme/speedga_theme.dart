import 'dart:ui';
import 'package:flutter/material.dart';

/// Tema visual y tokens del Sistema de Diseño SpeeDGA (Google Stitch)
class SpeeDGATheme {
  // Paleta de Colores OLED & Cybernetic Telemetry
  static const Color oledBlack = Color(0xFF000000);
  static const Color darkCanvas = Color(0xFF080B0E);
  static const Color darkSurface = Color(0xFF0F1419);
  static const Color darkCard = Color(0xFF13181F);
  static const Color darkCardHover = Color(0xFF1A212B);
  static const Color darkCardElevated = Color(0xFF1D2631);
  static const Color darkBorder = Color(0xFF222B38);
  static const Color darkBorderSubtle = Color(0x1FFFFFFF);

  // Acentos de Alta Energía
  static const Color neonLime = Color(0xFF00FF66);
  static const Color velocityLime = Color(0xFF00FF87);
  static const Color aeroCyan = Color(0xFF00D2FF);
  static const Color electricCyan = Color(0xFF00F0FF);
  static const Color pulseRed = Color(0xFFFF3366);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color alertOrange = Color(0xFFFF7A00);

  // Jerarquía Tipográfica de Color
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9BA8B6);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF475569);

  // Sombras y Resplandores (Glow)
  static List<BoxShadow> neonGlow({Color color = neonLime, double spread = 1.0, double blur = 16.0}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.35),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> cardShadow = [
    const BoxShadow(
      color: Color(0x80000000),
      blurRadius: 18.0,
      offset: Offset(0, 6),
    ),
  ];

  // Decoraciones para Tarjetas Bento
  static BoxDecoration bentoCardDecoration({
    Color backgroundColor = darkCard,
    Color borderColor = darkBorder,
    double borderRadius = 20.0,
    bool glow = false,
    Color glowColor = neonLime,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.0),
      boxShadow: [
        if (glow) ...neonGlow(color: glowColor, blur: 20.0, spread: 0.5),
        ...cardShadow,
      ],
    );
  }

  // Estilos de Texto Monospaciados con Cifras Tabulares
  static TextStyle digitFont({
    double fontSize = 28.0,
    FontWeight fontWeight = FontWeight.w900,
    Color color = textPrimary,
    double letterSpacing = -1.0,
  }) {
    return TextStyle(
      fontFamily: 'Courier',
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: 1.05,
    );
  }

  static TextStyle labelTechnical({
    double fontSize = 11.0,
    FontWeight fontWeight = FontWeight.w700,
    Color color = textSecondary,
    double letterSpacing = 1.2,
  }) {
    return TextStyle(
      fontFamily: 'Courier',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
