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

  // Sombras y Resplandores (Desactivados por legibilidad)
  static List<BoxShadow> neonGlow({Color color = neonLime, double spread = 1.0, double blur = 16.0}) {
    return const [];
  }

  static List<BoxShadow> cardShadow = [
    const BoxShadow(
      color: Color(0x80000000),
      blurRadius: 18.0,
      offset: Offset(0, 6),
    ),
  ];

  // Decoraciones para Tarjetas Bento (bordes limpios y sin glow)
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
      boxShadow: cardShadow,
    );
  }

  // Familias Tipográficas Oficiales de Google Stitch
  static const String fontSpaceGrotesk = 'SpaceGrotesk';
  static const String fontJetBrainsMono = 'JetBrainsMono';
  static const String fontHankenGrotesk = 'HankenGrotesk';

  // Velocímetro Gigante Hero (Space Grotesk 130px)
  static TextStyle speedHeroFont({
    double fontSize = 130.0,
    FontWeight fontWeight = FontWeight.w900,
    Color color = Colors.white,
    double letterSpacing = -2.0,
  }) {
    return TextStyle(
      fontFamily: fontSpaceGrotesk,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: 0.95,
    );
  }

  // Cifras y Números de Telemetría (Space Grotesk con cifras tabulares)
  static TextStyle digitFont({
    double fontSize = 24.0,
    FontWeight fontWeight = FontWeight.w900,
    Color color = textPrimary,
    double letterSpacing = -0.5,
  }) {
    return TextStyle(
      fontFamily: fontSpaceGrotesk,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: 1.05,
    );
  }

  // Etiquetas Técnicas y Chips de Datos (JetBrains Mono)
  static TextStyle labelTechnical({
    double fontSize = 10.5,
    FontWeight fontWeight = FontWeight.w700,
    Color color = textSecondary,
    double letterSpacing = 1.0,
  }) {
    return TextStyle(
      fontFamily: fontJetBrainsMono,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Títulos de Sección y Encabezados (Space Grotesk)
  static TextStyle headingFont({
    double fontSize = 17.0,
    FontWeight fontWeight = FontWeight.w900,
    Color color = textPrimary,
    double letterSpacing = 1.0,
  }) {
    return TextStyle(
      fontFamily: fontSpaceGrotesk,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Texto de Cuerpo y UI (Hanken Grotesk)
  static TextStyle bodyFont({
    double fontSize = 13.0,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textSecondary,
  }) {
    return TextStyle(
      fontFamily: fontHankenGrotesk,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
