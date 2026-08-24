import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../providers/analytics_provider.dart';
import '../providers/media_provider.dart';
import '../utils/export_helper.dart';
import '../utils/relative_time.dart';
import '../widgets/analytics/abandoned_shows_section.dart';
import '../widgets/analytics/analytics_legend_sheet.dart';
import '../widgets/analytics/analytics_share_card.dart';
import '../widgets/analytics/binge_velocity_section.dart';
import '../widgets/analytics/cast_constellations_section.dart';
import '../widgets/analytics/collection_completion_section.dart';
import '../widgets/analytics/chronological_heatmap.dart';
import '../widgets/analytics/discover_funnel_section.dart';
import '../widgets/analytics/era_distribution_section.dart';
import '../widgets/analytics/genre_dna_section.dart';
import '../widgets/analytics/language_distribution_section.dart';
import '../widgets/analytics/rating_divergence_section.dart';
import '../widgets/analytics/studio_affinity_section.dart';
import '../widgets/analytics/viewing_rhythm_section.dart';
import '../widgets/analytics/watchlist_funnel_section.dart';
import '../widgets/archive_summary_card.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/lounge_toast.dart';
import '../widgets/pressable_scale.dart';

/// ANLY-SHARE-1: stable across the screen's lifetime (a plain top-level
/// GlobalKey, not per-build) so the offscreen [AnalyticsShareCard]'s
/// RepaintBoundary can be found again when Share is tapped. Only one
/// AnalyticsScreen is ever mounted at a time in this app's navigation, so
/// a single shared key is safe.
final GlobalKey _analyticsShareCardKey = GlobalKey();

