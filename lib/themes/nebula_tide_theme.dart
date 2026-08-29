import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'shadow_tokens.dart';
import 'typography.dart';

// NT-REDESIGN (2026-08-28, dev feedback): originally shipped as "Cobalt
// Tide" -- a single-hue blue ramp that read as Midnight Cinema with the
// neon magenta removed, not a theme in its own right. Rebuilt around a
// COSMIC direction: an indigo-violet base layered with a magenta-nebula
// and cyan-starlight duality (its own two-tone language, not MC's
// cyan/hot-pink neon-marquee one), a 3-stop radial gradient for real depth
// instead of a single tint blob, and a constellation motif in place of the
// old current/tentacle curves.
const Color _ntBase = Color(0xFF0A0A1F);
const Color _ntCard = Color(0xFF1B1440);
const Color _ntCard2 = Color(0xFF2E1F5E);
const Color _ntLineRgba = Color.fromRGBO(237, 235, 251, 0.16);
const Color _ntInk = Color(0xFFEDEBFB);
const Color _ntSub = Color.fromRGBO(237, 235, 251, 0.55);
const Color _ntAcc = Color(0xFF5468E0); // electric indigo
const Color _ntOnPrimary = Color(0xFFF5F3FF);
const Color _ntPh = Color.fromRGBO(237, 235, 251, 0.07);
const Color _ntPill = Color.fromRGBO(237, 235, 251, 0.08);

const Color _ntGlow1 = Color(0xFFB24BD1); // nebula magenta-violet
const Color _ntGlow2 = Color(0xFF4FD1E8); // starlight cyan

const Color _ntStarRating = Color(0xFFF2D98C); // warm starlight gold
const Color _ntSurfaceHighlight = Color.fromRGBO(237, 235, 251, 0.08);
const Color _ntNavBarBg = Color.fromRGBO(10, 10, 31, 0.75);
const Color _ntScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _ntDanger = Color(0xFFD9506B);
const Color _ntSuccess = Color(0xFF43C08A);

const double _ntGrainOpacity = 0.027;
const Color _ntGrainTint = Color.fromRGBO(84, 104, 224, 0.24);

final ThemeShadows _ntShadows = buildThemeShadows(accent: _ntAcc, isDark: true);

BoxDecoration nebulaTideBackground() {
  return const BoxDecoration(
    color: _ntBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.3,
      colors: [
        Color(0xFF3D2568),
        Color(0xFF17123D),
        _ntBase,
      ],
      stops: [0.0, 0.45, 1.0],
    ),
  );
}

/// A loose constellation -- four stars of varying brightness joined by
/// faint sightlines, in gold, magenta-violet, and starlight cyan.
class _NebulaTideConstellationPainter extends CustomPainter {
  final Color starColor;
  final Color violet;
  final Color cyan;
  const _NebulaTideConstellationPainter({
    required this.starColor,
    required this.violet,
    required this.cyan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final midY = size.height / 2;

    final points = [
      Offset(midX - 40, midY + 2),
      Offset(midX - 14, midY - 6),
      Offset(midX + 12, midY + 4),
      Offset(midX + 38, midY - 5),
    ];

    final linePaint = Paint()
      ..color = starColor.withValues(alpha: 0.25)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    void star(Offset center, Color color, double radius, double glowAlpha) {
      canvas.drawCircle(
        center,
        radius + 3,
        Paint()
          ..color = color.withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(center, radius, Paint()..color = color);
    }

    star(points[0], cyan, 1.6, 0.5);
    star(points[1], starColor, 2.3, 0.6);
    star(points[2], violet, 1.7, 0.5);
    star(points[3], starColor, 2.5, 0.65);
  }

  @override
  bool shouldRepaint(covariant _NebulaTideConstellationPainter oldDelegate) =>
      oldDelegate.starColor != starColor ||
      oldDelegate.violet != violet ||
      oldDelegate.cyan != cyan;
}

Widget nebulaTideMotif(BuildContext context) {
  final colors = context.ambianceColors;
  return Center(
    child: SizedBox(
      width: 100,
      height: 24,
      child: CustomPaint(
        painter: _NebulaTideConstellationPainter(
          starColor: colors.starRating,
          violet: colors.glow1,
          cyan: colors.glow2,
        ),
      ),
    ),
  );
}

final AmbianceColors ntAmbianceColors = AmbianceColors(
  base: _ntBase,
  card: _ntCard,
  card2: _ntCard2,
  lineRgba: _ntLineRgba,
  ink: _ntInk,
  sub: _ntSub,
  acc: _ntAcc,
  ph: _ntPh,
  pill: _ntPill,
  starRating: _ntStarRating,
  surfaceHighlight: _ntSurfaceHighlight,
  navBarBg: _ntNavBarBg,
  scrim: _ntScrim,
  danger: _ntDanger,
  success: _ntSuccess,
  glow1: _ntGlow1,
  glow2: _ntGlow2,
  background: nebulaTideBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: buildAccentButtonGradient(_ntAcc),
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: _ntGrainOpacity,
  grainTint: _ntGrainTint,
  cardShadow: _ntShadows.cardShadow,
  ambientGlowShadow: _ntShadows.ambientGlowShadow,
  dialogShadow: _ntShadows.dialogShadow,
  signatureMotif: nebulaTideMotif,
  isDark: true,
);

final AppTheme nebulaTideTheme = AppTheme(
  id: 'nebula_tide',
  displayName: 'Nebula Tide',
  description: 'A deep-space current -- indigo nebula, magenta and starlight.',
  colors: ntAmbianceColors,
  signatureMotif: nebulaTideMotif,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _ntBase,
    primaryColor: _ntAcc,
    colorScheme: const ColorScheme.dark(
      primary: _ntAcc,
      surface: _ntBase,
      onPrimary: _ntOnPrimary,
      onSurface: _ntInk,
      surfaceContainerHighest: _ntCard,
      outline: _ntLineRgba,
    ),
    dividerColor: _ntLineRgba,
    textTheme: buildTextTheme(
      textColor: _ntInk,
      displayFont: GoogleFonts.marcellus,
      italicDisplay: false,
    ),
    extensions: [ntAmbianceColors],
  ),
);
