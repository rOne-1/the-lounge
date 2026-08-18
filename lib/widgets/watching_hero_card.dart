import 'package:flutter/material.dart';
import '../constants.dart';
import 'pressable_scale.dart';

/// YSR-COMP-3: A full-width hero banner highlighting active viewing ("Watching").
/// Features an electric blue overline badge, title, live count subtitle, and a
/// trailing 3-layer perspective card stack silhouette.
class WatchingHeroCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const WatchingHeroCard({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    const accentBlue = AppStatusColors.watching;
    final isDark = colors.isDark;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 22.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: accentBlue.withValues(alpha: isDark ? 0.38 : 0.45),
            width: 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.card,
              accentBlue.withValues(alpha: isDark ? 0.10 : 0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accentBlue.withValues(alpha: isDark ? 0.16 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Content: Overline badge, Title, Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: accentBlue.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentBlue.withValues(alpha: 0.45),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: accentBlue,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CONTINUE WATCHING',
                        style: AppThemes.safeGeist(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentBlue,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Watching',
                    style: AppThemes.safeGeist(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == 0
                        ? 'No titles in progress'
                        : '$count title${count == 1 ? '' : 's'} in progress',
                    style: AppThemes.safeGeist(
                      fontSize: 13.5,
                      color: colors.sub,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right Visual: 3-layer perspective card stack silhouette
            _CardStackSilhouette(accentColor: accentBlue, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _CardStackSilhouette extends StatelessWidget {
  final Color accentColor;
  final bool isDark;

  const _CardStackSilhouette({
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? const Color(0xFF1B2230)
        : const Color(0xFFE2E8F0);
    final cardBorder = accentColor.withValues(alpha: isDark ? 0.25 : 0.35);

    return SizedBox(
      width: 90,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Card 1 (Left tilt)
          Positioned(
            left: 2,
            top: 6,
            child: Transform.rotate(
              angle: -0.14,
              child: Container(
                width: 42,
                height: 62,
                decoration: BoxDecoration(
                  color: cardBg.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardBorder.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),
          // Background Card 2 (Right tilt)
          Positioned(
            right: 2,
            top: 6,
            child: Transform.rotate(
              angle: 0.14,
              child: Container(
                width: 42,
                height: 62,
                decoration: BoxDecoration(
                  color: cardBg.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardBorder.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),
          // Center Foreground Card
          Positioned(
            child: Container(
              width: 48,
              height: 68,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.7 : 0.8),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppStatusColors.watching,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
