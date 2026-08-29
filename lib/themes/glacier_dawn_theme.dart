import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'shadow_tokens.dart';
import 'typography.dart';

// GD-REDESIGN (2026-08-28, dev feedback): originally shipped as "Opal Frost"
// leaning on Cotton Candy pink + Dreamy Lilac, which read as a paler
// restatement of Orchid Bloom's violet identity -- the app's only other
// light theme. Rebuilt around a blue/coral duality instead (ice meeting
// dawn light) with a cool slate-blue ink, deliberately keeping this theme
// out of violet territory entirely.
const Color _gdBase = Color(0xFFEEF4F7);
const Color _gdCard = Color(0xFFFBFDFE);
const Color _gdCard2 = Color(0xFFD7E8F0);
const Color _gdLineRgba = Color.fromRGBO(31, 58, 77, 0.16);
const Color _gdInk = Color(0xFF1F3A4D); // cool slate-blue, not violet
const Color _gdSub = Color.fromRGBO(31, 58, 77, 0.55);
const Color _gdAcc = Color(0xFF1F6E96); // deep cerulean
const Color _gdPh = Color.fromRGBO(31, 58, 77, 0.07);
const Color _gdPill = Color.fromRGBO(31, 58, 77, 0.06);

const Color _gdGlow1 = Color(0xFFB8D8E6); // Ice Blue
const Color _gdGlow2 = Color(0xFFFCD7A1); // Peach Glow
const Color _gdGlint = Color(0xFFF4A7C4); // Cotton Candy -- motif-only accent

const Color _gdStarRating = Color(0xFFE8A94F);
const Color _gdSurfaceHighlight = Color.fromRGBO(255, 255, 255, 0.6);
const Color _gdNavBarBg = Color.fromRGBO(251, 253, 254, 0.78);
const Color _gdScrim = Color.fromRGBO(0, 0, 0, 0.72);
const Color _gdDanger = Color(0xFFC24A3E);
const Color _gdSuccess = Color(0xFF2E8F72);

const double _gdGrainOpacity = 0.014;
const Color _gdGrainTint = Color.fromRGBO(31, 110, 150, 0.12);

final ThemeShadows _gdShadows =
    buildThemeShadows(accent: _gdAcc, isDark: false);

BoxDecoration glacierDawnBackground() {
  return const BoxDecoration(
    color: _gdBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFFA9D4E8),
        _gdBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

/// Three glowing facets -- ice, coral, and a glint of iridescence -- light
/// splitting through frosted glass at dawn.
class _GlacierDawnPainter extends CustomPainter {
  final Color ice;
  final Color coral;
  final Color glint;
  const _GlacierDawnPainter(
      {required this.ice, required this.coral, required this.glint});

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final midY = size.height / 2;

    void facet(Offset center, Color color, double radius) {
      canvas.drawCircle(
        center,
        radius + 3,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill,
      );
    }

    facet(Offset(midX - 12, midY + 1), ice, 7);
    facet(Offset(midX + 12, midY + 1), coral, 7);
    facet(Offset(midX, midY - 6), glint, 4);

    canvas.drawCircle(Offset(midX, midY - 6), 1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _GlacierDawnPainter oldDelegate) =>
      oldDelegate.ice != ice ||
      oldDelegate.coral != coral ||
      oldDelegate.glint != glint;
}

Widget glacierDawnMotif(BuildContext context) {
  final colors = context.ambianceColors;
  return Center(
    child: SizedBox(
      width: 60,
      height: 24,
      child: CustomPaint(
        painter: _GlacierDawnPainter(
          ice: colors.glow1,
          coral: colors.glow2,
          glint: _gdGlint,
        ),
      ),
    ),
  );
}

final AmbianceColors gdAmbianceColors = AmbianceColors(
  base: _gdBase,
  card: _gdCard,
  card2: _gdCard2,
  lineRgba: _gdLineRgba,
  ink: _gdInk,
  sub: _gdSub,
  acc: _gdAcc,
  ph: _gdPh,
  pill: _gdPill,
  starRating: _gdStarRating,
  surfaceHighlight: _gdSurfaceHighlight,
  navBarBg: _gdNavBarBg,
  scrim: _gdScrim,
  danger: _gdDanger,
  success: _gdSuccess,
  glow1: _gdGlow1,
  glow2: _gdGlow2,
  background: glacierDawnBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: buildAccentButtonGradient(_gdAcc),
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: _gdGrainOpacity,
  grainTint: _gdGrainTint,
  cardShadow: _gdShadows.cardShadow,
  ambientGlowShadow: _gdShadows.ambientGlowShadow,
  dialogShadow: _gdShadows.dialogShadow,
  signatureMotif: glacierDawnMotif,
  isDark: false,
);

final AppTheme glacierDawnTheme = AppTheme(
  id: 'glacier_dawn',
  displayName: 'Glacier Dawn',
  description: 'Ice blue meeting coral dawn light -- cool glass, warm sun.',
  colors: gdAmbianceColors,
  signatureMotif: glacierDawnMotif,
  isDark: false,
  themeData: ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _gdBase,
    primaryColor: _gdAcc,
    colorScheme: const ColorScheme.light(
      primary: _gdAcc,
      surface: _gdBase,
      onPrimary: Colors.white,
      onSurface: _gdInk,
      surfaceContainerHighest: _gdCard,
      outline: _gdLineRgba,
    ),
    dividerColor: _gdLineRgba,
    textTheme: buildTextTheme(
      textColor: _gdInk,
      displayFont: GoogleFonts.dmSerifDisplay,
      italicDisplay: false,
    ),
    extensions: [gdAmbianceColors],
  ),
);
