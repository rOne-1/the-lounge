import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'shadow_tokens.dart';
import 'typography.dart';

// Replaces Amethyst Veil (2026-08-28, dev feedback: too close to Nebula
// Tide once both were dark blue-violet). A private estate deep inside
// old-growth rainforest: enormous dark conifers, needle leaves, moss over
// decomposing wood, mist in the canopy gaps, dew finding its way down
// through the branches, mansion floorboards under it all.
//
// WOOD-PASS (2026-08-29, dev feedback): the first cut kept every surface in
// one green/ivory/gray family and read as monotonous.
//
// STRUCTURE-PASS (2026-08-29, further dev feedback): the wood-pass's
// jade-to-walnut button gradient read as a modern, glossy tech-CTA blend --
// wrong material entirely for "enormous old trees, thick dark bark, misty
// air." Rebuilt the hierarchy instead of just adding a second hue: the
// *background* stays green-dominant (the canopy is the one thing that
// should read as forest at a glance), while card, card2, the primary
// button, the divider line, and the grain wash all move OFF green and onto
// distinct wood materials -- thick dark bark (card), a cooler rain-damp
// weathered log (card2), and an aged-timber button that's solid/matte, not
// a bright diagonal gradient. Green survives as the *accent* glow (foliage,
// living leaf) rather than the dominant surface color, so it reads as light
// filtering onto wood, not wood painted green.
const Color _vmBase = Color(0xFF0D1410); // forest shadow, near-black
const Color _vmCard = Color(0xFF241A12); // thick old bark
const Color _vmCard2 = Color(0xFF3A342C); // rain-damp weathered log
const Color _vmLineRgba = Color.fromRGBO(150, 120, 90, 0.20); // wood grain
// TYPE-PASS (2026-08-29, dev feedback): ink was a near-neutral cream --
// read as the same generic "light text" every theme falls back to, not
// this theme's own material. Warmed into an antique-gold parchment (the
// mansion's brass/candlelight, not another shade of white/gray) and paired
// with Ibarra Real Nova's italic -- a warmer, more characterful hand than
// Frank Ruhl Libre's neutral gravity, closer to a hand-lettered estate
// journal than a plain display serif.
const Color _vmInk = Color(0xFFE9D7A8); // antique-gold parchment
const Color _vmSub = Color.fromRGBO(233, 215, 168, 0.55);
const Color _vmAcc = Color(0xFF5C4028); // aged timber -- buttons, not green
const Color _vmOnPrimary = Color(0xFFF3F1E6);
const Color _vmPh = Color.fromRGBO(233, 215, 168, 0.07);
const Color _vmPill = Color.fromRGBO(233, 215, 168, 0.08);

// GLOW-CONTRAST-FIX (2026-08-29, dev feedback): AmbientGlowWidget
// (lib/widgets/ambient_glow.dart) animates glow1/glow2 at a constant, never-
// pulsing alpha -- the only thing that reads as "flowing" is the two blobs'
// hue differential as they drift past each other. A sage-tinted mist sat in
// the same green family as the foliage glow, so the animation ran but had
// nothing to visibly shift between. Recast mist as a true cool blue-gray --
// more accurate to actual rain/fog anyway -- so foliage green and mist
// blue-gray genuinely cross hues as they drift.
const Color _vmGlow1 = Color(0xFF2F8F5B); // foliage
const Color _vmGlow2 = Color(0xFF7FA3AE); // rain mist
const Color _vmBark = Color(0xFF4A3420); // branch/stem wood -- motif-only
const Color _vmRain = Color(0xFF9BB0A8); // rain streaks -- motif-only

const Color _vmStarRating = Color(0xFFD9A65C); // dappled sunlight, icon-only
const Color _vmSurfaceHighlight = Color.fromRGBO(233, 215, 168, 0.08);
const Color _vmNavBarBg = Color.fromRGBO(13, 20, 16, 0.75);
const Color _vmScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _vmDanger = Color(0xFFB4553F); // rust, decomposing wood
const Color _vmSuccess = Color(0xFF4CAF6E); // living leaf

const double _vmGrainOpacity = 0.029;
const Color _vmGrainTint = Color.fromRGBO(74, 66, 54, 0.22); // rain-damp bark

final ThemeShadows _vmShadows = buildThemeShadows(accent: _vmAcc, isDark: true);

BoxDecoration verdantManorBackground() {
  return const BoxDecoration(
    color: _vmBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.3,
      colors: [
        Color(0xFF23422E), // light breaking through the canopy
        _vmBase,
      ],
      stops: [0.0, 0.65],
    ),
  );
}

/// A pine-needle sprig with a single dew drop caught at the tip -- the
/// branch itself in bark, the needles in foliage green, faint rain
/// streaking through the gap behind it.
class _VerdantManorPainter extends CustomPainter {
  final Color bark;
  final Color needle;
  final Color droplet;
  final Color rain;
  const _VerdantManorPainter({
    required this.bark,
    required this.needle,
    required this.droplet,
    required this.rain,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final midY = size.height / 2;

    final rainPaint = Paint()
      ..color = rain.withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = midX - 38 + i * 22.0;
      canvas.drawLine(
          Offset(x, midY - 11), Offset(x - 3, midY - 3), rainPaint);
    }

    final stemPaint = Paint()
      ..color = bark
      ..strokeWidth = 1.4
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
      oldDelegate.bark != bark ||
      oldDelegate.needle != needle ||
      oldDelegate.droplet != droplet ||
      oldDelegate.rain != rain;
}

Widget verdantManorMotif(BuildContext context) {
  final colors = context.ambianceColors;
  return Center(
    child: SizedBox(
      width: 100,
      height: 24,
      child: CustomPaint(
        painter: _VerdantManorPainter(
          bark: _vmBark,
          needle: colors.glow1,
          droplet: colors.glow2,
          rain: _vmRain,
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
    color: _vmAcc,
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
      'A private estate deep in old-growth rainforest -- green canopy above, thick bark and mist below.',
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
      displayFont: GoogleFonts.ibarraRealNova,
      italicDisplay: true,
    ),
    extensions: [vmAmbianceColors],
  ),
);
