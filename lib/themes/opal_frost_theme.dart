import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'shadow_tokens.dart';
import 'typography.dart';

const Color _ofBase = Color(0xFFF6F2E8); // Moonlight
const Color _ofCard = Color(0xFFFFFDFB);
const Color _ofCard2 = Color(0xFFEDEAF7); // Ice Blue x Dreamy Lilac blend
const Color _ofLineRgba = Color.fromRGBO(59, 46, 82, 0.16);
const Color _ofInk = Color(0xFF3B2E52); // deep plum-indigo for contrast
const Color _ofSub = Color.fromRGBO(59, 46, 82, 0.55);
const Color _ofAcc = Color(0xFFC85D8D); // Cotton Candy, deepened for contrast
const Color _ofAccGradientEnd = Color(0xFF7C5FA8); // Dreamy Lilac, deepened
const Color _ofPh = Color.fromRGBO(59, 46, 82, 0.07);
const Color _ofPill = Color.fromRGBO(59, 46, 82, 0.06);

const Color _ofGlow1 = Color(0xFFF4A7C4); // Cotton Candy
const Color _ofGlow2 = Color(0xFFB8D8E6); // Ice Blue

const Color _ofStarRating = Color(0xFFFCD7A1); // Peach Glow -- icon-only use
const Color _ofSurfaceHighlight = Color.fromRGBO(255, 255, 255, 0.6);
const Color _ofNavBarBg = Color.fromRGBO(255, 253, 251, 0.78);
const Color _ofScrim = Color.fromRGBO(0, 0, 0, 0.72);
const Color _ofDanger = Color(0xFFC2415B);
const Color _ofSuccess = Color(0xFF3F8F72);

const double _ofGrainOpacity = 0.014;
const Color _ofGrainTint = Color.fromRGBO(200, 93, 141, 0.12);

final ThemeShadows _ofShadows =
    buildThemeShadows(accent: _ofAcc, isDark: false);

const LinearGradient _ofPrimaryGradient = LinearGradient(
  colors: [_ofAcc, _ofAccGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

BoxDecoration opalFrostBackground() {
  return const BoxDecoration(
    color: _ofBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFFE3ECF5),
        _ofBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

/// Three overlapping translucent facets suggesting light splitting through
/// frosted glass -- the prism-through-ice motif from the source moodboard.
class _OpalFrostPainter extends CustomPainter {
  final Color rose;
  final Color lilac;
  final Color ice;
  const _OpalFrostPainter(
      {required this.rose, required this.lilac, required this.ice});

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final midY = size.height / 2;

    void facet(Offset center, Color color) {
      canvas.drawCircle(
        center,
        7,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..style = PaintingStyle.fill,
      );
    }

    facet(Offset(midX - 10, midY), ice);
    facet(Offset(midX, midY - 3), lilac);
    facet(Offset(midX + 10, midY), rose);

    final sparkle = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(midX, midY - 3), 1.4, sparkle);
  }

  @override
  bool shouldRepaint(covariant _OpalFrostPainter oldDelegate) =>
      oldDelegate.rose != rose ||
      oldDelegate.lilac != lilac ||
      oldDelegate.ice != ice;
}

Widget opalFrostMotif(BuildContext context) {
  final colors = context.ambianceColors;
  return Center(
    child: SizedBox(
      width: 60,
      height: 20,
      child: CustomPaint(
        painter: _OpalFrostPainter(
          rose: colors.glow1,
          lilac: colors.acc,
          ice: colors.glow2,
        ),
      ),
    ),
  );
}

final AmbianceColors ofAmbianceColors = AmbianceColors(
  base: _ofBase,
  card: _ofCard,
  card2: _ofCard2,
  lineRgba: _ofLineRgba,
  ink: _ofInk,
  sub: _ofSub,
  acc: _ofAcc,
  ph: _ofPh,
  pill: _ofPill,
  starRating: _ofStarRating,
  surfaceHighlight: _ofSurfaceHighlight,
  navBarBg: _ofNavBarBg,
  scrim: _ofScrim,
  danger: _ofDanger,
  success: _ofSuccess,
  glow1: _ofGlow1,
  glow2: _ofGlow2,
  background: opalFrostBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: _ofPrimaryGradient,
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: _ofGrainOpacity,
  grainTint: _ofGrainTint,
  cardShadow: _ofShadows.cardShadow,
  ambientGlowShadow: _ofShadows.ambientGlowShadow,
  dialogShadow: _ofShadows.dialogShadow,
  signatureMotif: opalFrostMotif,
  isDark: false,
);

final AppTheme opalFrostTheme = AppTheme(
  id: 'opal_frost',
  displayName: 'Opal Frost',
  description: 'Iridescent pastel ice -- rose and lilac light through frost.',
  colors: ofAmbianceColors,
  signatureMotif: opalFrostMotif,
  isDark: false,
  themeData: ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _ofBase,
    primaryColor: _ofAcc,
    colorScheme: const ColorScheme.light(
      primary: _ofAcc,
      surface: _ofBase,
      onPrimary: Colors.white,
      onSurface: _ofInk,
      surfaceContainerHighest: _ofCard,
      outline: _ofLineRgba,
    ),
    dividerColor: _ofLineRgba,
    textTheme: buildTextTheme(
      textColor: _ofInk,
      displayFont: GoogleFonts.dmSerifDisplay,
      italicDisplay: false,
    ),
    extensions: [ofAmbianceColors],
  ),
);
