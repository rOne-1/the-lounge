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
import 'browse_screen.dart';
import 'your_space_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends ConsumerWidget {
  final bool? enableAnimation;

  const ShellScreen({super.key, this.enableAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final navigationNotifier = ref.read(navigationProvider.notifier);
    final ambiance = ref.watch(ambianceProvider);
    final ambianceNotifier = ref.read(ambianceProvider.notifier);
    final isDark = context.ambianceColors.isDark;

    return SizedBox.expand(
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        decoration: context.ambianceColors.background,
        child: AnimatedTheme(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          data: AppThemes.theme(ambiance),
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
              child: IconButton(
                key: const ValueKey('settings_button'),
                icon: Icon(
                  Icons.settings_outlined,
                  color: context.ambianceColors.sub,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
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
                        color: Theme.of(context).extension<AmbianceColors>()!.lineRgba,
                      ),
                      borderRadius: BorderRadius.circular(33),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _buildNavItems(context, state, notifier, isDark),
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
                color: Theme.of(context).extension<AmbianceColors>()!.lineRgba,
              ),
            ),
          ),
          child: SafeArea(
            right: false,
            child: Column(
              children: [
                const SizedBox(height: 24),
                IconButton(
                  key: const ValueKey('settings_button'),
                  icon: Icon(
                    Icons.settings_outlined,
                    color: context.ambianceColors.sub,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildNavItems(context, state, notifier, isDark, isRail: true),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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

  List<Widget> _buildNavItems(BuildContext context, 
    NavigationState state,
    NavigationNotifier notifier,
    bool isDark, {
    bool isRail = false,
  }) {
    final accColor = context.ambianceColors.acc;
    final subColor = context.ambianceColors.sub;

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


  int _tabIndex(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return 0;
      case AppTab.discover:
        return 1;
      case AppTab.search:
      case AppTab.browse:
        return 2;
      case AppTab.yourSpace:
        return 3;
      case AppTab.calendar:
        return 4;
    }
  }

  Widget _buildBody(AppTab tab) {
    final index = _tabIndex(tab);

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
      child: KeyedSubtree(
        key: ValueKey(tab),
        child: IndexedStack(
          index: index,
          children: [
            HomeScreen(
              key: const PageStorageKey(AppTab.home),
              enableAnimation: enableAnimation,
            ),
            const DiscoverScreen(key: PageStorageKey(AppTab.discover)),
            const BrowseScreen(key: PageStorageKey(AppTab.search)),
            const YourSpaceScreen(key: PageStorageKey(AppTab.yourSpace)),
            const CalendarScreen(key: PageStorageKey(AppTab.calendar)),
          ],
        ),
      ),
    );
  }
}
