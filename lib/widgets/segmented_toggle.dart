import 'package:flutter/material.dart';
import '../providers/navigation_provider.dart';
import '../constants.dart';
import 'pressable_scale.dart';

class SegmentedMediaTypeToggle extends StatelessWidget {
  final MediaTypeToggle activeType;
  final ValueChanged<MediaTypeToggle> onChanged;
  final bool isDark;
  final double segmentWidth;
  final double height;
  final double fontSize;

  const SegmentedMediaTypeToggle({
    super.key,
    required this.activeType,
    required this.onChanged,
    required this.isDark,
    this.segmentWidth = 68.0,
    this.height = 32.0,
    this.fontSize = 12.5,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.srPill : AppColors.rrPill;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final onAccColor = isDark ? const Color(0xFF1A140C) : Colors.white;
    final isMovies = activeType == MediaTypeToggle.movies;

    return Container(
      width: segmentWidth * 2 + 6,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(3),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            alignment: isMovies ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  color: accColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  onTap: () => onChanged(MediaTypeToggle.movies),
                  child: Container(
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOutCubic,
                      style: AppThemes.safeGeist(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: isMovies ? onAccColor : subColor,
                      ),
                      child: const Text('Movies'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PressableScale(
                  onTap: () => onChanged(MediaTypeToggle.tv),
                  child: Container(
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOutCubic,
                      style: AppThemes.safeGeist(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: !isMovies ? onAccColor : subColor,
                      ),
                      child: const Text('TV'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

