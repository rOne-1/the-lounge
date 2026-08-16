import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/navigation_provider.dart';
import '../providers/repository_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';
import '../constants.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/segmented_toggle.dart';
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

  Future<void> _loadAgenda() async {
    final repo = ref.read(movieRepositoryProvider);
    final movies = await repo.getTrendingMovies();
    final tvShows = await repo.getTrendingTvShows();

    if (mounted) {
      setState(() {
        _allMovies = movies.where((m) => m.releaseOrAirDate != null).toList();
        _allTvShows = tvShows.where((m) => m.releaseOrAirDate != null).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.ambianceColors.isDark;
    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;

    final navState = ref.watch(navigationProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;
    final targetItems = isMovies ? _allMovies : _allTvShows;

    final Map<DateTime, List<MediaItem>> grouped = {};
    for (final item in targetItems) {
      final date = item.releaseOrAirDate!;
      final dateKey = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;

    if (grouped.isEmpty) {
      return Column(
        children: [
          if (!isLarge) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedMediaTypeToggle(
                  activeType: navState.activeMediaType,
                  onChanged: (type) =>
                      ref.read(navigationProvider.notifier).setMediaType(type),
                  isDark: isDark,
                ),
              ),
            ),
          ],
          Expanded(
            child: Center(
              child: Text(
                isMovies ? 'No upcoming movie premieres.' : 'No upcoming TV episodes.',
                style: AppThemes.safeGeist(color: subColor),
              ),
            ),
          ),
        ],
      );
    }

    final sortedDates = grouped.keys.toList()..sort();

    final itemCount = sortedDates.length + (!isLarge ? 1 : 0);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          isLarge ? 24.0 : 18.0,
          isLarge ? 4.0 : 12.0,
          isLarge ? 24.0 : 18.0,
          18.0 + MediaQuery.of(context).padding.bottom),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (!isLarge && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedMediaTypeToggle(
                activeType: navState.activeMediaType,
                onChanged: (type) =>
                    ref.read(navigationProvider.notifier).setMediaType(type),
                isDark: isDark,
              ),
            ),
          );
        }

        final dateIndex = !isLarge ? index - 1 : index;
        final date = sortedDates[dateIndex];
        final items = grouped[date]!;
        final isToday = date.difference(DateTime.now()).inDays == 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                isToday ? 'Today' : '${_monthName(date.month)} ${date.day}',
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
    final dotColor = item.type == MediaType.movie ? accColor : (context.ambianceColors.statusWatched); // For TV

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
