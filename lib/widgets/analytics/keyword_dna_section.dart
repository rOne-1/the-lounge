import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../constants/analytics_constants.dart';

/// DATA-CONT-3: tag-cloud of keyword frequency across completed watch
/// history, capped to the top N keywords for legibility.
///
/// Unlike [GenreDnaSection]'s radar chart -- a good fit for TMDB's small,
/// fixed genre taxonomy -- keywords are a long-tail, effectively unbounded
/// vocabulary, so a weighted pill cloud (size/opacity scaled by frequency)
/// reads better here than forcing them onto a handful of radar axes.
class KeywordDnaSection extends StatelessWidget {
  final Map<String, int> keywordAffinity;

  const KeywordDnaSection({super.key, required this.keywordAffinity});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (keywordAffinity.isEmpty) {
      return Text(
        'Watch a few more titles to see your keyword profile.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    final sorted = keywordAffinity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(AnalyticsConstants.keywordDnaTopN).toList();
    final maxCount = top.first.value;
    final minCount = top.last.value;
    final range = (maxCount - minCount).clamp(1, maxCount);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in top)
          Builder(builder: (context) {
            // Weight [0.0, 1.0] within this top-N batch's own count range,
            // not the raw count -- keeps the cloud legible whether the
            // user has 3 rewatched keywords or 300 lightly-watched ones.
            final weight = (entry.value - minCount) / range;
            final fontSize = 12.0 + (weight * 5.0);
            final alpha = 0.12 + (weight * 0.18);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.acc.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                entry.key,
                style: AppThemes.safeGeist(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: colors.acc,
                ),
              ),
            );
          }),
      ],
    );
  }
}
