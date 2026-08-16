import 'package:flutter/material.dart';
import '../constants.dart';

/// A custom thumb: a solid accent-colored core with a soft glow halo,
/// replacing the stock Material thumb/overlay entirely.
class _LoungeThumbShape extends SliderComponentShape {
  static const double thumbRadius = 7;
  const _LoungeThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(thumbRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final accent = sliderTheme.thumbColor ?? Colors.white;

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, thumbRadius * 2.1, glowPaint);

    canvas.drawCircle(center, thumbRadius, Paint()..color = accent);
    canvas.drawCircle(
      center,
      thumbRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

SliderThemeData _loungeSliderTheme(BuildContext context) {
  final ambiance = context.ambianceColors;
  return SliderThemeData(
    trackHeight: 3,
    activeTrackColor: ambiance.acc,
    inactiveTrackColor: ambiance.card2,
    thumbColor: ambiance.acc,
    overlayColor: ambiance.acc.withValues(alpha: 0.15),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
    thumbShape: const _LoungeThumbShape(),
    trackShape: const RoundedRectSliderTrackShape(),
    valueIndicatorColor: ambiance.card2,
    valueIndicatorTextStyle: AppThemes.safeGeist(color: ambiance.ink, fontSize: 12),
  );
}

/// The app's bespoke slider: slim ambiance-toned track, glow-halo thumb --
/// the single canonical replacement for the stock Material [Slider].
class LoungeSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const LoungeSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: _loungeSliderTheme(context),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

/// The bespoke range variant, same track/thumb treatment as [LoungeSlider].
class LoungeRangeSlider extends StatelessWidget {
  final RangeValues values;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<RangeValues> onChanged;

  const LoungeRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: _loungeSliderTheme(context),
      child: RangeSlider(
        values: values,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}
