import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';

/// ANLY-TASTE-2: compares personal rating (mapped onto weightedRatingOf's
/// 0-10 scale via AnalyticsConstants.personalRatingPoints) against the
/// app's Bayesian weightedRating, for the titles that diverge from
/// consensus the most in either direction.
///
/// Hand-built horizontal rows rather than fl_chart's vertical BarChart --
/// full movie titles read as vertical-axis labels far more legibly than
/// truncated bottom-axis labels ever could, and a hand-built axis sidesteps
/// fl_chart's tick generator producing duplicate boundary values entirely.
class RatingDivergenceSection extends StatelessWidget {
  final List<RatingDivergencePoint> points;

  const RatingDivergenceSection({super.key, required this.points});

  static const int _topN = 7;

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (points.isEmpty) {
      return Text(
        'Rate a few watched titles to see how your taste compares to '
        'the consensus.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    final sorted = List<RatingDivergencePoint>.from(points)
      ..sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    final top = sorted.take(_topN).toList();
    final maxAbs = top
        .map((p) => p.delta.abs())
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < top.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DivergenceRow(point: top[i], maxAbs: maxAbs),
          )
              .animate()
              .fadeIn(
                duration: AppPhysics.houseSpringDuration,
                curve: AppPhysics.houseSpringCurve,
                delay: (i.clamp(0, 6) * 40).ms,
              )
              .slideX(
                begin: -0.06,
                end: 0,
                duration: AppPhysics.houseSpringDuration,
                curve: AppPhysics.houseSpringCurve,
                delay: (i.clamp(0, 6) * 40).ms,
              ),
      ],
    );
  }
}

class _DivergenceRow extends StatelessWidget {
  final RatingDivergencePoint point;
  final double maxAbs;

  const _DivergenceRow({required this.point, required this.maxAbs});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final isPositive = point.delta >= 0;
    final sign = isPositive ? '+' : '';

    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            point.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.safeGeist(fontSize: 12, color: colors.ink),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final halfWidth = constraints.maxWidth / 2;
              final barWidth = (point.delta.abs() / maxAbs) * halfWidth;
              return SizedBox(
                height: 18,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      child: Container(width: 1.5, color: colors.lineRgba),
                    ),
                    Positioned(
                      left: isPositive ? halfWidth : halfWidth - barWidth,
                      width: barWidth,
                      top: 3,
                      bottom: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.acc,
                          borderRadius: BorderRadius.horizontal(
                            left: isPositive ? Radius.zero : const Radius.circular(4),
                            right: isPositive ? const Radius.circular(4) : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            '$sign${point.delta.toStringAsFixed(1)}',
            textAlign: TextAlign.right,
            style: AppThemes.safeGeist(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.sub,
            ),
          ),
        ),
      ],
    );
  }
}
