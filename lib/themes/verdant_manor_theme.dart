import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'shadow_tokens.dart';
import 'typography.dart';

// Replaces Amethyst Veil (2026-08-28, dev feedback: too close to Nebula
// Tide once both were dark blue-violet). A different direction entirely --
// a private estate deep inside old-growth rainforest: enormous dark
// conifers, needle leaves, moss over decomposing wood, mist in the canopy
// gaps, dew finding its way down through the branches. Deep jade/moss for
// the forest itself, a warm stone-ivory for the architecture, and a soft
// sage-mist glow for the fog -- deliberately kept off gold/brown surfaces
// (Screening Room and Tuscany already own that territory); any warmth
// lives in the small starRating accent only, same convention every other
// theme follows.
const Color _vmBase = Color(0xFF0D1410); // forest shadow, near-black
const Color _vmCard = Color(0xFF1B2A1F); // moss
const Color _vmCard2 = Color(0xFF24352A); // wet bark
const Color _vmLineRgba = Color.fromRGBO(237, 232, 220, 0.16);
const Color _vmInk = Color(0xFFEDE8DC); // warm stone/mist ivory
const Color _vmSub = Color.fromRGBO(237, 232, 220, 0.55);
const Color _vmAcc = Color(0xFF1F7A52); // deep jade
const Color _vmAccGradientEnd = Color(0xFF6B9C3F); // dappled canopy light
const Color _vmOnPrimary = Color(0xFFF3F1E6);
const Color _vmPh = Color.fromRGBO(237, 232, 220, 0.07);
const Color _vmPill = Color.fromRGBO(237, 232, 220, 0.08);

const Color _vmGlow1 = Color(0xFF2F8F5B); // foliage
const Color _vmGlow2 = Color(0xFFB9CBC0); // mist

const Color _vmStarRating = Color(0xFFD9A65C); // dappled sunlight, icon-only
const Color _vmSurfaceHighlight = Color.fromRGBO(237, 232, 220, 0.08);
const Color _vmNavBarBg = Color.fromRGBO(13, 20, 16, 0.75);
const Color _vmScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _vmDanger = Color(0xFFB4553F); // rust, decomposing wood
const Color _vmSuccess = Color(0xFF4CAF6E); // living leaf

const double _vmGrainOpacity = 0.029;
const Color _vmGrainTint = Color.fromRGBO(31, 122, 82, 0.22);

final ThemeShadows _vmShadows = buildThemeShadows(accent: _vmAcc, isDark: true);

const LinearGradient _vmPrimaryGradient = LinearGradient(
  colors: [_vmAcc, _vmAccGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

BoxDecoration verdantManorBackground() {
  return const BoxDecoration(
    color: _vmBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.3,
      colors: [
        Color(0xFF1E3A2A), // light breaking through the canopy
        Color(0xFF142118),
        _vmBase,
      ],
      stops: [0.0, 0.45, 1.0],
    ),
  );
}

/// A pine-needle sprig with a single dew drop caught at the tip -- water
/// finding its way down through the branches.
class _VerdantManorPainter extends CustomPainter {
  final Color needle;
  final Color droplet;
  const _VerdantManorPainter({required this.needle, required this.droplet});

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final midY = size.height / 2;

    final stemPaint = Paint()
      ..color = needle
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final stemStart = Offset(midX - 30, midY + 4);
    final stemEnd = Offset(midX + 26, midY - 4);
    canvas.drawLine(stemStart, stemEnd, stemPaint);

    final needlePaint = Paint()
      ..color = needle.withValues(alpha: 0.85)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i++) {
      final t = (i + 2) / 4;
      final base = Offset.lerp(stemStart, stemEnd, t)!;
      canvas.drawLine(base, base + const Offset(5, -8), needlePaint);
      canvas.drawLine(base, base + const Offset(-3, -8), needlePaint);
    }

    final dropCenter = stemEnd + const Offset(4, 6);
    canvas.drawCircle(
      dropCenter,
      4,
      Paint()
        ..color = droplet.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    final dropPath = Path()
      ..moveTo(dropCenter.dx, dropCenter.dy - 3.2)
      ..quadraticBezierTo(
          dropCenter.dx + 2.4, dropCenter.dy + 1, dropCenter.dx, dropCenter.dy + 3)
      ..quadraticBezierTo(
          dropCenter.dx - 2.4, dropCenter.dy + 1, dropCenter.dx, dropCenter.dy - 3.2)
      ..close();
    canvas.drawPath(dropPath, Paint()..color = droplet.withValues(alpha: 0.9));
    canvas.drawCircle(
      Offset(dropCenter.dx - 0.9, dropCenter.dy - 0.9),
      0.7,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _VerdantManorPainter oldDelegate) =>
      oldDelegate.needle != needle || oldDelegate.droplet != droplet;
}

Widget verdantManorMotif(BuildContext context) {
  final colors = context.ambianceColors;
  return Center(
    child: SizedBox(
      width: 100,
      height: 24,
      child: CustomPaint(
        painter: _VerdantManorPainter(
          needle: colors.glow1,
          droplet: colors.glow2,
        ),
      ),
    ),
  );
}

final AmbianceColors vmAmbianceColors = AmbianceColors(
  base: _vmBase,
  card: _vmCard,
  card2: _vmCard2,
  lineRgba: _vmLineRgba,
  ink: _vmInk,
  sub: _vmSub,
  acc: _vmAcc,
  ph: _vmPh,
  pill: _vmPill,
  starRating: _vmStarRating,
  surfaceHighlight: _vmSurfaceHighlight,
  navBarBg: _vmNavBarBg,
  scrim: _vmScrim,
  danger: _vmDanger,
  success: _vmSuccess,
  glow1: _vmGlow1,
  glow2: _vmGlow2,
  background: verdantManorBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: _vmPrimaryGradient,
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: _vmGrainOpacity,
  grainTint: _vmGrainTint,
  cardShadow: _vmShadows.cardShadow,
  ambientGlowShadow: _vmShadows.ambientGlowShadow,
  dialogShadow: _vmShadows.dialogShadow,
  signatureMotif: verdantManorMotif,
  isDark: true,
);

final AppTheme verdantManorTheme = AppTheme(
  id: 'verdant_manor',
  displayName: 'Verdant Manor',
  description:
      'A private estate deep in old-growth rainforest -- moss, mist, and dusk-lit jade.',
  colors: vmAmbianceColors,
  signatureMotif: verdantManorMotif,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _vmBase,
    primaryColor: _vmAcc,
    colorScheme: const ColorScheme.dark(
      primary: _vmAcc,
      surface: _vmBase,
      onPrimary: _vmOnPrimary,
      onSurface: _vmInk,
      surfaceContainerHighest: _vmCard,
      outline: _vmLineRgba,
    ),
    dividerColor: _vmLineRgba,
    textTheme: buildTextTheme(
      textColor: _vmInk,
      displayFont: GoogleFonts.frankRuhlLibre,
      italicDisplay: false,
    ),
    extensions: [vmAmbianceColors],
  ),
);
