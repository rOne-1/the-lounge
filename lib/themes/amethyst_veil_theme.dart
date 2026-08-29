import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'shadow_tokens.dart';
import 'typography.dart';

// AV-REDESIGN (2026-08-28, dev feedback): the original base/card leaned
// magenta-purple, sitting too close to Violet Dusk's own warm plum-pink
// identity and clashing with this theme's teal accent (cool teal against a
// warm magenta base reads as dissonant, not complementary). Recast the
// whole base/card ramp toward a cooler blue-violet indigo -- a different
// amethyst, closer to the gem's blue-violet variety than its red-violet
// one -- so the teal accent sits naturally instead of fighting the base.
const Color _avBase = Color(0xFF1C1638); // cool indigo, not magenta-purple
const Color _avCard = Color(0xFF2E2350);
const Color _avCard2 = Color(0xFF3A2D66);
const Color _avLineRgba = Color.fromRGBO(255, 235, 237, 0.16);
const Color _avInk = Color(0xFFFFEBED); // Lavender Blush
const Color _avSub = Color.fromRGBO(255, 235, 237, 0.55);
const Color _avAcc = Color(0xFF4FA3AE); // brightened Pacific Cyan
const Color _avOnPrimary = Color(0xFFFFEBED);
const Color _avPh = Color.fromRGBO(255, 235, 237, 0.07);
const Color _avPill = Color.fromRGBO(255, 235, 237, 0.08);

const Color _avGlow1 = Color(0xFFF6B6B7); // Powder Blush
const Color _avGlow2 = Color(0xFFA6C9B6); // Muted Teal

const Color _avStarRating = Color(0xFFF6B6B7); // Powder Blush
const Color _avSurfaceHighlight = Color.fromRGBO(255, 235, 237, 0.08);
const Color _avNavBarBg = Color.fromRGBO(28, 22, 56, 0.75);
const Color _avScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _avDanger = Color(0xFFC4536B);
const Color _avSuccess = Color(0xFF4F9A82);

const double _avGrainOpacity = 0.024;
const Color _avGrainTint = Color.fromRGBO(79, 163, 174, 0.22);

final ThemeShadows _avShadows = buildThemeShadows(accent: _avAcc, isDark: true);

BoxDecoration amethystVeilBackground() {
  return const BoxDecoration(
    color: _avBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.3,
      colors: [
        Color(0xFF2E4A52), // teal-indigo -- the veil parting to reveal teal
        Color(0xFF241D42),
        _avBase,
      ],
      stops: [0.0, 0.45, 1.0],
    ),
  );
}

/// Two soft draping arcs meeting at a glowing gem -- a veil parting to
/// reveal a single teal jewel.
class _AmethystVeilPainter extends CustomPainter {
  final Color veil;
  final Color gem;
  const _AmethystVeilPainter({required this.veil, required this.gem});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = veil
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final midX = size.width / 2;
    final midY = size.height / 2;

    final leftPath = Path()
      ..moveTo(midX - 40, midY + 6)
      ..quadraticBezierTo(midX - 20, midY - 8, midX - 6, midY - 1);
    canvas.drawPath(leftPath, paint);

    final rightPath = Path()
      ..moveTo(midX + 40, midY + 6)
      ..quadraticBezierTo(midX + 20, midY - 8, midX + 6, midY - 1);
    canvas.drawPath(rightPath, paint);

    canvas.drawCircle(
      Offset(midX, midY - 1),
      6,
      Paint()
        ..color = gem.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final gemPaint = Paint()
      ..color = gem
      ..style = PaintingStyle.fill;
    final diamondPath = Path()
      ..moveTo(midX, midY - 7)
      ..lineTo(midX + 3, midY - 2)
      ..lineTo(midX, midY + 3)
      ..lineTo(midX - 3, midY - 2)
      ..close();
    canvas.drawPath(diamondPath, gemPaint);
  }

  @override
  bool shouldRepaint(covariant _AmethystVeilPainter oldDelegate) =>
      oldDelegate.veil != veil || oldDelegate.gem != gem;
}

Widget amethystVeilMotif(BuildContext context) {
  final colors = context.ambianceColors;
  return Center(
    child: SizedBox(
      width: 100,
      height: 20,
      child: CustomPaint(
        painter: _AmethystVeilPainter(
          veil: colors.glow1.withValues(alpha: 0.7),
          gem: colors.acc,
        ),
      ),
    ),
  );
}

final AmbianceColors avAmbianceColors = AmbianceColors(
  base: _avBase,
  card: _avCard,
  card2: _avCard2,
  lineRgba: _avLineRgba,
  ink: _avInk,
  sub: _avSub,
  acc: _avAcc,
  ph: _avPh,
  pill: _avPill,
  starRating: _avStarRating,
  surfaceHighlight: _avSurfaceHighlight,
  navBarBg: _avNavBarBg,
  scrim: _avScrim,
  danger: _avDanger,
  success: _avSuccess,
  glow1: _avGlow1,
  glow2: _avGlow2,
  background: amethystVeilBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: _avAcc,
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: _avGrainOpacity,
  grainTint: _avGrainTint,
  cardShadow: _avShadows.cardShadow,
  ambientGlowShadow: _avShadows.ambientGlowShadow,
  dialogShadow: _avShadows.dialogShadow,
  signatureMotif: amethystVeilMotif,
  isDark: true,
);

final AppTheme amethystVeilTheme = AppTheme(
  id: 'amethyst_veil',
  displayName: 'Amethyst Veil',
  description: 'Cool blue-violet dusk, parted by a single teal glow.',
  colors: avAmbianceColors,
  signatureMotif: amethystVeilMotif,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _avBase,
    primaryColor: _avAcc,
    colorScheme: const ColorScheme.dark(
      primary: _avAcc,
      surface: _avBase,
      onPrimary: _avOnPrimary,
      onSurface: _avInk,
      surfaceContainerHighest: _avCard,
      outline: _avLineRgba,
    ),
    dividerColor: _avLineRgba,
    textTheme: buildTextTheme(
      textColor: _avInk,
      displayFont: GoogleFonts.crimsonPro,
      italicDisplay: true,
    ),
    extensions: [avAmbianceColors],
  ),
);
