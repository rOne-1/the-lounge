import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';

/// ANLY-SHARE-1: the offscreen-rendered summary card captured via
/// `RenderRepaintBoundary.toImage()` for [shareImageFile]. Fixed size
/// (not responsive) since it's never actually displayed on screen -- only
/// painted, off-canvas, purely to be captured as a PNG.
class AnalyticsShareCard extends StatelessWidget {
  final AnalyticsResult result;

  const AnalyticsShareCard({super.key, required this.result});

  String? _topEntryName(Map<String, int> freq) {
    if (freq.isEmpty) return null;
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final totalHours = (result.timeInvestment.totalMinutes / 60).round();
    final topGenre = _topEntryName(result.genreFrequency);
    final topDirector = result.directorRanking.isNotEmpty ? result.directorRanking.first.name : null;
    final topActor = result.castRanking.isNotEmpty ? result.castRanking.first.name : null;

    return Container(
      width: 800,
      height: 1000,
      padding: const EdgeInsets.all(56),
      decoration: BoxDecoration(
        color: colors.base,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(colors.acc.withValues(alpha: 0.12), colors.base),
            colors.base,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THE LOUNGE',
                style: AppThemes.safeGeist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.acc,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'My Watching Habits',
                style: GoogleFonts.bodoniModa(
                  fontSize: 46,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  color: colors.ink,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatRow(value: '$totalHours', label: 'Hours Watched'),
              if (topGenre != null) _StatRow(value: topGenre, label: 'Top Genre'),
              if (topDirector != null) _StatRow(value: topDirector, label: 'Top Director'),
              if (topActor != null) _StatRow(value: topActor, label: 'Top Actor'),
            ],
          ),
          Text(
            'Generated on-device -- the-lounge app',
            style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String value;
  final String label;

  const _StatRow({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              value,
              style: GoogleFonts.bodoniModa(
                fontSize: 40,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: colors.acc,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: AppThemes.safeGeist(fontSize: 16, color: colors.sub),
          ),
        ],
      ),
    );
  }
}
