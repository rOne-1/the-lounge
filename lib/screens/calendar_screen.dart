import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/repository_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';
import '../constants.dart';
import '../widgets/pressable_scale.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  Map<DateTime, List<MediaItem>> _groupedItems = {};
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

    final allItems = [...movies, ...tvShows]
        .where((m) => m.releaseOrAirDate != null)
        .toList();

    // Group by Date (ignoring time)
    final Map<DateTime, List<MediaItem>> grouped = {};
    for (final item in allItems) {
      final date = item.releaseOrAirDate!;
      final dateKey = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    if (mounted) {
      setState(() {
        _groupedItems = grouped;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupedItems.isEmpty) {
      return Center(
        child: Text('No upcoming releases.', style: AppThemes.safeGeist(color: subColor)),
      );
    }

    final sortedDates = _groupedItems.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 18.0 + MediaQuery.of(context).padding.bottom),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = _groupedItems[date]!;
        final isToday = date.difference(DateTime.now()).inDays == 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                isToday ? 'Today' : '${_monthName(date.month)} ${date.day}',
                style: AppThemes.safeGeist(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: subColor, textStyle: const TextStyle(textBaseline: TextBaseline.alphabetic)),
              ),
            ),
            ...items.asMap().entries.map((entry) => _buildAgendaCard(
                  entry.value,
                  isDark,
                  inkColor,
                  subColor,
                  index: index + entry.key,
                )),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildAgendaCard(MediaItem item, bool isDark, Color inkColor, Color subColor, {required int index}) {
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc; // For Movies
    final dotColor = item.type == MediaType.movie ? accColor : (isDark ? AppColors.srStatusWatched : AppColors.rrStatusWatched); // For TV

    return PressableScale(
      child: OpenContainer(
        transitionDuration: AppPhysics.houseSpringDuration,
        closedElevation: 0,
        openElevation: 0,
        closedColor: Colors.transparent,
        openColor: isDark ? AppColors.srBase : AppColors.rrBase,
        middleColor: Colors.transparent,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        closedBuilder: (context, openContainer) {
          return GestureDetector(
            onTap: openContainer,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: phColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lineRgba),
                boxShadow: [
                  BoxShadow(color: isDark ? const Color.fromRGBO(255, 255, 255, 0.05) : const Color.fromRGBO(255, 255, 255, 0.4), blurRadius: 0, spreadRadius: 0, offset: const Offset(0, 1), blurStyle: BlurStyle.inner)
                ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
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
        openBuilder: (context, _) => DetailScreen(id: item.id),
      ),
    ).animate().fade(duration: 250.ms).slideY(
        begin: 0.1,
        end: 0,
        delay: (index.clamp(0, 5) * 40).ms);
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
