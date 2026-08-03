import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/navigation_provider.dart';
import '../providers/repository_provider.dart';
import 'detail_screen.dart';
import '../constants.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/ambient_glow.dart';

class HomeScreen extends ConsumerWidget {
  final bool? enableAnimation;

  const HomeScreen({super.key, this.enableAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;

    final trendingAsync = isMovies
        ? ref.watch(trendingMoviesProvider)
        : ref.watch(trendingTvShowsProvider);
    final popularAsync = ref.watch(popularMoviesProvider);

    String greeting() {
      final now = DateTime.now();
      const dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = dayNames[now.weekday - 1];
      final timeOfDay = now.hour < 12
          ? 'morning'
          : (now.hour < 17 ? 'afternoon' : 'evening');
      return '$dayName $timeOfDay';
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final pillColor = isDark ? AppColors.srPill : AppColors.rrPill;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.0, 4.0, 18.0, 4.0 + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting().toUpperCase(),
                      style: AppThemes.safeGeist(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.9,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'What are we\nwatching?',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: inkColor,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
                PressableScale(
                  onTap: () => ref
                      .read(navigationProvider.notifier)
                      .setTab(AppTab.search),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.search, color: accColor, size: 19),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Movie / TV Toggle
            SegmentedMediaTypeToggle(
              activeType: navState.activeMediaType,
              onChanged: (type) => ref
                  .read(navigationProvider.notifier)
                  .setMediaType(type),
              isDark: isDark,
            ),
            const SizedBox(height: 22),

            // Continue Watching
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Continue watching',
                  style: AppThemes.safeGeist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                  ),
                ),
                PressableScale(
                  onTap: () => ref
                      .read(navigationProvider.notifier)
                      .setTab(AppTab.yourSpace),
                  child: Text(
                    'See all',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: SizedBox(
                key: ValueKey('continue_watching_$isMovies'),
                height: 140,
                child: popularAsync.when(
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: PressableScale(
                            child: OpenContainer(
                              transitionDuration: AppPhysics.houseSpringDuration,
                              closedElevation: 0,
                              openElevation: 0,
                              closedColor: Colors.transparent,
                              openColor: isDark ? AppColors.srBase : AppColors.rrBase,
                              middleColor: Colors.transparent,
                              closedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              closedBuilder: (context, openContainer) {
                                return GestureDetector(
                                  onTap: openContainer,
                                  child: SizedBox(
                                    width: 132,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 82.5, // aspect-ratio 16:10 roughly
                                          decoration: BoxDecoration(
                                            color: phColor,
                                            border: Border.all(color: lineRgba),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isDark
                                                    ? const Color.fromRGBO(
                                                        255, 255, 255, 0.05)
                                                    : const Color.fromRGBO(
                                                        255, 255, 255, 0.5),
                                                blurRadius: 0,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 1),
                                                blurStyle: BlurStyle.inner,
                                              )
                                            ],
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              MediaImage(
                                                item: item,
                                                fit: BoxFit.cover,
                                                showFallbackTitle: false,
                                              ),
                                              Positioned(
                                                top: 8,
                                                left: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? const Color.fromRGBO(
                                                            0, 0, 0, 0.55)
                                                        : const Color.fromRGBO(
                                                            44, 32, 22, 0.7),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'S2 · E4',
                                                    style: AppThemes.safeGeist(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  height: 4,
                                                  color: isDark
                                                      ? const Color.fromRGBO(
                                                          0, 0, 0, 0.4)
                                                      : const Color.fromRGBO(
                                                          44, 32, 22, 0.18),
                                                  alignment: Alignment.centerLeft,
                                                  child: FractionallySizedBox(
                                                    widthFactor: 0.62,
                                                    child: Container(color: accColor),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.title,
                                          style: AppThemes.safeGeist(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: inkColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '18 min left',
                                          style: AppThemes.safeGeist(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: subColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              openBuilder: (context, _) => DetailScreen(id: item.id),
                            ),
                          ),
                        ).animate().fade(duration: 250.ms).slideY(
                            begin: 0.1,
                            end: 0,
                            delay: (index.clamp(0, 5) * 40).ms);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Next episode highlight
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: AppPhysics.houseSpringCurve,
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 350),
                firstCurve: Curves.easeInOutCubic,
                secondCurve: Curves.easeInOutCubic,
                sizeCurve: AppPhysics.houseSpringCurve,
                crossFadeState: !isMovies
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 22),
                    PressableScale(
                      onTap: () => ref
                          .read(navigationProvider.notifier)
                          .setTab(AppTab.calendar),
                      child: AmbientGlowWidget(
                        enableAnimation: enableAnimation,
                        padding: const EdgeInsets.all(14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color.fromRGBO(214, 151, 132, 0.42)
                              : const Color.fromRGBO(167, 106, 80, 0.42),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color.fromRGBO(255, 255, 255, 0.08)
                                : const Color.fromRGBO(255, 255, 255, 0.5),
                            offset: const Offset(0, 1),
                            blurStyle: BlurStyle.inner,
                          )
                        ],
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 84, // 2/3 aspect ratio
                              decoration: BoxDecoration(
                                color: phColor,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: isDark
                                      ? const Color.fromRGBO(214, 151, 132, 0.32)
                                      : const Color.fromRGBO(167, 106, 80, 0.34),
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NEXT EPISODE',
                                    style: AppThemes.safeGeist(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.1,
                                      color: isDark
                                          ? const Color(0xFFE0A894)
                                          : const Color(0xFFA76A50),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Severance · S2 E6',
                                    style: AppThemes.safeGeist(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: inkColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Airs in 2 days · Fri, Aug 2',
                                    style: AppThemes.safeGeist(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: isDark
                                      ? const Color(0xFFE0A894)
                                      : const Color(0xFFA76A50),
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Calendar',
                                  style: AppThemes.safeGeist(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFFE0A894)
                                        : const Color(0xFFA76A50),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                secondChild: const SizedBox(width: double.infinity, height: 0),
              ),
            ),

            // Trending Carousel
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Trending now',
                  style: AppThemes.safeGeist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                  ),
                ),
                PressableScale(
                  onTap: () => ref
                      .read(navigationProvider.notifier)
                      .setTab(AppTab.search),
                  child: Text(
                    'See all',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: SizedBox(
                key: ValueKey('trending_$isMovies'),
                height: 144,
                child: trendingAsync.when(
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: PressableScale(
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
                                  child: Container(
                                    width: 96,
                                    height: 144, // 2/3 ratio
                                    decoration: BoxDecoration(
                                      color: phColor,
                                      border: Border.all(color: lineRgba),
                                      borderRadius: BorderRadius.circular(11),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark
                                              ? const Color.fromRGBO(
                                                  255, 255, 255, 0.05)
                                              : const Color.fromRGBO(
                                                  255, 255, 255, 0.5),
                                          offset: const Offset(0, 1),
                                          blurStyle: BlurStyle.inner,
                                        ),
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
                              openBuilder: (context, _) => DetailScreen(id: item.id),
                            ),
                          ),
                        ).animate().fade(duration: 250.ms).slideY(
                            begin: 0.1,
                            end: 0,
                            delay: (index.clamp(0, 5) * 40).ms);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Discover Invitation
            const SizedBox(height: 22),
            AmbientGlowWidget(
              enableAnimation: enableAnimation,
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color.fromRGBO(203, 168, 106, 0.4)
                    : const Color.fromRGBO(176, 81, 43, 0.36),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color.fromRGBO(255, 255, 255, 0.1)
                      : const Color.fromRGBO(255, 255, 255, 0.5),
                  offset: const Offset(0, 1),
                  blurStyle: BlurStyle.inner,
                )
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Not sure what to pick?',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: isDark ? inkColor : const Color(0xFF7A3418),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Swipe through tonight\'s stack. Skip, save, or add — one title at a time.',
                    style: AppThemes.safeGeist(
                      fontSize: 12.5,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      color: subColor,
                    ),
                  ),
                  const SizedBox(height: 13),
                  PressableScale(
                    onTap: () => ref
                        .read(navigationProvider.notifier)
                        .setTab(AppTab.discover),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: AppColors.primaryButtonDecoration(
                          isDark: isDark, borderRadius: 999),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Enter Discover',
                            style: AppThemes.safeGeist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF1A140C)
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 15,
                            color: isDark
                                ? const Color(0xFF1A140C)
                                : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

