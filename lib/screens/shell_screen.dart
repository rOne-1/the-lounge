import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import '../providers/navigation_provider.dart';
import '../providers/ambiance_provider.dart';
import '../widgets/noise_texture_overlay.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/pressable_scale.dart';
import '../constants.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'search_screen.dart';
import 'your_space_screen.dart';
import 'calendar_screen.dart';

class ShellScreen extends ConsumerWidget {
  final bool? enableAnimation;

  const ShellScreen({super.key, this.enableAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final navigationNotifier = ref.read(navigationProvider.notifier);
    final ambiance = ref.watch(ambianceProvider);
    final ambianceNotifier = ref.read(ambianceProvider.notifier);
    final isDark = ambiance == AmbianceType.screeningRoom;

    return SizedBox.expand(
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        decoration: isDark
            ? AppThemes.screeningRoomBackground()
            : AppThemes.readingRoomBackground(),
        child: AnimatedTheme(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          data: isDark
              ? AppThemes.screeningRoomTheme
              : AppThemes.readingRoomTheme,
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: Colors.transparent,
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
              const Positioned.fill(
                child: AppNoiseTexture(),
              ),
            ],
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
    return SegmentedMediaTypeToggle(
      activeType: state.activeMediaType,
      onChanged: notifier.setMediaType,
      isDark: isDark,
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
    final mediaQuery = MediaQuery.of(context);
    final reservedBottomInset = 66.0 + 16.0 + 16.0 + mediaQuery.padding.bottom;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: PressableScale(
                onTap: () => ambianceNotifier.toggleAmbiance(),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: AppPhysics.houseSpringDuration,
                    switchInCurve: AppPhysics.houseSpringCurve,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      key: ValueKey(isDark),
                      color: isDark ? AppColors.srSub : AppColors.rrSub,
                      size: 20,
                    ),
                  ),
                  onPressed: () => ambianceNotifier.toggleAmbiance(),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: MediaQuery(
                  data: mediaQuery.copyWith(
                    padding: mediaQuery.padding.copyWith(
                      bottom: reservedBottomInset,
                    ),
                    viewPadding: mediaQuery.viewPadding.copyWith(
                      bottom: reservedBottomInset,
                    ),
                  ),
                  child: _buildBody(state.currentTab),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: SafeArea(
                  top: false,
                  child: AnimatedContainer(
                    duration: AppPhysics.houseSpringDuration,
                    curve: AppPhysics.houseSpringCurve,
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
        AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
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
                PressableScale(
                  onTap: () => ambianceNotifier.toggleAmbiance(),
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: AppPhysics.houseSpringDuration,
                      switchInCurve: AppPhysics.houseSpringCurve,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        key: ValueKey(isDark),
                        color: isDark ? AppColors.srSub : AppColors.rrSub,
                        size: 20,
                      ),
                    ),
                    onPressed: () => ambianceNotifier.toggleAmbiance(),
                  ),
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

      return PressableScale(
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
    Widget child;
    switch (tab) {
      case AppTab.home:
        child = HomeScreen(
          key: const ValueKey(AppTab.home),
          enableAnimation: enableAnimation,
        );
      case AppTab.discover:
        child = const DiscoverScreen(key: ValueKey(AppTab.discover));
      case AppTab.search:
        child = const SearchScreen(key: ValueKey(AppTab.search));
      case AppTab.yourSpace:
        child = const YourSpaceScreen(key: ValueKey(AppTab.yourSpace));
      case AppTab.calendar:
        child = const CalendarScreen(key: ValueKey(AppTab.calendar));
    }

    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (
        Widget child,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
      ) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
  }
}
