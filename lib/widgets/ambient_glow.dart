import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';

/// An ambiance-aware animated radial glow widget that renders an organic, continuous
/// ambient glow powered by multi-frequency noise trigonometric wave interference.
///
/// Screening Room (Dark): Gold/copper warm aurora glow (`Color(0xFFCBA86A)`, `Color(0xFFD69784)`).
/// Violet Dusk (Dark): Rose-magenta twilight glow (`Color(0xFFC2528F)`, `Color(0xFFF4D9E8)`).
/// Midnight Cinema (Dark): Cyan/magenta neon marquee glow (`Color(0xFF0096C7)`, `Color(0xFFD6409F)`).
class AmbientGlowWidget extends StatefulWidget {
  final Widget? child;
  final Duration duration;
  final Color? color1;
  final Color? color2;
  final Color? baseColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;
  final bool? enableAnimation;

  const AmbientGlowWidget({
    super.key,
    this.child,
    this.duration = const Duration(seconds: 15),
    this.color1,
    this.color2,
    this.baseColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.padding,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
    this.enableAnimation,
  });

  @override
  State<AmbientGlowWidget> createState() => _AmbientGlowWidgetState();
}

class _AmbientGlowWidgetState extends State<AmbientGlowWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    final isTestEnvironment =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final shouldAnimate = widget.enableAnimation ?? !isTestEnvironment;
    if (shouldAnimate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.ambianceColors.isDark;

    final effectiveColor1 = widget.color1 ??
        (context.ambianceColors.glow1);
    final effectiveColor2 = widget.color2 ??
        (context.ambianceColors.glow2);

    final effectiveBaseColor = widget.baseColor ??
        context.ambianceColors.card.withValues(alpha: isDark ? 0.65 : 0.75);

    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(16);

    final glowBackground = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _OrganicNoisePainter(
            progress: _animation.value,
            color1: effectiveColor1,
            color2: effectiveColor2,
            baseColor: effectiveBaseColor,
            borderRadius: effectiveBorderRadius,
            isDark: isDark,
          ),
        );
      },
    );

    Widget content = Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: glowBackground,
          ),
        ),
        if (widget.child != null)
          Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.child!,
          ),
      ],
    );

    if (widget.border != null || widget.boxShadow != null) {
      content = Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          border: widget.border,
          boxShadow: widget.boxShadow,
        ),
        clipBehavior: widget.clipBehavior,
        child: content,
      );
    } else if (widget.margin != null) {
      content = Padding(
        padding: widget.margin!,
        child: content,
      );
    }

    return content;
  }
}

/// Organic noise painter implementing harmonic trigonometric wave interference equations.
class _OrganicNoisePainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;
  final Color baseColor;
  final BorderRadius borderRadius;
  final bool isDark;

  _OrganicNoisePainter({
    required this.progress,
    required this.color1,
    required this.color2,
    required this.baseColor,
    required this.borderRadius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas.save();
    canvas.clipRRect(rrect);

    // Base ambiance background color
    final basePaint = Paint()..color = baseColor;
    canvas.drawRect(rect, basePaint);

    // Multi-frequency phase harmonics for organic turbulence
    final phase1 = progress * 2.0 * math.pi;
    final phase2 = (progress * 1.5 + 0.33) * 2.0 * math.pi;
    final phase3 = (progress * 2.2 + 0.66) * 2.0 * math.pi;

    // Organic orbital non-linear translation (slow center position drift)
    final offsetX1 = 0.3 * math.sin(phase1) + 0.2 * math.cos(phase2);
    final offsetY1 = 0.3 * math.cos(phase1) + 0.2 * math.sin(phase3);

    final center1 = Alignment(
      -0.2 + offsetX1,
      -0.3 + offsetY1,
    );

    // Gradient expansion (~1.5 to 1.8 radius factor)
    final radius1 = 1.6 + 0.10 * math.sin(phase2);

    // VISIBILITY-PASS (2026-08-29, dev feedback: glow "barely visible" on a
    // real Android device, not just a per-theme color-contrast issue --
    // bumped from 0.22/0.18 for more baseline presence everywhere. Still
    // unverified live on-device this session; re-check once the phone
    // reconnects and tune further if it's still too subtle in a real room).
    // Strictly constant brightness peak with zero phase-based alpha pulsing
    final peak1 = isDark ? 0.30 : 0.24;
    final paint1 = Paint()
      ..shader = RadialGradient(
        center: center1,
        radius: radius1,
        colors: [
          color1.withValues(alpha: peak1),
          color1.withValues(alpha: peak1 * 0.85),
          color1.withValues(alpha: peak1 * 0.55),
          color1.withValues(alpha: peak1 * 0.20),
          color1.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.30, 0.60, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint1);

    // Secondary organic turbulence wave center drift
    final offsetX2 = 0.35 * math.cos(phase3) - 0.15 * math.sin(phase1);
    final offsetY2 = 0.35 * math.sin(phase2) - 0.15 * math.cos(phase3);

    final center2 = Alignment(
      0.3 + offsetX2,
      0.4 + offsetY2,
    );

    // Gradient expansion (~1.5 to 1.8 radius factor)
    final radius2 = 1.65 - 0.10 * math.cos(phase1);

    // Strictly constant brightness peak with zero phase-based alpha pulsing
    // (see VISIBILITY-PASS note above -- bumped from 0.19/0.15)
    final peak2 = isDark ? 0.26 : 0.20;
    final paint2 = Paint()
      ..shader = RadialGradient(
        center: center2,
        radius: radius2,
        colors: [
          color2.withValues(alpha: peak2),
          color2.withValues(alpha: peak2 * 0.85),
          color2.withValues(alpha: peak2 * 0.55),
          color2.withValues(alpha: peak2 * 0.20),
          color2.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.30, 0.60, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint2);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrganicNoisePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2 ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isDark != isDark;
  }
}
