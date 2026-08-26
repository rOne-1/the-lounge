import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../constants/app_physics.dart';
import '../themes/ambiance_colors.dart';

/// Alias for [AppNoiseTexture] for convenience.
typedef NoiseTextureOverlay = AppNoiseTexture;

/// An efficient procedural noise/grain texture overlay widget that adds a tactile,
/// material paper/velvet grain feel across the application interface.
///
/// THEME-DEPTH-2: [opacity] and [tint] default to the active theme's own
/// `grainOpacity`/`grainTint` (`AmbianceColors`) rather than one fixed
/// constant, so the grain reads as each theme's own material -- richer,
/// warm-tinted "velvet" on a luxury dark theme, barely-there on an airy
/// light one -- and cross-fades with House Spring physics on theme switch.
/// Pass [opacity]/[tint] explicitly only to override the theme default.
///
/// Blends high-frequency noise using [BlendMode.overlay] (or custom
/// [blendMode]), then washes the result with [tint] via [BlendMode.color]
/// so the same cached grayscale noise tile reads as a different material
/// per theme. Wrapped in an [IgnorePointer] so it never interrupts touch or
/// pointer events.
class AppNoiseTexture extends StatefulWidget {
  final double? opacity;
  final Color? tint;
  final BlendMode blendMode;

  const AppNoiseTexture({
    super.key,
    this.opacity,
    this.tint,
    this.blendMode = BlendMode.overlay,
  });

  @override
  State<AppNoiseTexture> createState() => _AppNoiseTextureState();
}

class _AppNoiseTextureState extends State<AppNoiseTexture> {
  static ui.Image? _cachedNoiseTile;
  static bool _isGeneratingTile = false;

  @override
  void initState() {
    super.initState();
    if (_cachedNoiseTile == null && !_isGeneratingTile) {
      _generateNoiseTile();
    }
  }

  Future<void> _generateNoiseTile() async {
    _isGeneratingTile = true;
    try {
      const int tileSize = 128;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final random = math.Random(42);

      // Mid-gray background base for overlay blend mode
      final basePaint = Paint()..color = const Color(0xFF808080);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, tileSize + 0.0, tileSize + 0.0),
        basePaint,
      );

      final lightPoints = <Offset>[];
      final darkPoints = <Offset>[];

      for (int y = 0; y < tileSize; y++) {
        for (int x = 0; x < tileSize; x++) {
          final val = random.nextDouble();
          if (val > 0.68) {
            lightPoints.add(Offset(x.toDouble(), y.toDouble()));
          } else if (val < 0.32) {
            darkPoints.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }

      final lightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..strokeWidth = 1.0;
      final darkPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..strokeWidth = 1.0;

      canvas.drawPoints(ui.PointMode.points, lightPoints, lightPaint);
      canvas.drawPoints(ui.PointMode.points, darkPoints, darkPaint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(tileSize, tileSize);

      if (mounted) {
        setState(() {
          _cachedNoiseTile = img;
        });
      } else {
        _cachedNoiseTile = img;
      }
    } catch (_) {
      // Fallback painter will render synchronously if tile generation fails or is in test mode
    } finally {
      _isGeneratingTile = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetOpacity = widget.opacity ?? context.ambianceColors.grainOpacity;
    final targetTint = widget.tint ?? context.ambianceColors.grainTint;

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: targetOpacity, end: targetOpacity),
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        builder: (context, animatedOpacity, _) {
          return TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: targetTint, end: targetTint),
            duration: AppPhysics.houseSpringDuration,
            curve: AppPhysics.houseSpringCurve,
            builder: (context, animatedTint, __) {
              return CustomPaint(
                painter: _NoiseTexturePainter(
                  noiseImage: _cachedNoiseTile,
                  opacity: animatedOpacity,
                  tint: animatedTint ?? targetTint,
                  blendMode: widget.blendMode,
                ),
                size: Size.infinite,
              );
            },
          );
        },
      ),
    );
  }
}

class _NoiseTexturePainter extends CustomPainter {
  final ui.Image? noiseImage;
  final double opacity;
  final Color tint;
  final BlendMode blendMode;

  _NoiseTexturePainter({
    required this.noiseImage,
    required this.opacity,
    required this.tint,
    required this.blendMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    if (noiseImage != null) {
      final paint = Paint()
        ..blendMode = blendMode
        ..color = Color.fromRGBO(255, 255, 255, opacity);

      if (tint.a > 0) {
        paint.colorFilter = ColorFilter.mode(tint, BlendMode.color);
      }

      paint.shader = ImageShader(
        noiseImage!,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
      canvas.drawRect(Offset.zero & size, paint);
    } else {
      _paintProceduralFallback(canvas, size);
    }
  }

  void _paintProceduralFallback(Canvas canvas, Size size) {
    final paint = Paint()
      ..blendMode = blendMode
      ..color = Color.fromRGBO(255, 255, 255, opacity);

    if (tint.a > 0) {
      paint.colorFilter = ColorFilter.mode(tint, BlendMode.color);
    }

    final random = math.Random(1337);
    final width = size.width;
    final height = size.height;

    final points = <Offset>[];
    const step = 4.0;
    for (double y = 0; y < height; y += step) {
      for (double x = 0; x < width; x += step) {
        if (random.nextDouble() > 0.5) {
          points.add(Offset(x, y));
        }
      }
    }

    canvas.drawPoints(ui.PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant _NoiseTexturePainter oldDelegate) {
    return oldDelegate.noiseImage != noiseImage ||
        oldDelegate.opacity != opacity ||
        oldDelegate.tint != tint ||
        oldDelegate.blendMode != blendMode;
  }
}
