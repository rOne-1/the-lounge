import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';

/// YSR-COMP-1: Vector & image emblem representing "The Lounge" - an arched
/// golden doorway opening with a radiant golden light beam. Uses the official
/// high-resolution asset `assets/icons/doorway_emblem.png` with a procedural
/// canvas painter fallback. Dynamically theme-aware and decoupled via AmbianceColors.
class LoungeDoorwayEmblem extends StatelessWidget {
  final double size;

  const LoungeDoorwayEmblem({
    super.key,
    this.size = 132.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final accent = colors.acc;
    final isDark = colors.isDark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: isDark ? 0.40 : 0.20),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.35 : 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.22 : 0.15),
            blurRadius: size * 0.3,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark ? const Color(0x99000000) : const Color(0x18000000),
            blurRadius: size * 0.2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/icons/doorway_emblem.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              size: Size(size, size),
              painter: _DoorwayPainter(
                accentColor: accent,
                inkColor: colors.ink,
                bgColor: colors.base,
                isDark: isDark,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DoorwayPainter extends CustomPainter {
  final Color accentColor;
  final Color inkColor;
  final Color bgColor;
  final bool isDark;

  _DoorwayPainter({
    required this.accentColor,
    required this.inkColor,
    required this.bgColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Doorway dimensions & positioning
    final doorWidth = w * 0.40;
    final doorHeight = h * 0.64;
    final left = (w - doorWidth) / 2;
    final top = (h - doorHeight) / 2 + (h * 0.03);
    final bottom = top + doorHeight;
    final archRadius = doorWidth / 2;

    // 1. Radiant Light Beam from Opening (Soft trapezoid gradient)
    final beamPath = Path();
    beamPath.moveTo(left + doorWidth * 0.52, top + archRadius * 0.35);
    beamPath.lineTo(left + doorWidth * 0.62, top + archRadius * 0.35);
    beamPath.lineTo(left + doorWidth * 0.98, bottom);
    beamPath.lineTo(left + doorWidth * 0.48, bottom);
    beamPath.close();

    final beamGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        accentColor.withValues(alpha: isDark ? 0.95 : 0.85),
        accentColor.withValues(alpha: isDark ? 0.45 : 0.35),
        accentColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.60, 1.0],
    );

    final beamPaint = Paint()
      ..shader = beamGradient.createShader(beamPath.getBounds())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawPath(beamPath, beamPaint);

    // 2. Arched Doorway Outer Frame Path
    final framePath = Path();
    framePath.moveTo(left, bottom);
    framePath.lineTo(left, top + archRadius);
    framePath.arcTo(
      Rect.fromCircle(
        center: Offset(left + archRadius, top + archRadius),
        radius: archRadius,
      ),
      math.pi,
      math.pi,
      false,
    );
    framePath.lineTo(left + doorWidth, bottom);
    framePath.close();

    // 3. Arched Frame Outline
    final framePaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.88 : 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.038
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(framePath, framePaint);

    // 4. Inner Open Door Panel (Perspective angled rectangle)
    final doorPanelPath = Path();
    final panelLeft = left + doorWidth * 0.12;
    final panelTop = top + archRadius * 0.22;
    final panelRight = left + doorWidth * 0.54;

    doorPanelPath.moveTo(panelLeft, bottom);
    doorPanelPath.lineTo(panelLeft, panelTop + archRadius * 0.7);
    doorPanelPath.quadraticBezierTo(
      panelLeft + (panelRight - panelLeft) * 0.4,
      panelTop,
      panelRight,
      panelTop + archRadius * 0.35,
    );
    doorPanelPath.lineTo(panelRight, bottom);
    doorPanelPath.close();

    final doorPanelFill = Paint()
      ..color = isDark
          ? bgColor.withValues(alpha: 0.90)
          : inkColor.withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;

    canvas.drawPath(doorPanelPath, doorPanelFill);

    final doorPanelEdge = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.95 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.024;

    canvas.drawPath(doorPanelPath, doorPanelEdge);

    // 5. Vertical Warm Accent Light Flare on Right Frame Edge
    final flarePaint = Paint()
      ..color = accentColor
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

    canvas.drawLine(
      Offset(left + doorWidth * 0.55, top + archRadius * 0.38),
      Offset(left + doorWidth * 0.56, bottom - h * 0.02),
      flarePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DoorwayPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.inkColor != inkColor ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.isDark != isDark;
  }
}
