import 'package:flutter/material.dart';
import '../constants.dart';
import 'pressable_scale.dart';

class AnimatedSegmentedControl<T> extends StatelessWidget {
  final List<T> items;
  final T selectedItem;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  const AnimatedSegmentedControl({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final count = items.length;
    final selectedIndex = items.indexOf(selectedItem);
    final alignmentX = count <= 1 ? -1.0 : -1.0 + (selectedIndex / (count - 1)) * 2.0;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: context.ambianceColors.pill,
        border: Border.all(color: context.ambianceColors.lineRgba, width: 1.0),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(3),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: AppPhysics.houseSpringDuration,
            curve: AppPhysics.houseSpringCurve,
            alignment: Alignment(alignmentX, 0.0),
            child: FractionallySizedBox(
              widthFactor: count > 0 ? 1.0 / count : 1.0,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: context.ambianceColors.acc,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: context.ambianceColors.acc.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: items.map((item) {
              final isSelected = item == selectedItem;
              return Expanded(
                child: PressableScale(
                  onTap: () => onSelected(item),
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.transparent,
                    child: AnimatedDefaultTextStyle(
                      duration: AppPhysics.houseSpringDuration,
                      curve: AppPhysics.houseSpringCurve,
                      style: AppThemes.safeGeist(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.onPrimary 
                            : context.ambianceColors.sub,
                      ),
                      child: Text(
                        labelBuilder(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
