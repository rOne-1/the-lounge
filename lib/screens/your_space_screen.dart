import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';
import '../constants.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/quick_status_sheet.dart';

enum InProgressSubFilter { watching, onHold, dropped }

class YourSpaceScreen extends ConsumerStatefulWidget {
  const YourSpaceScreen({super.key});

  @override
  ConsumerState<YourSpaceScreen> createState() => _YourSpaceScreenState();
}

class _YourSpaceScreenState extends ConsumerState<YourSpaceScreen> {
  InProgressSubFilter _inProgressFilter = InProgressSubFilter.watching;

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);
    final navState = ref.watch(navigationProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;
    final activeType = isMovies ? MediaType.movie : MediaType.tv;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;

    List<MediaItem> filterList(Map<String, MediaItem> itemsMap) {
      return itemsMap.values
          .where((item) => item.type == activeType)
          .toList();
    }

    List<MediaItem> getInProgressItems() {
      switch (_inProgressFilter) {
        case InProgressSubFilter.watching:
          return filterList(mediaState.watchingList);
        case InProgressSubFilter.onHold:
          return filterList(mediaState.onHoldList);
        case InProgressSubFilter.dropped:
          return filterList(mediaState.droppedList);
      }
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  labelColor: accColor,
                  unselectedLabelColor: subColor,
                  indicatorColor: accColor,
                  labelStyle: AppThemes.safeGeist(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: AppThemes.safeGeist(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Watchlist'),
                    Tab(text: 'Saved'),
                    Tab(text: 'In Progress'),
                    Tab(text: 'Watched'),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('app_info_button'),
                icon: Icon(Icons.info_outline, color: subColor, size: 20),
                tooltip: 'App Info & Privacy',
                onPressed: () => _showAppInfoDialog(context, isDark),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTabContent(
                  context: context,
                  title: 'Watchlist',
                  subtitle: 'Committed watchlist of titles you plan to watch soon.',
                  items: filterList(mediaState.watchlist),
                  isDark: isDark,
                  subColor: subColor,
                  inkColor: inkColor,
                ),
                _buildTabContent(
                  context: context,
                  title: 'Saved',
                  subtitle: 'Soft, non-committal bookmarks for titles you might want to check out later.',
                  items: filterList(mediaState.maybeList),
                  isDark: isDark,
                  subColor: subColor,
                  inkColor: inkColor,
                ),
                _buildInProgressTabContent(
                  context: context,
                  title: 'In Progress',
                  subtitle: 'Track active, paused, or stopped viewing progress.',
                  items: getInProgressItems(),
                  isDark: isDark,
                  subColor: subColor,
                  inkColor: inkColor,
                  accColor: accColor,
                ),
                _buildTabContent(
                  context: context,
                  title: 'Watched',
                  subtitle: null,
                  items: filterList(mediaState.watchedList),
                  isDark: isDark,
                  subColor: subColor,
                  inkColor: inkColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context, bool isDark) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final dialogBg = isDark ? AppColors.srBase : AppColors.rrBase;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'App Info & Privacy',
          style: AppThemes.safeGeist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TMDB Attribution',
                style: AppThemes.safeGeist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tester Privacy Note',
                style: AppThemes.safeGeist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The Lounge collects local storage state to persist your watchlist, bookmarks, and preferences, as well as anonymous Sentry error and device logs to identify bugs and ensure stability.',
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppThemes.safeGeist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.srAcc : AppColors.rrAcc,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent({
    required BuildContext context,
    required String title,
    required String? subtitle,
    required List<MediaItem> items,
    required bool isDark,
    required Color subColor,
    required Color inkColor,
  }) {
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(paddingHorizontal, 16.0, paddingHorizontal, 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppThemes.safeGeist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _buildGrid(context, items, isDark, subColor),
        ),
      ],
    );
  }

  Widget _buildInProgressTabContent({
    required BuildContext context,
    required String title,
    required String? subtitle,
    required List<MediaItem> items,
    required bool isDark,
    required Color subColor,
    required Color inkColor,
    required Color accColor,
  }) {
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(paddingHorizontal, 16.0, paddingHorizontal, 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppThemes.safeGeist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: subColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _buildSubSegmentedPills(isDark: isDark, accColor: accColor, subColor: subColor),
            ],
          ),
        ),
        Expanded(
          child: _buildGrid(context, items, isDark, subColor),
        ),
      ],
    );
  }

  Widget _buildSubSegmentedPills({
    required bool isDark,
    required Color accColor,
    required Color subColor,
  }) {
    final pillBg = isDark ? AppColors.srPill : AppColors.rrPill;
    final activeTextColor = isDark ? const Color(0xFF1A140C) : Colors.white;

    Widget buildPill(String label, InProgressSubFilter filter) {
      final isSelected = _inProgressFilter == filter;
      return PressableScale(
        onTap: () {
          setState(() {
            _inProgressFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? accColor : pillBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppThemes.safeGeist(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? activeTextColor : subColor,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildPill('Watching', InProgressSubFilter.watching),
        const SizedBox(width: 8),
        buildPill('On-Hold', InProgressSubFilter.onHold),
        const SizedBox(width: 8),
        buildPill('Dropped', InProgressSubFilter.dropped),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<MediaItem> items, bool isDark, Color subColor) {
    if (items.isEmpty) {
      return Center(child: Text('Nothing here yet.', style: AppThemes.safeGeist(fontSize: 14, color: subColor)));
    }

    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final isLarge = MediaQuery.of(context).size.width >= 600;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
          isLarge ? 24.0 : 18.0, isLarge ? 12.0 : 18.0, isLarge ? 24.0 : 18.0, 18.0 + MediaQuery.of(context).padding.bottom),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return PressableScale(
          child: OpenContainer(
            transitionDuration: AppPhysics.houseSpringDuration,
            closedElevation: 0,
            openElevation: 0,
            closedColor: Colors.transparent,
            openColor: isDark ? AppColors.srBase : AppColors.rrBase,
            middleColor: Colors.transparent,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            closedBuilder: (context, openContainer) {
              return GestureDetector(
                onTap: openContainer,
                onLongPress: () => showQuickStatusSheet(context, ref, item),
                child: Container(
                  decoration: BoxDecoration(
                    color: phColor,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: lineRgba),
                    boxShadow: [
                      BoxShadow(color: isDark ? const Color.fromRGBO(255, 255, 255, 0.05) : const Color.fromRGBO(255, 255, 255, 0.4), blurRadius: 0, spreadRadius: 0, offset: const Offset(0, 1), blurStyle: BlurStyle.inner)
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaImage(
                    item: item,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
            openBuilder: (context, _) => DetailScreen(id: item.prefixedId),
          ),
        ).animate().fade(duration: 250.ms).slideY(
            begin: 0.1,
            end: 0,
            delay: (index.clamp(0, 5) * 40).ms);
      },
    );
  }
}
