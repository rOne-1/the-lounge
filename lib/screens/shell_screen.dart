import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/ambiance_provider.dart';
import '../widgets/responsive_layout.dart';
import '../constants.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'search_screen.dart';
import 'your_space_screen.dart';
import 'calendar_screen.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final navigationNotifier = ref.read(navigationProvider.notifier);
    final ambiance = ref.watch(ambianceProvider);
    final ambianceNotifier = ref.read(ambianceProvider.notifier);
    final isDark = ambiance == AmbianceType.screeningRoom;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: isDark
            ? AppThemes.screeningRoomBackground()
            : AppThemes.readingRoomBackground(),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.srBase : AppColors.rrBase,
          extendBody: true,
          body: ResponsiveLayout(
            compact: (context) => _buildCompactLayout(
              context,
              navigationState,
              navigationNotifier,
              ambiance,
              ambianceNotifier,
              isDark,
            ),
            medium: (context) => _buildLargeLayout(
              context,
              navigationState,
              navigationNotifier,
              ambiance,
              ambianceNotifier,
              isDark,
            ),
            large: (context) => _buildLargeLayout(
              context,
              navigationState,
              navigationNotifier,
              ambiance,
              ambianceNotifier,
              isDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarToggle(
    BuildContext context,
    NavigationState state,
    NavigationNotifier notifier,
    bool isDark,
  ) {
    final bgColor = isDark ? AppColors.srPill : AppColors.rrPill;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final onAccColor = isDark ? const Color(0xFF1A140C) : Colors.white;

    Widget buildSegment(MediaTypeToggle type, String label) {
      final isSelected = state.activeMediaType == type;
      return GestureDetector(
        onTap: () => notifier.setMediaType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? accColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: isSelected ? onAccColor : subColor,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildSegment(MediaTypeToggle.movies, 'Movies'),
          const SizedBox(width: 2),
          buildSegment(MediaTypeToggle.tv, 'TV'),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    NavigationState state,
    NavigationNotifier notifier,
    AmbianceType ambiance,
    AmbianceNotifier ambianceNotifier,
    bool isDark,
  ) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopBarToggle(context, state, notifier, isDark),
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: isDark ? AppColors.srSub : AppColors.rrSub,
                    size: 20,
                  ),
                  onPressed: () => ambianceNotifier.toggleAmbiance(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _buildBody(state.currentTab)),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color.fromRGBO(12, 9, 7, 0.82)
                          : const Color.fromRGBO(240, 232, 216, 0.86),
                      border: Border.all(
                        color: isDark ? AppColors.srLineRgba : AppColors.rrLineRgba,
                      ),
                      borderRadius: BorderRadius.circular(33),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _buildNavItems(state, notifier, isDark),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLargeLayout(
    BuildContext context,
    NavigationState state,
    NavigationNotifier notifier,
    AmbianceType ambiance,
    AmbianceNotifier ambianceNotifier,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 80,
          decoration: BoxDecoration(
            color: isDark
                ? const Color.fromRGBO(12, 9, 7, 0.82)
                : const Color.fromRGBO(240, 232, 216, 0.86),
            border: Border(
              right: BorderSide(
                color: isDark ? AppColors.srLineRgba : AppColors.rrLineRgba,
              ),
            ),
          ),
          child: SafeArea(
            right: false,
            child: Column(
              children: [
                const SizedBox(height: 24),
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: isDark ? AppColors.srSub : AppColors.rrSub,
                    size: 20,
                  ),
                  onPressed: () => ambianceNotifier.toggleAmbiance(),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildNavItems(state, notifier, isDark, isRail: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                left: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTopBarToggle(context, state, notifier, isDark),
                  ),
                ),
              ),
              Expanded(
                child: _buildBody(state.currentTab),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNavItems(
    NavigationState state,
    NavigationNotifier notifier,
    bool isDark, {
    bool isRail = false,
  }) {
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

    Widget buildItem(AppTab tab, String label, IconData icon) {
      final isSelected = state.currentTab == tab;
      final color = isSelected ? accColor : subColor;

      final content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 9.5,
              color: color,
            ),
          ),
        ],
      );

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => notifier.setTab(tab),
        child: isRail
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: content,
              )
            : content,
      );
    }

    return [
      buildItem(AppTab.home, 'Home', Icons.home_outlined),
      buildItem(AppTab.discover, 'Discover', Icons.style_outlined),
      buildItem(AppTab.search, 'Search', Icons.search),
      buildItem(AppTab.yourSpace, 'Your space', Icons.bookmark_outline),
      buildItem(AppTab.calendar, 'Calendar', Icons.calendar_today_outlined),
    ];
  }

  Widget _buildBody(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return const HomeScreen();
      case AppTab.discover:
        return const DiscoverScreen();
      case AppTab.search:
        return const SearchScreen();
      case AppTab.yourSpace:
        return const YourSpaceScreen();
      case AppTab.calendar:
        return const CalendarScreen();
    }
  }
}
