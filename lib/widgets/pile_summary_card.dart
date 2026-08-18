import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'pressable_scale.dart';

/// YSR-COMP-3: A 2x2 grid summary card representing a status pile.
/// Features a status icon badge, a prominent Bodoni Moda italic count numeral,
/// and responsive typography consuming [AmbianceColors] and [AppStatusColors].
class PileSummaryCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color statusColor;
  final VoidCallback onTap;

  const PileSummaryCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.isDark
                  ? const Color(0x22000000)
                  : const Color(0x0A000000),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon Badge (left) & Large Bodoni Italic Count (right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(11.0),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: statusColor,
                    size: 19,
                  ),
                ),
                Text(
                  '$count',
                  style: GoogleFonts.bodoniModa(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: statusColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Bottom Column: Label & Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppThemes.safeGeist(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    color: colors.sub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
