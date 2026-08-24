import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/media_item.dart';
import '../widgets/trailer_player.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/lounge_dropdown.dart';
import '../widgets/lounge_folder_picker_sheet.dart';
import '../widgets/lounge_rating_sheet.dart';
import '../widgets/lounge_rewatch_sheet.dart';
import '../widgets/lounge_toast.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/quick_status_sheet.dart';
import '../widgets/seasonal_rating_bar.dart';
import '../widgets/status_pulse_ring.dart';
import '../widgets/watch_history_timeline.dart';
import '../constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'search_screen.dart';
import 'collection_screen.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final String id;
  final MediaItem? initialItem;

  const DetailScreen({super.key, required this.id, this.initialItem});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isTransitionComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isTransitionComplete = true;
        });
      }
    });
  }

  Future<void> _playTrailer(
    BuildContext context,
    MediaItem item, {
    String? videoId,
    String? videoTitle,
  }) async {
    final vId = videoId ??
        item.trailerVideoId ??
        (item.trailers != null && item.trailers!.isNotEmpty
            ? item.trailers!.first.key
            : null);
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        vId != null &&
        vId.isNotEmpty) {
      final url = Uri.parse('https://www.youtube.com/watch?v=$vId');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrailerPlayer(
          item: item,
          videoId: videoId,
          videoTitle: videoTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(mediaDetailsProvider(widget.id));
    final isDark = context.ambianceColors.isDark;
    final inkColor = context.ambianceColors.ink;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: context.ambianceColors.background,
        child: Scaffold(
          backgroundColor: context.ambianceColors.base,
          appBar: AppBar(
            leading: PressableScale(
              onTap: () => Navigator.maybePop(context),
              child: Icon(Icons.arrow_back, color: inkColor),
            ),
            title: Text(
              'Details',
              style: GoogleFonts.bodoniModa(
                fontStyle: FontStyle.italic,
                color: inkColor,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: inkColor),
          ),
          body: detailAsync.when(
            data: (fetchedItem) {
              final rawItem = fetchedItem ?? widget.initialItem;
              if (rawItem == null) {
                return FullScreenErrorWidget(
                  message: 'Failed to load media details.',
                  onRetry: () =>
                      ref.invalidate(mediaDetailsProvider(widget.id)),
                );
              }
              final item = rawItem.copyWith(
                releaseOrAirDate: rawItem.releaseOrAirDate ??
                    widget.initialItem?.releaseOrAirDate,
                status: rawItem.status ?? widget.initialItem?.status,
              );
              final isLarge = MediaQuery.of(context).size.width > 800;

              if (isLarge) {
                return _buildLargeLayout(context, ref, item, isDark);
              }
              return _buildCompactLayout(context, ref, item, isDark);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              final message = err.toString().replaceAll('Exception: ', '');
              return FullScreenErrorWidget(
                message: message.isNotEmpty
                    ? message
                    : 'Failed to load media details.',
                onRetry: () => ref.invalidate(mediaDetailsProvider(widget.id)),
              );
            },
          ),
        ),
      ),
    );
  }

  /// BETA3-PERF-1: the below-the-fold sections (director/creator credit,
  /// cast strip, trailers, similar titles, keywords, networks, watch
  /// providers) as deferred builder closures, not already-built widgets --
  /// paired with a SliverList.builder below, this means none of these
  /// sections (and none of the network/image loads their MediaCard/rail
  /// content triggers) are even constructed until they scroll near the
  /// viewport, not just laid out. Deliberately NOT wrapped in its own
  /// .animate() fade/slide per item (unlike the eager section above): a
  /// separate flutter_animate instance per lazily-built sliver item left a
  /// pending Timer if the screen was disposed (e.g. rapid tap-then-pop
  /// navigation in a test) before that item's delayed entrance finished,
  /// tripping flutter_test's "Timer still pending after dispose" invariant
  /// -- confirmed live by reproducing and removing it. The scroll itself
  /// already reveals each section, which reads as a reasonable entrance on
  /// its own without stacking a second animation on top.
  List<Widget Function()> _belowFoldSectionBuilders(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    return [
      () => _buildDirectorOrCreatorCredit(context, ref, item, isDark),
      () => _buildCastStrip(context, ref, item, isDark),
      () => _buildTrailersSection(context, item, isDark),
      () => _buildSimilarTitlesSection(context, ref, item, isDark),
      () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              _buildKeywordChips(context, ref, item, isDark),
              _buildNetworksSection(item, isDark),
              _buildWatchProvidersSection(context, ref, item, isDark),
            ],
          ),
    ];
  }

  Widget _buildCompactLayout(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final belowFold = _isTransitionComplete
        ? _belowFoldSectionBuilders(context, ref, item, isDark)
        : const <Widget Function()>[];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHero(context, item, isDark)
              .animate()
              .fade(duration: 250.ms),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.bodoniModa(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: inkColor,
                    height: 1.05,
                  ),
                ),
                if (item.tagline != null &&
                    item.tagline!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${item.tagline}"',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: subColor,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildMetaRow(item, isDark),
                if (item.genres.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildGenreChips(context, ref, item, isDark),
                ],
                if (item.belongsToCollection != null)
                  _buildCollectionBanner(context, item, isDark),
                const SizedBox(height: 18),
                _buildActionButtons(context, ref, item, isDark),
                const SizedBox(height: 22),
                ExpandableOverviewText(
                  text: item.overview,
                  style: AppThemes.safeGeist(
                    fontSize: 14,
                    height: 1.5,
                    color: subColor,
                  ),
                  isDark: isDark,
                ),
                _buildSeasonsSection(context, ref, item, isDark),
                SeasonalRatingBar(item: item),
                _buildWatchHistorySection(context, item, isDark),
              ],
            ).animate(delay: 100.ms).fade(duration: 250.ms).slideY(
                  begin: 0.08,
                  end: 0,
                  curve: AppPhysics.houseSpringCurve,
                ),
          ),
        ),
        if (belowFold.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => belowFold[index](),
                childCount: belowFold.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 24, bottom: 16),
            child: SignatureMotif(),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _buildLargeLayout(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: _buildHero(context, item, isDark)
                .animate()
                .fade(duration: 250.ms),
          ),
        ),
        Expanded(
          flex: 1,
          child: Builder(builder: (paneContext) {
            final belowFold = _isTransitionComplete
                ? _belowFoldSectionBuilders(paneContext, ref, item, isDark)
                : const <Widget Function()>[];

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.bodoniModa(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: inkColor,
                            height: 1.05,
                          ),
                        ),
                        if (item.tagline != null &&
                            item.tagline!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '"${item.tagline}"',
                            style: GoogleFonts.bodoniModa(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: subColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _buildMetaRow(item, isDark),
                        if (item.genres.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildGenreChips(paneContext, ref, item, isDark),
                        ],
                        if (item.belongsToCollection != null)
                          _buildCollectionBanner(paneContext, item, isDark),
                        const SizedBox(height: 24),
                        _buildActionButtons(paneContext, ref, item, isDark),
                        const SizedBox(height: 24),
                        ExpandableOverviewText(
                          text: item.overview,
                          style: AppThemes.safeGeist(
                            fontSize: 15,
                            height: 1.5,
                            color: subColor,
                          ),
                          isDark: isDark,
                        ),
                        _buildSeasonsSection(paneContext, ref, item, isDark),
                        SeasonalRatingBar(item: item),
                        _buildWatchHistorySection(paneContext, item, isDark),
                      ],
                    ).animate(delay: 100.ms).fade(duration: 250.ms).slideY(
                          begin: 0.08,
                          end: 0,
                          curve: AppPhysics.houseSpringCurve,
                        ),
                  ),
                ),
                if (belowFold.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => belowFold[index](),
                        childCount: belowFold.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 16),
                    child: SignatureMotif(),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, MediaItem item, bool isDark) {
    final phColor = context.ambianceColors.ph;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: phColor,
        child: MediaImage(
          item: item,
          imageUrl: item.backdropUrl ?? item.posterUrl,
          fit: BoxFit.cover,
          showFallbackTitle: false,
          memCacheWidth: 800,
          memCacheHeight: 450,
        ),
      ),
    );
  }

  Widget _buildRatingBadge(MediaItem item, bool isDark) {
    // starRating is tuned gold/amber in every theme, so black text reads
    // reliably across all 6 — mirrors the IMDb badge's own black-on-gold text.
    const textColor = Colors.black;

    final String ratingStr;
    if (item.voteCount != null && item.voteCount! > 0) {
      ratingStr =
          '★ ${item.rating.toStringAsFixed(1)} (${_formatVoteCount(item.voteCount!)})';
    } else {
      ratingStr = '★ ${item.rating.toStringAsFixed(1)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.ambianceColors.starRating,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ratingStr,
        style: AppThemes.safeGeist(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  String _formatVoteCount(int count) {
    if (count >= 1000000) {
      final m = count / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M votes';
    } else if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k votes';
    } else {
      return '$count votes';
    }
  }

  Widget _buildMetaRow(MediaItem item, bool isDark) {
    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;

    final metaPills = <Widget>[];

    // Rating badge
    metaPills.add(_buildRatingBadge(item, isDark));

    // Original Language badge
    final langDisplay = item.originalLanguageDisplay;
    if (langDisplay != null && langDisplay.isNotEmpty) {
      metaPills.add(
        _buildMetaPill(
          Icons.language,
          langDisplay,
          phColor,
          lineRgba,
          subColor,
        ),
      );
    }

    // Certification badge
    if (item.certification != null && item.certification!.isNotEmpty) {
      metaPills.add(
        _buildMetaPill(
          Icons.verified_user_outlined,
          item.certification!,
          phColor,
          lineRgba,
          subColor,
        ),
      );
    }

    if (item.type == MediaType.movie) {
      if (item.runtime != null) {
        metaPills.add(
          _buildMetaPill(
            Icons.schedule,
            '${item.runtime} min',
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
      if (item.releaseOrAirDate != null) {
        metaPills.add(
          _buildMetaPill(
            Icons.calendar_today,
            _formatDate(item.releaseOrAirDate!),
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
    } else {
      // TV show
      if (item.status != null && item.status!.isNotEmpty) {
        metaPills.add(
          _buildMetaPill(
            Icons.live_tv,
            item.status!,
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
      if (item.seasonsCount != null) {
        final seasonLabel = item.seasonsCount == 1
            ? '1 Season'
            : '${item.seasonsCount} Seasons';
        metaPills.add(
          _buildMetaPill(
            Icons.layers_outlined,
            seasonLabel,
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
      if (item.episodesCount != null) {
        final episodeLabel = item.episodesCount == 1
            ? '1 Episode'
            : '${item.episodesCount} Episodes';
        metaPills.add(
          _buildMetaPill(
            Icons.video_library_outlined,
            episodeLabel,
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
      if (item.nextEpisodeAirDate != null) {
        metaPills.add(
          _buildMetaPill(
            Icons.upcoming_outlined,
            'Next: ${_formatDate(item.nextEpisodeAirDate!)}',
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
      if (item.releaseOrAirDate != null) {
        metaPills.add(
          _buildMetaPill(
            Icons.calendar_today,
            _formatDate(item.releaseOrAirDate!),
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: metaPills,
    );
  }

  Widget _buildMetaPill(
    IconData icon,
    String text,
    Color bgColor,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppThemes.safeGeist(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChips(
      BuildContext context, WidgetRef ref, MediaItem item, bool isDark) {
    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: item.genres.map((genre) {
        return PressableScale(
          onTap: () {
            ref.read(searchGenreProvider.notifier).setGenre(genre);
            ref.read(searchKeywordProvider.notifier).clearKeyword();
            ref.read(discoverFilterProvider.notifier).setGenre(
                  genreId: getGenreIdForName(genre),
                  genreName: genre,
                );
            ref.read(discoverFilterProvider.notifier).setKeyword(
                  keywordId: null,
                  keywordName: null,
                );
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: phColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: lineRgba),
            ),
            child: Text(
              genre,
              style: AppThemes.safeGeist(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeywordChips(
      BuildContext context, WidgetRef ref, MediaItem item, bool isDark) {
    if (item.keywords == null || item.keywords!.isEmpty) {
      return const SizedBox.shrink();
    }

    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;
    final inkColor = context.ambianceColors.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keywords',
          style: AppThemes.safeGeist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: item.keywords!.map((kw) {
            return PressableScale(
              onTap: () {
                ref.read(searchKeywordProvider.notifier).setKeyword(kw.name);
                ref.read(searchGenreProvider.notifier).setGenre('All');
                ref.read(discoverFilterProvider.notifier).setKeyword(
                      keywordId: kw.id,
                      keywordName: kw.name,
                    );
                ref.read(discoverFilterProvider.notifier).setGenre(
                      genreId: null,
                      genreName: null,
                    );
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: phColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: lineRgba),
                ),
                child: Text(
                  '#${kw.name}',
                  style: AppThemes.safeGeist(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCollectionBanner(
      BuildContext context, MediaItem item, bool isDark) {
    final collection = item.belongsToCollection;
    if (collection == null) return const SizedBox.shrink();

    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;
    final cardBg = context.ambianceColors.card;

    final imageUrl = collection.backdropUrl ?? collection.posterUrl;

    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectionScreen(collectionId: collection.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lineRgba),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.ambianceColors.scrim,
                      context.ambianceColors.scrim.withValues(
                        alpha: context.ambianceColors.scrim.a * 0.6,
                      ),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (collection.posterUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        collection.posterUrl!,
                        width: 48,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 72,
                          color: phColor,
                          child: const Icon(Icons.movie, color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COLLECTION',
                          style: AppThemes.safeGeist(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: context.ambianceColors.acc,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Part of the ${collection.name}',
                                style: GoogleFonts.bodoniModa(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectorOrCreatorCredit(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    final hasDirectors = item.directors != null && item.directors!.isNotEmpty;
    final String label;

    if (hasDirectors) {
      final hasCreators = item.directors!.any((d) => d.role == 'Creator');
      final hasMovieDirectors =
          item.directors!.any((d) => d.role == 'Director');
      if (hasCreators && !hasMovieDirectors) {
        label = item.directors!.length > 1 ? 'Creators' : 'Created by';
      } else if (hasMovieDirectors && !hasCreators) {
        label = item.directors!.length > 1 ? 'Directors' : 'Director';
      } else {
        label = 'Directors & Creators';
      }
    } else if (item.director != null && item.director!.isNotEmpty) {
      label = 'Director';
    } else if (item.createdBy != null && item.createdBy!.isNotEmpty) {
      label = 'Created by';
    } else {
      return const SizedBox.shrink();
    }

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;

    void navigateToPerson(int? pId, String pName) {
      // SEARCH-CAST-1: discoverFilterProvider is a long-lived singleton, so
      // a genre/keyword/rating filter left over from an earlier, unrelated
      // Search session would otherwise silently combine with this person
      // filter and could zero out the filmography results entirely.
      ref.read(discoverFilterProvider.notifier).resetFilters();
      ref.read(discoverFilterProvider.notifier).setPerson(
            personId: pId,
            personName: pName,
          );
      // NAV-2: SearchScreen is pushed as a sub-route on top of wherever the
      // user actually came from -- mutating the root navigationProvider tab
      // here used to silently strand them on the Search tab after popping
      // back out, even if they arrived from Home/Discover/etc.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      );
    }

    Widget contentWidget;
    if (hasDirectors) {
      final directorList = item.directors!;
      contentWidget = Wrap(
        spacing: 12,
        runSpacing: 4,
        children: directorList.map((director) {
          final pId = int.tryParse(director.id);
          return PressableScale(
            onTap: () => navigateToPerson(pId, director.name),
            child: Text(
              director.name,
              style: AppThemes.safeGeist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: inkColor,
              ),
            ),
          );
        }).toList(),
      );
    } else {
      final pName = (item.director != null && item.director!.isNotEmpty)
          ? item.director!
          : item.createdBy!.join(', ');
      final pId = int.tryParse(pName);
      contentWidget = PressableScale(
        onTap: () => navigateToPerson(pId, pName),
        child: Text(
          pName,
          style: AppThemes.safeGeist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: phColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lineRgba),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(Icons.video_camera_front_outlined,
                size: 20, color: subColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppThemes.safeGeist(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 4),
                contentWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarTitlesSection(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    final recsAsync = ref.watch(mediaRecommendationsProvider(item.prefixedId));
    final similarAsync = ref.watch(similarMediaProvider(item.prefixedId));

    final List<MediaItem> items;
    if (recsAsync.hasValue && recsAsync.value!.isNotEmpty) {
      items = recsAsync.value!;
    } else if (similarAsync.hasValue && similarAsync.value!.isNotEmpty) {
      items = similarAsync.value!;
    } else {
      items = const [];
    }

    final inkColor = context.ambianceColors.ink;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;

    return AnimatedSwitcher(
      duration: AppPhysics.houseSpringDuration,
      switchInCurve: AppPhysics.houseSpringCurve,
      switchOutCurve: Curves.easeOut,
      child: items.isEmpty
          ? const SizedBox.shrink(key: ValueKey('similar_titles_empty'))
          : Column(
              key: ValueKey('similar_titles_${item.prefixedId}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Similar titles',
                  style: AppThemes.safeGeist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final similarItem = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: PressableScale(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailScreen(id: similarItem.prefixedId),
                              ),
                            );
                          },
                          onLongPress: () =>
                              showQuickStatusSheet(context, ref, similarItem),
                          child: SizedBox(
                            width: 110,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 110,
                                  height: 155,
                                  decoration: BoxDecoration(
                                    color: phColor,
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(color: lineRgba),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? const Color.fromRGBO(
                                                255, 255, 255, 0.05)
                                            : const Color.fromRGBO(
                                                0, 0, 0, 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: MediaImage(
                                    item: similarItem,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  similarItem.title,
                                  style: AppThemes.safeGeist(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: inkColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNetworksSection(MediaItem item, bool isDark) {
    if (item.networks == null || item.networks!.isEmpty) {
      return const SizedBox.shrink();
    }

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Networks',
          style: AppThemes.safeGeist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: item.networks!.map((net) {
            // DATA-2: network pills were previously inert Containers.
            // Tapping one now filters Search by that network, matching the
            // existing person/cast-crew navigation pattern.
            return PressableScale(
              onTap: () {
                ref.read(discoverFilterProvider.notifier).setTvNetwork(
                      tvNetworkId: net.id,
                      tvNetworkName: net.name,
                    );
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: phColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: lineRgba),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (net.logoUrl != null && net.logoUrl!.isNotEmpty) ...[
                      Image.network(
                        net.logoUrl!,
                        height: 16,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.tv, size: 16, color: subColor),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      Icon(Icons.tv, size: 16, color: subColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      net.name,
                      style: AppThemes.safeGeist(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: inkColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    // PERF-1: ref.watch(mediaProvider) here used to register against the
    // whole DetailScreen Element (this method is just a plain function
    // call within _DetailScreenState.build(), not its own widget), so
    // toggling watch status on ANY item anywhere in the app rebuilt this
    // entire 2000+ line screen -- cast strip, trailers, similar titles,
    // hero, all of it. Wrapping the watch in its own Consumer scopes the
    // rebuild to just this action-buttons subtree.
    return Consumer(
      builder: (context, ref, child) {
        final mediaState = ref.watch(mediaProvider);
        final notifier = ref.read(mediaProvider.notifier);

        final inWatchlist = mediaState.watchlist.containsKey(item.id);
        final inSaved = mediaState.maybeList.containsKey(item.id);
        final inWatching = mediaState.watchingList.containsKey(item.id);
        final inWatched = mediaState.watchedList.containsKey(item.id);
        final inOnHold = mediaState.onHoldList.containsKey(item.id);
        final inDropped = mediaState.droppedList.containsKey(item.id);

        final saveColor = AppStatusColors.save;
        final watchColor = AppStatusColors.watchlist;
        final watchingColor = AppStatusColors.watching;
        final watchedColor = AppStatusColors.watched;
        final onHoldColor = AppStatusColors.onHold;
        final droppedColor = AppStatusColors.dropped;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatusToggle(
                    'Saved',
                    inSaved,
                    saveColor,
                    () => notifier.toggleMaybe(item),
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusToggle(
                    'Watchlist',
                    inWatchlist,
                    watchColor,
                    () => notifier.toggleWatchlist(item),
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatusToggle(
                    'Watching',
                    inWatching,
                    watchingColor,
                    () => notifier.toggleWatching(item),
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: () {
                    final isUnreleased = (item.releaseDate != null &&
                            item.releaseDate!.isAfter(DateTime.now())) ||
                        (item.status != null &&
                            (item.status!.toLowerCase() == 'unreleased' ||
                                item.status!.toLowerCase() == 'in production' ||
                                item.status!.toLowerCase() == 'planned'));
                    final seasons =
                        ref.watch(tvShowSeasonsProvider(item)).value;
                    return _buildStatusToggle(
                      'Watched',
                      inWatched,
                      watchedColor,
                      () {
                        if (isUnreleased) {
                          LoungeToast.show(
                              context, 'This title has not been released yet.');
                          return;
                        }
                        // PERS-RATE-1: auto-prompt for a rating the moment a
                        // title genuinely settles into Watched (not on every
                        // toggle -- re-read state after the mutation rather
                        // than trusting the pre-toggle `inWatched` closure,
                        // since a TV show can land in Watching instead if
                        // unreleased episodes remain).
                        final wasWatched = ref
                            .read(mediaProvider)
                            .watchedList
                            .containsKey(item.id);
                        notifier.toggleWatched(item, seasons: seasons);
                        final isNowWatched = ref
                            .read(mediaProvider)
                            .watchedList
                            .containsKey(item.id);
                        if (!wasWatched && isNowWatched) {
                          final hasRating = findPrimaryWatchRecord(
                                ref.read(mediaProvider).watchHistory,
                                item.id,
                                null,
                              ) !=
                              null;
                          if (!hasRating) {
                            showLoungeRatingSheet(
                              context,
                              ref,
                              item: item,
                              isAutoPrompt: true,
                            );
                          }
                        }
                      },
                      isDark,
                      isDisabled: isUnreleased,
                    );
                  }(),
                ),
              ],
            ),
            // PERS-RATE-1: fixed-position, high-contrast rating banner --
            // was a small pill inline in the meta-info row, whose content
            // (and thus the button's position) differs between movies and
            // TV shows; moving it to its own row right after Watched gives
            // it one consistent, easy-to-spot location for every title.
            // Own top margin is baked into the pill itself (rather than a
            // Padding wrapper here) so it contributes zero extra space when
            // the item isn't Watched yet and the pill renders nothing.
            Consumer(
              builder: (context, ref, _) =>
                  PersonalRatingPill(item: item, expanded: true),
            ),
            const SizedBox(height: 8),
            // Secondary status bar (On-Hold & Dropped options)
            Row(
              children: [
                Expanded(
                  child: _buildStatusToggle(
                    'On-Hold',
                    inOnHold,
                    onHoldColor,
                    () => notifier.toggleOnHold(item),
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusToggle(
                    'Dropped',
                    inDropped,
                    droppedColor,
                    () => notifier.toggleDropped(item),
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildWatchTrailerButton(context, item, isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAddToFolderButton(context, ref, item, isDark),
                ),
              ],
            ),
            if (item.imdbId != null && item.imdbId!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImdbButton(item, isDark),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWatchTrailerButton(
    BuildContext context,
    MediaItem item,
    bool isDark,
  ) {
    final inkColor = context.ambianceColors.ink;
    final accentColor = context.ambianceColors.acc;
    final borderColor =
        isDark ? accentColor.withAlpha(50) : accentColor.withAlpha(50);

    return PressableScale(
      onTap: () => _playTrailer(context, item),
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        height: 44,
        decoration: BoxDecoration(
          color: context.ambianceColors.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow,
                size: 16,
                color: inkColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Watch trailer',
                style: AppThemes.safeGeist(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PERS-FOLDERS-1: opens the status-independent "Add to Folder" picker.
  Widget _buildAddToFolderButton(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    final inkColor = context.ambianceColors.ink;
    final accentColor = context.ambianceColors.acc;
    final borderColor = accentColor.withAlpha(50);

    return PressableScale(
      key: const ValueKey('add_to_folder_button'),
      onTap: () => showFolderPickerSheet(
        context,
        ref,
        mediaId: item.id,
        mediaTitle: item.title,
      ),
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        height: 44,
        decoration: BoxDecoration(
          color: context.ambianceColors.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 16,
                color: inkColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Add to Folder',
                style: AppThemes.safeGeist(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImdbButton(MediaItem item, bool isDark) {
    if (item.imdbId == null || item.imdbId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return PressableScale(
      onTap: () async {
        final url = Uri.parse('https://www.imdb.com/title/${item.imdbId}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.ambianceColors.card2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.ambianceColors.lineRgba,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: context.ambianceColors.starRating,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'IMDb',
                style: AppThemes.safeGeist(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'View on IMDb',
              style: AppThemes.safeGeist(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.ambianceColors.ink,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: context.ambianceColors.sub,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(
    String label,
    bool isSelected,
    Color accentColor,
    VoidCallback onTap,
    bool isDark, {
    bool isDisabled = false,
  }) {
    final textColor = isSelected
        ? (Theme.of(context).colorScheme.onPrimary)
        : (context.ambianceColors.sub);
    final borderColor = isSelected
        ? accentColor
        : (isDark ? accentColor.withAlpha(50) : accentColor.withAlpha(50));

    final IconData iconData;
    if (label == 'Watchlist') {
      iconData = isSelected ? Icons.bookmark : Icons.bookmark_outline;
    } else if (label == 'Saved' || label == 'Save') {
      iconData = isSelected ? Icons.star : Icons.star_border;
    } else if (label == 'Watching') {
      iconData = isSelected ? Icons.play_circle : Icons.play_circle_outline;
    } else if (label == 'Watched') {
      iconData = isSelected ? Icons.check_circle : Icons.check_circle_outline;
    } else if (label == 'On-Hold') {
      iconData = isSelected ? Icons.pause_circle : Icons.pause_circle_outline;
    } else if (label == 'Dropped') {
      iconData = isSelected ? Icons.remove_circle : Icons.remove_circle_outline;
    } else {
      iconData = isSelected ? Icons.check_circle : Icons.check_circle_outline;
    }

    final decoration = isSelected
        ? (isDark
            ? BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.15),
                    blurRadius: 0,
                    spreadRadius: 0,
                    offset: Offset(0, 1),
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              )
            : context.ambianceColors.primaryButtonDecoration
                .copyWith(borderRadius: BorderRadius.circular(12)))
        : BoxDecoration(
            color: context.ambianceColors.card2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          );

    final toggleWidget = StatusPulseRing(
      isSelected: isSelected,
      accentColor: accentColor,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          height: 44,
          decoration: decoration,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: AppPhysics.houseSpringDuration,
                  switchInCurve: AppPhysics.houseSpringCurve,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    iconData,
                    key: ValueKey('$label-$isSelected'),
                    size: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 5),
                AnimatedDefaultTextStyle(
                  duration: AppPhysics.houseSpringDuration,
                  curve: AppPhysics.houseSpringCurve,
                  style: AppThemes.safeGeist(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isDisabled) {
      return Tooltip(
        message: 'This title has not been released yet.',
        // SP-2: themed to match the app's dark chrome instead of
        // Flutter's plain light default popup.
        decoration: BoxDecoration(
          color: context.ambianceColors.card2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.ambianceColors.lineRgba),
        ),
        textStyle: AppThemes.safeGeist(
            fontSize: 12, color: context.ambianceColors.ink),
        child: Opacity(
          opacity: 0.5,
          child: toggleWidget,
        ),
      );
    }

    return toggleWidget;
  }

  Widget _buildCastStrip(
      BuildContext context, WidgetRef ref, MediaItem item, bool isDark) {
    if (item.cast.isEmpty) return const SizedBox.shrink();

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cast',
          style: AppThemes.safeGeist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: item.cast.length,
            itemBuilder: (context, index) {
              final castName = item.cast[index];
              final castMember = (index < item.castMembers.length)
                  ? item.castMembers[index]
                  : null;
              final profileUrl = castMember?.profileUrl;

              Widget avatarContent;
              if (profileUrl != null && profileUrl.isNotEmpty) {
                avatarContent = ClipOval(
                  child: MediaImage(
                    imageUrl: profileUrl,
                    fit: BoxFit.cover,
                    fallback: Icon(Icons.person, color: subColor),
                  ),
                );
              } else {
                avatarContent = Icon(Icons.person, color: subColor);
              }

              return PressableScale(
                onTap: () {
                  final pId =
                      castMember != null ? int.tryParse(castMember.id) : null;
                  final pName = castMember?.name ?? castName;
                  // SEARCH-CAST-1: see navigateToPerson's comment above --
                  // clear any stale filters from an earlier Search session
                  // before applying this person filter.
                  ref.read(discoverFilterProvider.notifier).resetFilters();
                  ref.read(discoverFilterProvider.notifier).setPerson(
                        personId: pId,
                        personName: pName,
                      );
                  // NAV-2: see navigateToPerson's comment above -- do not
                  // mutate the root tab for a pushed sub-route.
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: phColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: lineRgba),
                        ),
                        child: avatarContent,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          castName,
                          style: AppThemes.safeGeist(
                            fontSize: 11,
                            color: subColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrailersSection(
      BuildContext context, MediaItem item, bool isDark) {
    final trailers = item.trailers;
    if (trailers == null || trailers.isEmpty) return const SizedBox.shrink();

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;
    final accColor = context.ambianceColors.acc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Trailers',
          style: AppThemes.safeGeist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 155,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trailers.length,
            itemBuilder: (context, index) {
              final video = trailers[index];
              final thumbnailUrl =
                  'https://img.youtube.com/vi/${video.key}/hqdefault.jpg';

              return Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: PressableScale(
                  onTap: () => _playTrailer(
                    context,
                    item,
                    videoId: video.key,
                    videoTitle: video.name,
                  ),
                  child: SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 220,
                          height: 105,
                          decoration: BoxDecoration(
                            color: phColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: lineRgba),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MediaImage(
                                imageUrl: thumbnailUrl,
                                fit: BoxFit.cover,
                                fallback: Container(
                                  color: phColor,
                                  child: Icon(Icons.movie_outlined,
                                      color: subColor),
                                ),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: context.ambianceColors.scrim,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        video.type,
                                        style: AppThemes.safeGeist(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (video.official) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: accColor.withAlpha(230),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Official',
                                          style: AppThemes.safeGeist(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          video.name,
                          style: AppThemes.safeGeist(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: inkColor,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWatchProvidersSection(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    // PERF-1: see _buildActionButtons' comment -- same reasoning, this
    // watches the broad mediaProvider (for watchProvidersCountry) and
    // watchProviderRegionsProvider, so it gets its own Consumer scope
    // instead of forcing a whole-DetailScreen rebuild.
    return Consumer(
      builder: (context, ref, child) {
        return _buildWatchProvidersContent(context, ref, item, isDark);
      },
    );
  }

  Widget _buildWatchProvidersContent(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    final mediaState = ref.watch(mediaProvider);
    final selectedCountry = mediaState.watchProvidersCountry;
    final notifier = ref.read(mediaProvider.notifier);
    final regionsAsync = ref.watch(watchProviderRegionsProvider);

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;
    final accColor = context.ambianceColors.acc;

    final defaultRegions = const [
      {'code': 'US', 'name': 'United States'},
      {'code': 'GB', 'name': 'United Kingdom'},
      {'code': 'CA', 'name': 'Canada'},
      {'code': 'AU', 'name': 'Australia'},
      {'code': 'DE', 'name': 'Germany'},
      {'code': 'FR', 'name': 'France'},
      {'code': 'JP', 'name': 'Japan'},
    ];

    final availableRegions = regionsAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : defaultRegions,
      orElse: () => defaultRegions,
    );

    final hasSelected =
        availableRegions.any((r) => r['code'] == selectedCountry);
    final currentCountry = hasSelected
        ? selectedCountry
        : (availableRegions.isNotEmpty
            ? availableRegions.first['code']!
            : 'US');

    final countryProviders = item.getWatchProvidersForCountry(currentCountry);

    final grouped = <String, List<WatchProviderInfo>>{};
    for (final p in countryProviders) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Where to Watch',
              style: AppThemes.safeGeist(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: inkColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: phColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: lineRgba),
              ),
              child: LoungeDropdown<String>(
                value: currentCountry,
                dense: true,
                onChanged: (newCountry) {
                  if (newCountry != null) {
                    notifier.setWatchProvidersCountry(newCountry);
                  }
                },
                items:
                    availableRegions.map<LoungeDropdownItem<String>>((region) {
                  final code = region['code'] ?? 'US';
                  return LoungeDropdownItem<String>(value: code, label: code);
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (countryProviders.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final cat in ['Stream', 'Rent', 'Buy'])
                if (grouped.containsKey(cat) && grouped[cat]!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 6),
                    child: Text(
                      cat,
                      style: AppThemes.safeGeist(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: grouped[cat]!.map((provider) {
                      return PressableScale(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: phColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: lineRgba),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat == 'Stream'
                                    ? Icons.tv
                                    : (cat == 'Rent'
                                        ? Icons.shopping_bag_outlined
                                        : Icons.shopping_cart_outlined),
                                size: 14,
                                color: accColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                provider.providerName,
                                style: AppThemes.safeGeist(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: inkColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ).animate(key: ValueKey(currentCountry)).fade(duration: 250.ms)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'No streaming providers available in $currentCountry.',
              style: AppThemes.safeGeist(
                fontSize: 12.5,
                color: subColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ).animate(key: ValueKey(currentCountry)).fade(duration: 250.ms),
      ],
    );
  }

  Widget _buildSeasonsSection(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    return SeasonsSectionWidget(item: item, isDark: isDark);
  }

  /// PERS-REWATCH-1: "Add Rewatch" action pill (shown once the item has at
  /// least one logged [WatchRecord]) + the collapsible Watch History
  /// timeline. Scoped to its own Consumer so history/rating edits don't
  /// rebuild the whole DetailScreen (PERF-1 pattern).
  Widget _buildWatchHistorySection(
    BuildContext context,
    MediaItem item,
    bool isDark,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final hasHistory = ref.watch(
          mediaProvider.select(
            (s) => (s.watchHistory[item.id]?.isNotEmpty ?? false),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WatchHistoryTimeline(item: item),
            if (hasHistory) ...[
              const SizedBox(height: 12),
              PressableScale(
                onTap: () => showLoungeRewatchSheet(context, ref, item: item),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.ambianceColors.card2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.ambianceColors.lineRgba),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded,
                          size: 16, color: context.ambianceColors.ink),
                      const SizedBox(width: 8),
                      Text(
                        'Add Rewatch',
                        style: AppThemes.safeGeist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.ambianceColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class ExpandableOverviewText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool isDark;
  final int maxLinesCollapsed;

  const ExpandableOverviewText({
    super.key,
    required this.text,
    required this.style,
    required this.isDark,
    this.maxLinesCollapsed = 3,
  });

  @override
  State<ExpandableOverviewText> createState() => _ExpandableOverviewTextState();
}

class _ExpandableOverviewTextState extends State<ExpandableOverviewText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = context.ambianceColors.acc;

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.text, style: widget.style);
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxLinesCollapsed,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: AppPhysics.houseSpringCurve,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: widget.style,
                maxLines: _isExpanded ? null : widget.maxLinesCollapsed,
                overflow:
                    _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
              ),
            ),
            if (isOverflowing) ...[
              const SizedBox(height: 6),
              PressableScale(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'Show less' : 'Show more',
                        style: AppThemes.safeGeist(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: AppPhysics.houseSpringCurve,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class SeasonsSectionWidget extends ConsumerStatefulWidget {
  final MediaItem item;
  final bool isDark;

  const SeasonsSectionWidget({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  ConsumerState<SeasonsSectionWidget> createState() =>
      _SeasonsSectionWidgetState();
}

class _SeasonsSectionWidgetState extends ConsumerState<SeasonsSectionWidget> {
  int _selectedSeason = 1;
  bool _isExpanded = false;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.type != MediaType.tv) return const SizedBox.shrink();

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;
    final accColor = context.ambianceColors.acc;
    final pillColor = context.ambianceColors.pill;

    final seasonsCount = widget.item.seasonsCount ?? 1;

    final seasonAsync = ref.watch(
      tvSeasonDetailsProvider(
          (tvId: widget.item.id, seasonNumber: _selectedSeason)),
    );
    final allSeasonsAsync = ref.watch(tvShowSeasonsProvider(widget.item));

    if (allSeasonsAsync.hasValue && allSeasonsAsync.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(mediaProvider.notifier).reevaluateShowCompletion(
                showId: widget.item.id,
                seasons: allSeasonsAsync.value!,
              );
        }
      });
    }

    ref.watch(mediaProvider);

    // TV-SEASON-1: only offered once real per-season episode data is in
    // hand -- marking a season complete needs to know which episodes are
    // actually released, the same ground truth toggleEpisodeWatched
    // requires.
    final currentSeasonData = allSeasonsAsync.value?.firstWhere(
      (s) => s.seasonNumber == _selectedSeason,
      orElse: () =>
          TvSeason(id: 0, seasonNumber: _selectedSeason, name: '', episodes: const []),
    );
    final seasonAlreadyComplete = ref.read(mediaProvider).seasonEndDates[
            widget.item.id]?[_selectedSeason] !=
        null;
    final canMarkSeasonComplete = allSeasonsAsync.hasValue &&
        currentSeasonData != null &&
        currentSeasonData.episodes.isNotEmpty &&
        !seasonAlreadyComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Seasons & Episodes',
                style: AppThemes.safeGeist(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
            ),
            if (canMarkSeasonComplete)
              PressableScale(
                onTap: () {
                  ref.read(mediaProvider.notifier).markSeasonWatched(
                        showId: widget.item.id,
                        seasonNumber: _selectedSeason,
                        showItem: widget.item,
                        seasons: allSeasonsAsync.value!,
                      );
                  LoungeToast.show(
                      context, 'Season $_selectedSeason marked complete.');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all, size: 14, color: accColor),
                      const SizedBox(width: 6),
                      Text(
                        'Mark season complete',
                        style: AppThemes.safeGeist(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (seasonsCount > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(seasonsCount, (index) {
                final seasonNum = index + 1;
                final isSelected = seasonNum == _selectedSeason;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PressableScale(
                    onTap: () {
                      setState(() {
                        _selectedSeason = seasonNum;
                        _isExpanded = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? accColor : phColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? accColor : lineRgba,
                        ),
                      ),
                      child: Text(
                        'Season $seasonNum',
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? (Theme.of(context).colorScheme.onPrimary)
                              : subColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 12),
        // PERS-RATE-1: per-season personal rating pill (rebuilds standalone
        // via its own Consumer, not the whole season block).
        Consumer(
          builder: (context, ref, _) => PersonalRatingPill(
            item: widget.item,
            seasonNumber: _selectedSeason,
          ),
        ),
        const SizedBox(height: 12),
        seasonAsync.when(
          data: (seasonData) {
            final List<TvEpisode> allEpisodes;
            if (seasonData != null && seasonData.episodes.isNotEmpty) {
              allEpisodes = seasonData.episodes;
            } else if (widget.item.episodesList != null &&
                widget.item.episodesList!.isNotEmpty) {
              allEpisodes = List.generate(
                widget.item.episodesList!.length,
                (i) => TvEpisode(
                  id: (_selectedSeason * 100) + i + 1,
                  episodeNumber: i + 1,
                  seasonNumber: _selectedSeason,
                  name: widget.item.episodesList![i],
                  runtime: 45,
                ),
              );
            } else {
              final count = widget.item.episodesCount ?? 8;
              allEpisodes = List.generate(
                count,
                (i) => TvEpisode(
                  id: (_selectedSeason * 100) + i + 1,
                  episodeNumber: i + 1,
                  seasonNumber: _selectedSeason,
                  name: 'Episode ${i + 1}',
                  runtime: 45,
                ),
              );
            }

            final bool hasMoreThan15 = allEpisodes.length > 15;
            final visibleEpisodes = (hasMoreThan15 && !_isExpanded)
                ? allEpisodes.take(15).toList()
                : allEpisodes;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleEpisodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final episode = visibleEpisodes[index];
                    final isWatched =
                        ref.read(mediaProvider.notifier).isEpisodeWatched(
                              widget.item.id,
                              episode.seasonNumber,
                              episode.episodeNumber,
                            );

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: phColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isWatched ? accColor.withAlpha(128) : lineRgba,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.ambianceColors.card,
                              borderRadius: BorderRadius.circular(6),
                              image: episode.stillUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(episode.stillUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: episode.stillUrl == null
                                ? Icon(Icons.play_circle_outline,
                                    size: 20, color: subColor)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'E${episode.episodeNumber} · ${episode.name}',
                                  style: AppThemes.safeGeist(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: inkColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  episode.airDate != null
                                      ? 'Air date: ${_formatDate(episode.airDate!)}'
                                      : 'Air date: TBA',
                                  style: AppThemes.safeGeist(
                                    fontSize: 11,
                                    color: subColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (episode.overview != null &&
                                    episode.overview!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    episode.overview!,
                                    style: AppThemes.safeGeist(
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Interactive watched toggle checkmark icon button
                          () {
                            final isEpisodeUnaired = episode.airDate != null
                                ? episode.airDate!.isAfter(DateTime.now())
                                : (widget.item.releaseOrAirDate != null
                                    ? widget.item.releaseOrAirDate!
                                        .isAfter(DateTime.now())
                                    : false);
                            return Tooltip(
                              message: isEpisodeUnaired
                                  ? 'This episode has not aired yet.'
                                  : (isWatched
                                      ? 'Mark as unwatched'
                                      : 'Mark as watched'),
                              // SP-2: themed to match the app's dark chrome
                              // instead of Flutter's plain light default
                              // popup.
                              decoration: BoxDecoration(
                                color: context.ambianceColors.card2,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: context.ambianceColors.lineRgba),
                              ),
                              textStyle: AppThemes.safeGeist(
                                  fontSize: 12,
                                  color: context.ambianceColors.ink),
                              child: Opacity(
                                opacity: isEpisodeUnaired ? 0.4 : 1.0,
                                child: StatusPulseRing(
                                  isSelected: isWatched,
                                  accentColor: accColor,
                                  borderRadius: 999,
                                  child: PressableScale(
                                    onTap: isEpisodeUnaired
                                        ? () {
                                            LoungeToast.show(context,
                                                'This episode has not aired yet.');
                                          }
                                        : () {
                                            final totalEpisodes = widget
                                                    .item.episodesCount ??
                                                ((widget.item.seasonsCount ??
                                                        1) *
                                                    allEpisodes.length);

                                            final showId = widget.item.id;
                                            final seasonNum =
                                                episode.seasonNumber;
                                            final wasSeasonComplete = ref
                                                        .read(mediaProvider)
                                                        .seasonEndDates[showId]
                                                    ?[seasonNum] !=
                                                null;

                                            ref
                                                .read(mediaProvider.notifier)
                                                .toggleEpisodeWatched(
                                                  showId: showId,
                                                  seasonNumber: seasonNum,
                                                  episodeNumber:
                                                      episode.episodeNumber,
                                                  showItem: widget.item,
                                                  totalEpisodeCount:
                                                      totalEpisodes,
                                                  seasons:
                                                      allSeasonsAsync.value,
                                                );

                                            // PERS-RATE-1: auto-prompt the
                                            // moment this specific season
                                            // (not necessarily the whole
                                            // show) newly completes.
                                            final isNowSeasonComplete = ref
                                                        .read(mediaProvider)
                                                        .seasonEndDates[showId]
                                                    ?[seasonNum] !=
                                                null;
                                            if (!wasSeasonComplete &&
                                                isNowSeasonComplete) {
                                              final hasRating =
                                                  findPrimaryWatchRecord(
                                                        ref
                                                            .read(mediaProvider)
                                                            .watchHistory,
                                                        showId,
                                                        seasonNum,
                                                      ) !=
                                                      null;
                                              if (!hasRating) {
                                                showLoungeRatingSheet(
                                                  context,
                                                  ref,
                                                  item: widget.item,
                                                  seasonNumber: seasonNum,
                                                  isAutoPrompt: true,
                                                );
                                              }
                                            }
                                          },
                                    child: AnimatedContainer(
                                      duration: AppPhysics.houseSpringDuration,
                                      curve: AppPhysics.houseSpringCurve,
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isWatched
                                            ? accColor
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isWatched
                                              ? accColor
                                              : subColor.withAlpha(128),
                                        ),
                                      ),
                                      child: AnimatedSwitcher(
                                        duration:
                                            AppPhysics.houseSpringDuration,
                                        switchInCurve:
                                            AppPhysics.houseSpringCurve,
                                        switchOutCurve: Curves.easeOut,
                                        transitionBuilder: (child, animation) =>
                                            ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                        child: Icon(
                                          isWatched
                                              ? Icons.check
                                              : Icons.check_outlined,
                                          key: ValueKey(
                                              'episode-check-$isWatched'),
                                          size: 16,
                                          color: isWatched
                                              ? (Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary)
                                              : subColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }(),
                        ],
                      ),
                    );
                  },
                ),
                if (hasMoreThan15 && !_isExpanded) ...[
                  const SizedBox(height: 12),
                  PressableScale(
                    onTap: () {
                      setState(() {
                        _isExpanded = true;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: lineRgba),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Show all ${allEpisodes.length} episodes',
                        style: AppThemes.safeGeist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InlinePartialErrorWidget(
              message: 'Failed to load season details',
              onRetry: () => ref.invalidate(
                tvSeasonDetailsProvider(
                    (tvId: widget.item.id, seasonNumber: _selectedSeason)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
