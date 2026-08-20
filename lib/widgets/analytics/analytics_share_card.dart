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

    final stats = [
      _StatEntry(value: '$totalHours', label: 'Hours Watched'),
      if (topGenre != null) _StatEntry(value: topGenre, label: 'Top Genre'),
      if (topDirector != null) _StatEntry(value: topDirector, label: 'Top Director'),
      if (topActor != null) _StatEntry(value: topActor, label: 'Top Actor'),
    ];

    return Container(
      width: 800,
      height: 1000,
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
      child: Stack(
        children: [
          // Subtle watermark anchoring the composition -- deliberately
          // clipped/oversized and low-opacity so it reads as texture, not
          // as a second focal point competing with the real stats.
          Positioned(
            right: -70,
            bottom: -40,
            child: Opacity(
              opacity: 0.07,
              child: Image.asset(
                'assets/icons/doorway_emblem.png',
                width: 460,
                height: 460,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
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
                _StatGrid(stats: stats),
                Text(
                  'Generated on-device -- the-lounge app',
                  style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatEntry {
  final String value;
  final String label;

  const _StatEntry({required this.value, required this.label});
}

/// Balanced 2-per-row grid instead of a single tall column -- a column of
/// up to 4 short stat rows left roughly half the card's width as dead
/// space; pairing them up fills the composition properly.
class _StatGrid extends StatelessWidget {
  final List<_StatEntry> stats;

  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += 2) {
      final second = i + 1 < stats.length ? stats[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 34),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StatCell(entry: stats[i])),
              const SizedBox(width: 24),
              Expanded(child: second != null ? _StatCell(entry: second) : const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _StatCell extends StatelessWidget {
  final _StatEntry entry;

  const _StatCell({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.value,
          style: GoogleFonts.bodoniModa(
            fontSize: 36,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            color: colors.acc,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          entry.label,
          style: AppThemes.safeGeist(fontSize: 15, color: colors.sub),
        ),
      ],
    );
  }
}
