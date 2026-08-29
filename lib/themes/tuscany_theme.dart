import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'shadow_tokens.dart';
import 'typography.dart';

const Color _tsBase = Color(0xFF1F161A); // Darkened Voodoo
const Color _tsCard = Color(0xFF45303E); // Voodoo
const Color _tsCard2 = Color(0xFF6A4048); // Vineyard Wine
const Color _tsLineRgba = Color.fromRGBO(243, 230, 224, 0.16);
const Color _tsInk = Color(0xFFF3E6E0);
const Color _tsSub = Color.fromRGBO(243, 230, 224, 0.55);
const Color _tsAcc = Color(0xFFBB8B7A); // Tuscany
const Color _tsOnPrimary = Color(0xFF1F161A);
const Color _tsPh = Color.fromRGBO(243, 230, 224, 0.07);
const Color _tsPill = Color.fromRGBO(243, 230, 224, 0.08);

const Color _tsGlow1 = Color(0xFF966D69); // Clay Ridge
const Color _tsGlow2 = Color(0xFF434252); // Flintstone Blue

const Color _tsStarRating = Color(0xFFE3A458);
const Color _tsSurfaceHighlight = Color.fromRGBO(243, 230, 224, 0.08);
const Color _tsNavBarBg = Color.fromRGBO(31, 22, 26, 0.75);
const Color _tsScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _tsDanger = Color(0xFFC1443D);
const Color _tsSuccess = Color(0xFF6B9A6E);

const double _tsGrainOpacity = 0.031;
const Color _tsGrainTint = Color.fromRGBO(187, 139, 122, 0.26);

final ThemeShadows _tsShadows = buildThemeShadows(accent: _tsAcc, isDark: true);

BoxDecoration tuscanyBackground() {
  return const BoxDecoration(
    color: _tsBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF3A2830),
        _tsBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

class _TuscanyFlourishPainter extends CustomPainter {
  final Color color;
  const _TuscanyFlourishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final midX = size.width / 2;
    final midY = size.height / 2;

    // Left scroll flourish
    final leftPath = Path()
      ..moveTo(midX - 42, midY + 3)
      ..cubicTo(midX - 32, midY - 6, midX - 18, midY + 4, midX - 6, midY);
    canvas.drawPath(leftPath, paint);

    // Right scroll flourish
    final rightPath = Path()
      ..moveTo(midX + 42, midY + 3)
      ..cubicTo(midX + 32, midY - 6, midX + 18, midY + 4, midX + 6, midY);
    canvas.drawPath(rightPath, paint);

    // Center wrought-iron crest / sunburst seed
    canvas.drawCircle(Offset(midX, midY), 2.5, fillPaint);

    // Small radiating rays
    final rayPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(midX, midY - 4), Offset(midX, midY - 8), rayPaint);
    canvas.drawLine(
        Offset(midX - 4, midY - 3), Offset(midX - 7, midY - 6), rayPaint);
    canvas.drawLine(
        Offset(midX + 4, midY - 3), Offset(midX + 7, midY - 6), rayPaint);
  }

  @override
  bool shouldRepaint(covariant _TuscanyFlourishPainter oldDelegate) =>
      oldDelegate.color != color;
}

Widget tuscanyMotif(BuildContext context) {
  final colors = context.ambianceColors;
  return Center(
    child: SizedBox(
      width: 110,
      height: 20,
      child: CustomPaint(
        painter:
            _TuscanyFlourishPainter(color: colors.acc.withValues(alpha: 0.75)),
      ),
    ),
  );
}

final AmbianceColors tsAmbianceColors = AmbianceColors(
  base: _tsBase,
  card: _tsCard,
  card2: _tsCard2,
  lineRgba: _tsLineRgba,
  ink: _tsInk,
  sub: _tsSub,
  acc: _tsAcc,
  ph: _tsPh,
  pill: _tsPill,
  starRating: _tsStarRating,
  surfaceHighlight: _tsSurfaceHighlight,
  navBarBg: _tsNavBarBg,
  scrim: _tsScrim,
  danger: _tsDanger,
  success: _tsSuccess,
  glow1: _tsGlow1,
  glow2: _tsGlow2,
  background: tuscanyBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: buildAccentButtonGradient(_tsAcc),
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: _tsGrainOpacity,
  grainTint: _tsGrainTint,
  cardShadow: _tsShadows.cardShadow,
  ambientGlowShadow: _tsShadows.ambientGlowShadow,
  dialogShadow: _tsShadows.dialogShadow,
  signatureMotif: tuscanyMotif,
  isDark: true,
);

final AppTheme tuscanyTheme = AppTheme(
  id: 'tuscany',
  displayName: 'Tuscany',
  description: 'Sun-baked terracotta and aged wine, cooled by dusk slate.',
  colors: tsAmbianceColors,
  signatureMotif: tuscanyMotif,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _tsBase,
    primaryColor: _tsAcc,
    colorScheme: const ColorScheme.dark(
      primary: _tsAcc,
      surface: _tsBase,
      onPrimary: _tsOnPrimary,
      onSurface: _tsInk,
      surfaceContainerHighest: _tsCard,
      outline: _tsLineRgba,
    ),
    dividerColor: _tsLineRgba,
    textTheme: buildTextTheme(
      textColor: _tsInk,
      displayFont: GoogleFonts.lora,
      italicDisplay: false,
    ),
    extensions: [tsAmbianceColors],
  ),
);
