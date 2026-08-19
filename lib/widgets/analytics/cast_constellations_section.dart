import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';

/// ANLY-TASTE-1: ranks the user's most-frequently-watched directors and
/// actors. Reflects only the top-billed cast/primary director captured
/// per saved title (see MediaItem.cast/director), not full credits -- a
/// real scope limit of the stored data, called out in copy rather than
/// silently implied as complete.
class CastConstellationsSection extends StatelessWidget {
  final List<NameCount> directorRanking;
  final List<NameCount> castRanking;

  const CastConstellationsSection({
    super.key,
    required this.directorRanking,
    required this.castRanking,
  });

  static const int _topN = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (directorRanking.isEmpty && castRanking.isEmpty) {
      return Text(
        'Watch a few more titles to see your most-watched people.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (directorRanking.isNotEmpty)
              Expanded(
                child: _RankedList(
                  title: 'Top Directors',
                  entries: directorRanking.take(_topN).toList(),
                ),
              ),
            if (directorRanking.isNotEmpty && castRanking.isNotEmpty)
              const SizedBox(width: 16),
            if (castRanking.isNotEmpty)
              Expanded(
                child: _RankedList(
                  title: 'Top Actors',
                  entries: castRanking.take(_topN).toList(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Based on the top-billed cast and primary director captured per '
          'title -- not full credits.',
          style: AppThemes.safeGeist(fontSize: 11, color: colors.sub),
        ),
      ],
    );
  }
}

class _RankedList extends StatelessWidget {
  final String title;
  final List<NameCount> entries;

  const _RankedList({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.bodoniModa(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in entries)
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
