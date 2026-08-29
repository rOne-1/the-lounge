import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'shadow_tokens.dart';
import 'typography.dart';

const Color _ctBase = Color(0xFF06132E); // Squid's Ink
const Color _ctCard = Color(0xFF07254E); // Royal Blue Metallic
const Color _ctCard2 = Color(0xFF1E4B77); // Thunder Night
const Color _ctLineRgba = Color.fromRGBO(231, 241, 251, 0.16);
const Color _ctInk = Color(0xFFE7F1FB);
const Color _ctSub = Color.fromRGBO(231, 241, 251, 0.55);
const Color _ctAcc = Color(0xFF2A87CD); // Ticino Blue
const Color _ctOnPrimary = Color(0xFF04101F);
const Color _ctPh = Color.fromRGBO(231, 241, 251, 0.07);
const Color _ctPill = Color.fromRGBO(231, 241, 251, 0.08);

const Color _ctGlow1 = Color(0xFF7FB5E7); // Aero
const Color _ctGlow2 = Color(0xFFC7D8E5); // Lively Tune

const Color _ctStarRating = Color(0xFF7FB5E7); // Aero
const Color _ctSurfaceHighlight = Color.fromRGBO(231, 241, 251, 0.08);
const Color _ctNavBarBg = Color.fromRGBO(6, 19, 46, 0.75);
const Color _ctScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _ctDanger = Color(0xFFDB5A56);
const Color _ctSuccess = Color(0xFF3FA687);

const double _ctGrainOpacity = 0.026;
const Color _ctGrainTint = Color.fromRGBO(42, 135, 205, 0.24);

final ThemeShadows _ctShadows = buildThemeShadows(accent: _ctAcc, isDark: true);

BoxDecoration cobaltTideBackground() {
  return const BoxDecoration(
    color: _ctBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF12335E),
        _ctBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

/// Two soft drifting tentacle curves with luminous bioluminescent points --
/// the jellyfish-in-deep-water source imagery, abstracted to a line motif.
class _CobaltTideCurrentPainter extends CustomPainter {
  final Color color;
  final Color glow;
  const _CobaltTideCurrentPainter({required this.color, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final midX = size.width / 2;
    final midY = size.height / 2;

    final leftPath = Path()
      ..moveTo(midX - 44, midY - 5)
      ..cubicTo(midX - 30, midY + 6, midX - 16, midY - 6, midX - 4, midY);
    canvas.drawPath(leftPath, paint);

    final rightPath = Path()
      ..moveTo(midX + 44, midY - 5)
      ..cubicTo(midX + 30, midY + 6, midX + 16, midY - 6, midX + 4, midY);
    canvas.drawPath(rightPath, paint);

    final dotPaint = Paint()
      ..color = glow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(midX, midY), 2.4, dotPaint);
    canvas.drawCircle(
        Offset(midX - 20, midY + 2), 1.3, dotPaint..color = glow.withValues(alpha: 0.6));
    canvas.drawCircle(
        Offset(midX + 20, midY + 2), 1.3, dotPaint..color = glow.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant _CobaltTideCurrentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glow != glow;
}

Widget cobaltTideMotif(BuildContext context) {
  final colors = context.ambianceColors;
  return Center(
    child: SizedBox(
      width: 100,
      height: 20,
      child: CustomPaint(
        painter: _CobaltTideCurrentPainter(
          color: colors.acc.withValues(alpha: 0.7),
          glow: colors.glow1,
        ),
      ),
    ),
  );
}

final AmbianceColors ctAmbianceColors = AmbianceColors(
  base: _ctBase,
  card: _ctCard,
  card2: _ctCard2,
  lineRgba: _ctLineRgba,
  ink: _ctInk,
  sub: _ctSub,
  acc: _ctAcc,
  ph: _ctPh,
  pill: _ctPill,
  starRating: _ctStarRating,
  surfaceHighlight: _ctSurfaceHighlight,
  navBarBg: _ctNavBarBg,
  scrim: _ctScrim,
  danger: _ctDanger,
  success: _ctSuccess,
  glow1: _ctGlow1,
  glow2: _ctGlow2,
  background: cobaltTideBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: _ctAcc,
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: _ctGrainOpacity,
  grainTint: _ctGrainTint,
  cardShadow: _ctShadows.cardShadow,
  ambientGlowShadow: _ctShadows.ambientGlowShadow,
  dialogShadow: _ctShadows.dialogShadow,
  signatureMotif: cobaltTideMotif,
  isDark: true,
);

final AppTheme cobaltTideTheme = AppTheme(
  id: 'cobalt_tide',
  displayName: 'Cobalt Tide',
  description: 'Deep ocean cobalt with a luminous bioluminescent current.',
  colors: ctAmbianceColors,
  signatureMotif: cobaltTideMotif,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _ctBase,
    primaryColor: _ctAcc,
    colorScheme: const ColorScheme.dark(
      primary: _ctAcc,
      surface: _ctBase,
      onPrimary: _ctOnPrimary,
      onSurface: _ctInk,
      surfaceContainerHighest: _ctCard,
      outline: _ctLineRgba,
    ),
    dividerColor: _ctLineRgba,
    textTheme: buildTextTheme(
      textColor: _ctInk,
      displayFont: GoogleFonts.marcellus,
      italicDisplay: false,
    ),
    extensions: [ctAmbianceColors],
  ),
);
