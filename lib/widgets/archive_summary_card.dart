import 'package:flutter/material.dart';
import '../constants.dart';
import 'pressable_scale.dart';

/// YSR-COMP-3: A 2x2 grid summary card representing an archive shelf.
/// Features a status icon badge, a prominent Bodoni Moda italic count numeral,
/// status-tinted luxury gradient background, and responsive typography.
/// Fully dynamic and theme-isolated via AmbianceColors & AppStatusColors.
class ArchiveSummaryCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color statusColor;
  final VoidCallback onTap;

  /// Overrides the big numeral's displayed text without lying about [count]
  /// being a real zero -- e.g. a placeholder dash when there isn't enough
  /// data to compute a meaningful value yet.
  final String? countLabelOverride;

  const ArchiveSummaryCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.statusColor,
    required this.onTap,
    this.countLabelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final isDark = colors.isDark;

    // BETA3-A11Y-2: group the numeral, label, and subtitle into one
    // coherent announcement instead of 3 disconnected fragments.
    final semanticLabel = '${countLabelOverride ?? '$count'} $label, $subtitle';

    return PressableScale(
      onTap: onTap,
      child: Semantics(
        label: semanticLabel,
        button: true,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(
              color: statusColor.withValues(alpha: isDark ? 0.32 : 0.40),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      statusColor.withValues(alpha: 0.12),
                      colors.card,
                    ]
                  : [
                      statusColor.withValues(alpha: 0.08),
                      colors.card,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              if (isDark)
                BoxShadow(
                  color: colors.surfaceHighlight,
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                  blurStyle: BlurStyle.inner,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon Squircle Badge (left) & Large Bodoni Italic Count (right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          statusColor.withValues(alpha: isDark ? 0.18 : 0.14),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        countLabelOverride ?? '$count',
                        style: AppThemes.display(
                          context,
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          color: statusColor,
                          height: 0.95,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Column: Label & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: AppThemes.safeGeist(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      style: AppThemes.safeGeist(
                        fontSize: 12.5,
                        color: colors.sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
