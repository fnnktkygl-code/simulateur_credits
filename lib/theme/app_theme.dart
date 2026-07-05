import 'package:flutter/material.dart';

class SimColors {
  static const ink = Color(0xFF101B2D);
  static const ink2 = Color(0xFF0B1524);
  static const paper = Color(0xFFEEF0EC);
  static const paper2 = Color(0xFFE4E7DF);
  static const card = Color(0xFFFBFBF8);
  static const brass = Color(0xFFA9812E);
  static const brassLight = Color(0xFFC9A24E);
  static const safe = Color(0xFF3B7A5A);
  static const safeBg = Color(0xFFDCEAE1);
  static const warn = Color(0xFFC98A1B);
  static const warnBg = Color(0xFFF4E4C7);
  static const danger = Color(0xFFB23B3B);
  static const dangerBg = Color(0xFFF5DCDA);
  static const text = Color(0xFF16202E);
  static const muted = Color(0xFF5C6472);
  static const line = Color(0xFFD8DAD1);
  static const heroText = Color(0xFFF2EFE6);
  static const heroSub = Color(0xFFC9CDD8);
  static const resultSub = Color(0xFF9CA3B2);
}

class SimTheme {
  static const radius = 14.0;

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: SimColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SimColors.ink,
      surface: SimColors.paper,
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Fraunces',
        fontWeight: FontWeight.w600,
        fontSize: 28,
        height: 1.08,
        color: SimColors.heroText,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Fraunces',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: SimColors.text,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14.5,
        color: SimColors.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        color: SimColors.text,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        color: SimColors.muted,
      ),
      labelLarge: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: SimColors.brassLight,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: SimColors.ink,
      inactiveTrackColor: SimColors.paper2,
      thumbColor: SimColors.ink,
      overlayColor: SimColors.brassLight.withAlpha(40),
      trackHeight: 4,
      thumbShape: _BrassThumb(),
    ),
  );
}

class _BrassThumb extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(18, 18);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    
    // Scale up slightly when pressed
    final scale = 1.0 + (activationAnimation.value * 0.15);
    final currentRadius = 9.0 * scale;

    // Shadow
    if (activationAnimation.value > 0) {
      final shadowPaint = Paint()
        ..color = SimColors.brassLight.withAlpha((80 * activationAnimation.value).toInt())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * activationAnimation.value);
      canvas.drawCircle(center, currentRadius + 2, shadowPaint);
    }

    // Border
    canvas.drawCircle(center, currentRadius, Paint()..color = SimColors.brassLight);
    // Inner
    canvas.drawCircle(center, 6.0 * scale, Paint()..color = SimColors.ink);
  }
}

/// Monospaced number text style.
TextStyle numStyle({double size = 14, FontWeight weight = FontWeight.w600, Color color = SimColors.brassLight}) {
  return TextStyle(fontFamily: 'IBMPlexMono', fontSize: size, fontWeight: weight, color: color);
}
