import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';

/// EXP-GLOBAL-3: recurring production companies/studios across watched
/// titles.
class StudioAffinitySection extends StatelessWidget {
  final StudioAffinity studioAffinity;

  const StudioAffinitySection({super.key, required this.studioAffinity});

  static const int _topN = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (studioAffinity.studios.isEmpty) {
      return Text(
        'Watch a few more titles to see your studio affinity.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    final top = studioAffinity.studios.take(_topN).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in top)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.name,
                    style: AppThemes.safeGeist(fontSize: 13, color: colors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.acc.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${entry.count}',
                    style: AppThemes.safeGeist(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: colors.acc,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
