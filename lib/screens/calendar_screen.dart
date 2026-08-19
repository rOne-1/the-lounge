import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/hall_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/repository_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';
import '../constants.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/quick_status_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  List<MediaItem> _allMovies = [];
  List<MediaItem> _allTvShows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  /// CAL-1: for TV, `releaseOrAirDate` is the show's original premiere
  /// (`first_air_date`) -- for an ongoing show that's routinely years in
  /// the past, not when its next episode actually airs. Prefer the real
  /// next-episode date when TMDB provided one; movies only ever have the
  /// single `releaseOrAirDate`.
  DateTime? _effectiveDate(MediaItem item) {
    if (item.type == MediaType.tv && item.nextEpisodeAirDate != null) {
      return item.nextEpisodeAirDate;
    }
    return item.releaseOrAirDate;
  }

  Future<void> _loadAgenda() async {
    final repo = ref.read(movieRepositoryProvider);

    // CAL-1: Calendar is specifically an *upcoming* releases agenda (see
    // this screen's own empty-state copy: "No upcoming movie premieres" /
    // "No upcoming TV episodes"), not a general trending feed --
    // getTrendingMovies/getTrendingTvShows return whatever's popular RIGHT
    // NOW regardless of release date, which routinely includes titles
    // released years ago. getUpcomingMovies/getOnTheAirTvShows are the
    // correct semantic match (both already have their own server-side +
    // client-side future-date filtering, see tmdb_movie_repository.dart).
    //
    // LANG-2 (2nd pass): both route through /discover with server-side
    // with_original_language when a Hall lock is active (see
    // MovieRepository's originalLanguage param) -- a plain single-page
    // fetch-then-filter left the agenda near-empty for a locked regional
    // language with few/no matches in the raw global chart.
    final lockedLanguageCode = ref.read(activeHallSpaceProvider).lockedLanguageCode;
    final movies = await repo.getUpcomingMovies(originalLanguage: lockedLanguageCode);
    final tvShows = await repo.getOnTheAirTvShows(originalLanguage: lockedLanguageCode);

    // Belt-and-suspenders (matches getUpcomingMovies' own "server-side
    // filter already excludes released titles, but keep the client-side
    // check too" convention): re-derive "upcoming" here using each item's
    // real effective date (next-episode date for TV, not first-air-date),
    // rather than trusting every source endpoint's classification as-is.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isUpcoming(MediaItem item) {
      final date = _effectiveDate(item);
      if (date == null) return false;
      final dateOnly = DateTime(date.year, date.month, date.day);
      return !dateOnly.isBefore(today);
    }

    if (mounted) {
      setState(() {
        _allMovies = movies.where(isUpcoming).toList();
        _allTvShows = tvShows.where(isUpcoming).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.ambianceColors.isDark;
    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;

    // LANG-2: _loadAgenda() is a one-shot imperative fetch, not a
    // FutureProvider Riverpod can auto-rerun on dependency change, so a
    // Hall switch while already sitting on Calendar would otherwise leave
    // the agenda showing the previous Hall's language lock until the tab is
    // left and re-entered. Re-fetch explicitly when the lock changes.
    ref.listen(activeHallSpaceProvider.select((h) => h.lockedLanguageCode),
        (previous, next) {
      if (previous != next) _loadAgenda();
    });

    final navState = ref.watch(navigationProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;
    final targetItems = isMovies ? _allMovies : _allTvShows;

    final Map<DateTime, List<MediaItem>> grouped = {};
    for (final item in targetItems) {
      // Safe to force-unwrap: _loadAgenda already filtered targetItems down
      // to items with a real, non-null, upcoming effective date.
      final date = _effectiveDate(item)!;
      final dateKey = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;

    if (grouped.isEmpty) {
      return AtmosphericEmptyState(
        icon: Icons.calendar_month_outlined,
        title: isMovies ? 'No upcoming movie premieres' : 'No upcoming TV episodes',
        message: 'Releases for anything you\'ve watchlisted will show up here.',
        ctaLabel: 'Discover Titles',
        onCta: () => ref.read(navigationProvider.notifier).setTab(AppTab.discover),
      );
    }

    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          isLarge ? 24.0 : 18.0,
          isLarge ? 4.0 : 12.0,
          isLarge ? 24.0 : 18.0,
          18.0 + MediaQuery.of(context).padding.bottom),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateIndex = index;
        final date = sortedDates[dateIndex];
        final items = grouped[date]!;
        // date is already midnight-normalized (see the grouping above);
        // comparing against today's own midnight-normalized value avoids
        // the previous time-of-day-dependent edge case where `.inDays`
        // truncation could misclassify "tomorrow" as "today" within the
        // last hour before midnight.
        final now = DateTime.now();
        final isToday = date == DateTime(now.year, now.month, now.day);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                isToday
                    ? 'Today'
                    : date.year == now.year
                        ? '${_monthName(date.month)} ${date.day}'
                        : '${_monthName(date.month)} ${date.day}, ${date.year}',
                style: AppThemes.safeGeist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: subColor,
                    textStyle: const TextStyle(
                        textBaseline: TextBaseline.alphabetic)),
              ),
            ),
            ...items.asMap().entries.map((entry) => _buildAgendaCard(
                  entry.value,
                  isDark,
                  inkColor,
                  subColor,
                  index: dateIndex + entry.key,
                )),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildAgendaCard(MediaItem item, bool isDark, Color inkColor, Color subColor, {required int index}) {
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;
    final accColor = context.ambianceColors.acc; // For Movies
    final dotColor = item.type == MediaType.movie ? accColor : AppStatusColors.watched; // For TV

    return OpenContainer(
      transitionDuration: AppPhysics.houseSpringDuration,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: context.ambianceColors.base,
      middleColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      closedBuilder: (context, openContainer) {
        return PressableScale(
          onTap: openContainer,
          onLongPress: () => showQuickStatusSheet(context, ref, item),
          child: Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: phColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lineRgba),
                boxShadow: [
                  BoxShadow(color: context.ambianceColors.surfaceHighlight, blurRadius: 0, spreadRadius: 0, offset: const Offset(0, 1), blurStyle: BlurStyle.inner)
                ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppPhysics.houseSpringDuration,
                    curve: AppPhysics.houseSpringCurve,
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: isDark ? const Color.fromRGBO(0, 0, 0, 0.15) : const Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 0, spreadRadius: 0, offset: const Offset(0, 1), blurStyle: BlurStyle.inner)
                      ]
                    ),
                  ).animate(key: ValueKey(dotColor)).fade(duration: 200.ms),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: AppThemes.safeGeist(fontSize: 14, fontWeight: FontWeight.w600, color: inkColor)),
                        const SizedBox(height: 3),
                        Text(item.type == MediaType.movie ? 'Movie Premiere' : 'New Episode', style: AppThemes.safeGeist(fontSize: 12, color: subColor)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: subColor, size: 20),
                ],
              ),
            ),
          );
        },
        openBuilder: (context, _) => DetailScreen(id: item.prefixedId),
    ).animate(key: ValueKey(item.prefixedId))
        .fade(duration: 250.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          delay: (index.clamp(0, 5) * 40).ms,
        );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