/// ANLY-HUB-2: the Analytics epic's hub screen. Follows the Archive/Tools
/// scaffolding convention exactly (custom top-bar, not a stock AppBar;
/// SingleChildScrollView + 720px-constrained content; `isLarge` driving
/// only horizontal padding).
///
/// Three states, gated entirely by [AnalyticsState] (never computed as a
/// side effect of opening this screen -- SP-1):
/// - idle: no result yet -> a ceremonial [AtmosphericEmptyState] with an
///   explicit "Generate Analytics" button. Nothing computes before this tap.
/// - loading: `isGenerating` -> the app's established full-screen loading
///   treatment (plain centered CircularProgressIndicator, matching every
///   other async-load screen in the app -- Discover, Calendar, Search).
/// - results: sectioned metric groups (Temporal, then Taste), a Share
///   action that captures an offscreen [AnalyticsShareCard] as a PNG via
///   [shareImageFile], and a Regenerate action.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: colors.base,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            paddingHorizontal,
            14.0,
            paddingHorizontal,
            // The floating navigation capsule is user-draggable and often
            // rests bottom-right, directly over the Genre DNA radar's right
            // vertex (the final, and widest, section) -- 100px wasn't
            // enough clearance once the radar's own height grew; this
            // leaves genuine room to scroll every chart fully clear of it.
            160.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  if (state.isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.result == null)
                    _buildIdleState(context, ref)
                  else
                    _AnalyticsResults(state: state, ref: ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.ambianceColors;

    return Row(
      children: [
        PressableScale(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.card,
              shape: BoxShape.circle,
              border: Border.all(color: colors.lineRgba),
              boxShadow: [
                BoxShadow(
                  color: colors.scrim
                      .withValues(alpha: colors.isDark ? 0.25 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: colors.ink,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: AppThemes.display(
                  context,
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  color: colors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'On-device insights from your own watch history',
                style: AppThemes.safeGeist(
                  fontSize: 13.5,
                  color: colors.sub,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    // BACKUP-2: a backup import (or account reset) is mid-flight -- data is
    // actively being rewritten underneath this screen, so generating now
    // would either read a half-restored state or race the import's own
    // writes. Withhold the CTA instead of letting it produce a misleading
    // result.
    final isImporting = ref.watch(isDataImportingProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: AtmosphericEmptyState(
        icon: Icons.insights_rounded,
        title: isImporting ? 'Hold on a moment' : 'Ready when you are',
        message: isImporting
            ? 'Your backup is still restoring -- Analytics will be ready to '
                'generate once it finishes.'
            : 'Generate a fresh look at your watching habits -- computed '
                'entirely on this device, only when you ask for it.',
        ctaLabel: isImporting ? null : 'Generate Analytics',
        onCta: isImporting
            ? null
            : () => ref.read(analyticsProvider.notifier).generate(),
      ),
    );
  }
}

class _AnalyticsResults extends StatelessWidget {
  final AnalyticsState state;
  final WidgetRef ref;

  const _AnalyticsResults({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final result = state.result!;
    final movieHours = (result.timeInvestment.movieMinutes / 60).round();
    final tvHours = (result.timeInvestment.tvMinutes / 60).round();
    // BACKUP-2: see _buildIdleState -- same reasoning, applied to
    // Regenerate on an already-visible results view.
    final isImporting = ref.watch(isDataImportingProvider);

    return Stack(
      children: [
        // ANLY-SHARE-1: painted (so RepaintBoundary.toImage() has a real
        // raster to capture) but positioned entirely outside the visible
        // viewport -- Offstage/Opacity(0) both skip painting in modern
        // Flutter, which would make the captured image blank.
        Positioned(
          left: -9999,
          top: 0,
          child: RepaintBoundary(
            key: _analyticsShareCardKey,
            child: AnalyticsShareCard(result: result),
          ),
        ),
        TweenAnimationBuilder<double>(
          key: ValueKey(state.generatedAt),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          builder: (context, t, child) {
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t.clamp(0.0, 1.0)) * 16),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        PressableScale(
                          onTap: () => showAnalyticsLegendSheet(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline,
                                  color: colors.sub, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                'Legend',
                                style: AppThemes.safeGeist(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: colors.sub,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            state.generatedAt != null
                                ? 'Updated ${formatRelativeTime(state.generatedAt!)}'
                                : '',
                            overflow: TextOverflow.ellipsis,
                            style: AppThemes.safeGeist(
                                fontSize: 12.5, color: colors.sub),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PressableScale(
                    onTap: () => _handleShare(context),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.pill,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.lineRgba),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.ios_share_rounded,
                              size: 14, color: colors.ink),
                          const SizedBox(width: 6),
                          Text(
                            'Share',
                            style: AppThemes.safeGeist(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PressableScale(
                    onTap: isImporting
                        ? null
                        : () => ref.read(analyticsProvider.notifier).generate(),
                    child: Opacity(
                      opacity: isImporting ? 0.5 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.pill,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colors.lineRgba),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded,
                                size: 14, color: colors.ink),
                            const SizedBox(width: 6),
                            Text(
                              'Regenerate',
                              style: AppThemes.safeGeist(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: colors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Temporal'),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.16,
                children: [
                  ArchiveSummaryCard(
                    // EXP-CLARITY-1: this numeral is hours, not a title
                    // count -- every other ArchiveSummaryCard in the app
                    // puts an item count in this exact slot -- the first
                    // fix here (relabeling to "Movie Hours") only patched
                    // the label around a numeral that was still hours, not
                    // a count. Dev feedback was explicit: the numeral
                    // itself must be the count, matching every other card.
                    label: 'Movies',
                    subtitle: movieHours == 1
                        ? '1 hour watched'
                        : '$movieHours hours watched',
                    count: result.timeInvestment.movieCount,
                    icon: Icons.local_movies_rounded,
                    statusColor: colors.acc,
                    onTap: () {},
                  ),
                  ArchiveSummaryCard(
                    label: 'TV Shows',
                    subtitle: tvHours == 1
                        ? '~1 hour watched (estimate)'
                        : '~$tvHours hours watched (estimate)',
                    count: result.timeInvestment.tvCount,
                    icon: Icons.live_tv_rounded,
                    statusColor: colors.acc,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Watch Activity',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              ChronologicalHeatmap(data: result.heatmap),
              const SizedBox(height: 20),
              BingeVelocitySection(data: result.bingeVelocity),
              const SizedBox(height: 20),
              Text(
                'Era & Cinema History',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              EraDistributionSection(
                decades: result.decadeDistribution,
                temporalDistance: result.temporalDistanceIndex,
              ),
              const SizedBox(height: 20),
              Text(
                'Viewing Rhythm',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              ViewingRhythmSection(
                dayOfWeek: result.dayOfWeekDistribution,
                runtimePreferences: result.runtimePreferences,
              ),
              const SizedBox(height: 28),
              _SectionHeader(title: 'Taste'),
              const SizedBox(height: 16),
              Text(
                'Cast & Crew',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              CastConstellationsSection(
                directorRanking: result.directorRanking,
                castRanking: result.castRanking,
              ),
              const SizedBox(height: 20),
              Text(
                'Franchise Completion',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              CollectionCompletionSection(
                completions: state.collectionCompletions,
              ),
              const SizedBox(height: 20),
              Text(
                'Rating Divergence',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              RatingDivergenceSection(points: result.ratingDivergence),
              const SizedBox(height: 20),
              Text(
                'Genre DNA',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              GenreDnaSection(genreFrequency: result.genreFrequency),
              const SizedBox(height: 20),
              Text(
                'Global Footprint',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              LanguageDistributionSection(
                  languages: result.languageDistribution),
              const SizedBox(height: 16),
              Text(
                'Studios',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 8),
              StudioAffinitySection(studioAffinity: result.studioAffinity),
              const SizedBox(height: 20),
              Text(
                'Discover Selectivity',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              DiscoverFunnelSection(swipeRatio: result.discoverSwipeRatio),
              const SizedBox(height: 20),
              Text(
                'Watchlist Funnel',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              WatchlistFunnelSection(funnel: result.watchlistFunnel),
              const SizedBox(height: 20),
              Text(
                'Shelf-Life Drop-Offs',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 10),
              AbandonedShowsSection(shows: result.abandonedShows),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      final boundary = _analyticsShareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await shareImageFile(bytes, 'the_lounge_analytics.png');
    } catch (_) {
      if (context.mounted) {
        LoungeToast.show(
          context,
          'Could not create the share image.',
          type: ToastType.danger,
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return Text(
      title,
      style: AppThemes.display(
        context,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
    );
  }
}
