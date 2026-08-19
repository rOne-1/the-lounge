import 'package:flutter/material.dart';
import '../constants.dart';
import 'pressable_scale.dart';

/// D-2: shared selection-chip pill used by Search's filter panels (Genre,
/// Provider, Network, Language) -- `PressableScale -> AnimatedContainer`
/// with a house-spring size/decoration transition, filled with
/// `AmbianceColors.primaryButtonDecoration` (accent-bordered) when
/// selected, or a plain pill outline otherwise.
///
/// Deliberately does NOT cover HallSelectorSheet's `_LanguageChip` /
/// theme-swatch chips: those use a different visual language entirely
/// (tinted accent fill instead of solid primary, a smaller border radius,
/// no spring animation) -- unifying them would be a real design decision,
/// not a value-preserving extraction.
class LoungeFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color pillColor;
  final Color lineRgba;

  const LoungeFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.pillColor,
    required this.lineRgba,
  });

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;
    final decoration = isSelected
        ? ambiance.primaryButtonDecoration
            .copyWith(borderRadius: BorderRadius.circular(999))
            .copyWith(border: Border.all(color: ambiance.acc, width: 1.0))
        : BoxDecoration(
            color: pillColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: lineRgba, width: 1.0),
          );

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: decoration,
        child: Text(
          label,
          style: AppThemes.safeGeist(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : ambiance.ink,
          ),
        ),
      ),
    );
  }
}
