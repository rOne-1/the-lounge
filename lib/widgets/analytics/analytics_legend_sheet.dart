import 'package:flutter/material.dart';
import '../../constants.dart';
import '../drag_to_dismiss_sheet.dart';
import '../pressable_scale.dart';

/// A quick-reference glossary explaining every metric on the Analytics
/// screen, matching the app's established "Legend" bottom-sheet convention
/// (see `discover_screen.dart`'s own Legend, which this mirrors) rather
/// than inventing a new explainer pattern.
Future<void> showAnalyticsLegendSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.ambianceColors.scrim,
    builder: (context) => DragToDismissSheet(
      isDark: context.ambianceColors.isDark,
      onDismiss: () => Navigator.of(context).pop(),
      child: const _AnalyticsLegendContent(),
    ),
  );
}

class _LegendEntry {
  final String title;
  final String description;
  const _LegendEntry(this.title, this.description);
}

class _LegendGroup {
  final String title;
  final List<_LegendEntry> entries;
  const _LegendGroup(this.title, this.entries);
}

const _legendGroups = [
  _LegendGroup('Temporal', [
    _LegendEntry(
      'Movies / TV Shows',
      'Total hours watched, summed from real per-title runtime. TV is an '
          'estimate: episodes watched × the show\'s average episode '
          'runtime.',
    ),
    _LegendEntry(
      'Watch Activity',
      'A day-by-day map of when you watched something -- darker means '
          'more titles logged that day.',
    ),
    _LegendEntry(
      'Binge Velocity',
      'How many days it typically takes you to finish a season once you '
          'start it, from real per-season start/end dates.',
    ),
    _LegendEntry(
      'Era & Cinema History',
      'Which decades your watched titles are from, and on average how '
          'long after release you actually get to them.',
    ),
    _LegendEntry(
      'Viewing Rhythm',
      'Which days of the week you watch the most, plus whether you lean '
          'toward short features or long epics.',
    ),
  ]),
  _LegendGroup('Taste', [
    _LegendEntry(
      'Cast & Crew',
      'Your most-watched actors and directors, based on top-billed cast '
          'and primary director -- not full credits.',
    ),
    _LegendEntry(
      'Franchise Completion',
      'How far you\'ve gotten through the collections/franchises you\'ve '
          'started, for your 5 most recently watched.',
    ),
    _LegendEntry(
      'Rating Divergence',
      'Where your personal rating disagrees most with the wider '
          'consensus -- positive means you liked it more than average, '
          'negative means less.',
    ),
    _LegendEntry(
      'Genre DNA',
      'A profile of your genre mix across everything you\'ve watched.',
    ),
    _LegendEntry(
      'Global Footprint',
      'The original languages your watched titles were made in.',
    ),
    _LegendEntry(
      'Studios',
      'Production companies that show up again and again across your '
          'watched titles.',
    ),
    _LegendEntry(
      'Discover Selectivity',
      'How you interact with Discover cards -- skipped vs. watchlisted '
          'vs. saved, over roughly the last 6 months.',
    ),
    _LegendEntry(
      'Watchlist Funnel',
      'How many titles have made it from your Watchlist to actually '
          'watched, and how long they typically sat first. Only counts '
          'titles added since this metric shipped.',
    ),
    _LegendEntry(
      'Shelf-Life Drop-Offs',
      'TV shows you started but haven\'t touched in 90+ days, well short '
          'of finishing.',
    ),
  ]),
];

class _AnalyticsLegendContent extends StatelessWidget {
  const _AnalyticsLegendContent();

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        10,
        24,
        24.0 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.base, colors.card],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(top: BorderSide(color: colors.lineRgba)),
        boxShadow: [
          BoxShadow(
            color: colors.surfaceHighlight,
            blurRadius: 0,
            offset: const Offset(0, 1),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What these mean',
            style: AppThemes.display(
              context,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A quick reference for every metric on this screen.',
            style: AppThemes.safeGeist(fontSize: 12.5, color: colors.sub),
          ),
          const SizedBox(height: 18),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final group in _legendGroups) ...[
                    Text(
                      group.title,
                      style: AppThemes.display(
                        context,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final entry in group.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: AppThemes.safeGeist(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.description,
                              style: AppThemes.safeGeist(
                                fontSize: 12,
                                color: colors.sub,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          PressableScale(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: colors.primaryButtonDecoration
                  .copyWith(borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(
                'Got it',
                style: AppThemes.safeGeist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
