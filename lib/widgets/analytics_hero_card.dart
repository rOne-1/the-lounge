import 'package:flutter/material.dart';
import '../constants.dart';
import '../utils/relative_time.dart';
import 'pressable_scale.dart';

/// ANLY-HUB-1: full-width hero banner on the Lounge landing screen, the
/// entry point into the Analytics epic. Deliberately a sibling to
/// [WatchingHeroCard] rather than a reuse-via-parameter of it --
/// WatchingHeroCard is tightly coupled to AppStatusColors.watching and its
/// poster-stack decoration, neither of which apply here. Uses the active
/// ambiance's own accent color (not a fixed status color), so the banner
/// reflects whichever Hall theme is active (SP-2 -- Ambiance-Aware
/// Palettes applies to this entry point too, not just the charts inside).
class AnalyticsHeroCard extends StatelessWidget {
  final DateTime? generatedAt;
  final VoidCallback onTap;

  const AnalyticsHeroCard({
    super.key,
    required this.generatedAt,
    required this.onTap,
  });

  String get _subtitle {
    final at = generatedAt;
    if (at == null) return 'Discover your watching habits';
    return 'Last updated ${formatRelativeTime(at)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final accent = colors.acc;
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
            color: accent.withValues(alpha: isDark ? 0.35 : 0.45),
            width: 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color.alphaBlend(accent.withValues(alpha: 0.16), colors.card),
                    colors.card,
                  ]
                : [
                    Color.alphaBlend(accent.withValues(alpha: 0.08), colors.card),
                    colors.card,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
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
                          color: accent.withValues(alpha: isDark ? 0.22 : 0.18),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.40),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.insights_rounded,
                          color: accent,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'THE THIRD CORE',
                            style: AppThemes.safeGeist(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: accent,
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
                      'Analytics',
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
                      _subtitle,
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  accent.withValues(alpha: isDark ? 0.22 : 0.14),
                  colors.card2,
                ),
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.40 : 0.50),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_graph_rounded,
                color: accent,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
