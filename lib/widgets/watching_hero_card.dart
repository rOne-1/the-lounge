import 'package:flutter/material.dart';
import '../constants.dart';
import 'pressable_scale.dart';

/// YSR-COMP-3: A full-width hero banner highlighting active viewing ("Watching").
/// Features a luxury gradient background, 2-line electric blue overline badge,
/// bold title, live progress subtitle, and a 3-poster depth silhouette stack.
/// Fully dynamic, responsive, and theme-isolated via AmbianceColors & AppStatusColors.
class WatchingHeroCard extends StatelessWidget {
  final int count;
  final String? subtitle;
  final VoidCallback onTap;

  const WatchingHeroCard({
    super.key,
    required this.count,
    this.subtitle,
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
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: accentBlue.withValues(alpha: isDark ? 0.35 : 0.45),
            width: 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color.alphaBlend(accentBlue.withValues(alpha: 0.16), colors.card),
                    colors.card,
                  ]
                : [
                    Color.alphaBlend(accentBlue.withValues(alpha: 0.08), colors.card),
                    colors.card,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: accentBlue.withValues(alpha: isDark ? 0.18 : 0.10),
              blurRadius: 28,
              offset: const Offset(0, 10),
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
        child: Row(
          children: [
            // Left Content: Overline badge + stacked label, Title, Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accentBlue.withValues(alpha: isDark ? 0.22 : 0.18),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: accentBlue.withValues(alpha: 0.40),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: accentBlue,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CONTINUE WATCHING',
                            style: AppThemes.safeGeist(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: accentBlue,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Watching',
                      style: AppThemes.safeGeist(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle ?? (count == 1 ? '1 title in progress' : '$count titles in progress'),
                      style: AppThemes.safeGeist(
                        fontSize: 13.5,
                        color: colors.sub,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right: 3-Poster Depth Silhouette Stack
            _PosterStack(
              accentColor: accentBlue,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterStack extends StatelessWidget {
  final Color accentColor;
  final bool isDark;

  const _PosterStack({
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final posterBg = Color.alphaBlend(
      accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
      colors.card2,
    );
    final centerBg = Color.alphaBlend(
      accentColor.withValues(alpha: isDark ? 0.38 : 0.26),
      colors.card2,
    );

    return SizedBox(
      width: 114,
      height: 74,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Poster Silhouette
          Container(
            width: 32,
            height: 54,
            decoration: BoxDecoration(
              color: posterBg.withValues(alpha: isDark ? 0.75 : 0.85),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.18 : 0.25),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.scrim.withValues(alpha: isDark ? 0.4 : 0.09),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Center Elevated Poster Silhouette
          Container(
            width: 36,
            height: 62,
            decoration: BoxDecoration(
              color: centerBg,
              borderRadius: BorderRadius.circular(7.0),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.45 : 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: colors.scrim.withValues(alpha: isDark ? 0.6 : 0.13),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Right Poster Silhouette
          Container(
            width: 32,
            height: 54,
            decoration: BoxDecoration(
              color: posterBg.withValues(alpha: isDark ? 0.75 : 0.85),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.18 : 0.25),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.scrim.withValues(alpha: isDark ? 0.4 : 0.09),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
