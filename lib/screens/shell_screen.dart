import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/media_provider.dart';
import '../providers/ambiance_provider.dart';
import '../providers/chrome_visibility_provider.dart';
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

    // E1/TF-4: a fresh tab always starts with its top bar fully visible --
    // otherwise switching tabs while scrolled down elsewhere in a
    // permanently-mounted IndexedStack (see _buildBody) could strand the
    // bar hidden on a tab the user hasn't scrolled yet.
    ref.listen(navigationProvider.select((s) => s.currentTab), (previous, next) {
      if (previous != next) {
        ref.read(chromeVisibilityProvider.notifier).reset();
      }
    });

    return SizedBox.expand(
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        decoration: context.ambianceColors.background,
        child: AnimatedTheme(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          data: ambiance.themeData,
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: Colors.transparent,
                extendBody: true,
                body: ResponsiveLayout(
                  compact: (context) => _buildCompactLayout(
                    context,
                    ref,
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
    WidgetRef ref,
    NavigationState state,
    NavigationNotifier notifier,
    AppTheme ambiance,
    AmbianceNotifier ambianceNotifier,
    bool isDark,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final reservedBottomInset = 66.0 + 16.0 + 16.0 + mediaQuery.padding.bottom;
    final isChromeVisible = ref.watch(chromeVisibilityProvider);

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: AnimatedSize(
            duration: AppPhysics.houseSpringDuration,
            curve: AppPhysics.houseSpringCurve,
            alignment: Alignment.topCenter,
            child: AnimatedOpacity(
              duration: AppPhysics.houseSpringDuration,
              curve: AppPhysics.houseSpringCurve,
              opacity: isChromeVisible ? 1.0 : 0.0,
              child: isChromeVisible
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const UndoTopBarButton(isLarge: false),
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
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              ref
                  .read(chromeVisibilityProvider.notifier)
                  .handleScrollNotification(notification);
              return false;
            },
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
        ),
      ],
    );
  }

  Widget _buildLargeLayout(
    BuildContext context,
    NavigationState state,
    NavigationNotifier notifier,
    AppTheme ambiance,
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
                const UndoTopBarButton(isLarge: true),
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

    // B3: this used to wrap the IndexedStack in a KeyedSubtree keyed by
    // `tab`, which changed on every switch. PageTransitionSwitcher treats a
    // key change as "brand new subtree", so every single bottom-nav tap
    // destroyed and rebuilt all 5 tabs from scratch -- not just the one
    // becoming visible. That's what IndexedStack exists to prevent: each
    // tab's local state (e.g. YourSpaceScreen's selected sub-tab and
    // in-progress filter) was silently reset to its default on every visit,
    // which is the root cause behind TF-14's highlight/content desync.
    // _PersistentTabView below keeps a single stable IndexedStack (never
    // re-keyed, so children are never torn down) and animates the switch
    // itself instead of the subtree identity.
    return _PersistentTabView(
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
    );
  }
}

/// Keeps all tabs permanently mounted in a single, never-re-keyed
/// [IndexedStack] (so switching tabs never tears down another tab's state --
/// see the B3 note at the [ShellScreen._buildBody] call site) while still
/// animating the switch with a fade + subtle horizontal slide.
class _PersistentTabView extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _PersistentTabView({required this.index, required this.children});

  @override
  State<_PersistentTabView> createState() => _PersistentTabViewState();
}

class _PersistentTabViewState extends State<_PersistentTabView>
    with SingleTickerProviderStateMixin {
  // Snappier than AppPhysics.houseSpringDuration (550ms, tuned for large
  // one-off transitions like detail-page opens) -- this fires on every
  // bottom-nav tap, a frequent, lightweight interaction where 550ms would
  // feel sluggish. The slide still uses the house spring curve (its native
  // use case per AppPhysics' own doc comment) for motion-language
  // consistency (SP-2); opacity uses a plain ease curve since the spring's
  // characteristic overshoot would push it outside FadeTransition's valid
  // [0, 1] range.
  static const Duration _duration = Duration(milliseconds: 220);

  late final AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: 1.0,
    );
    _buildAnimations(reverseDirection: false);
  }

  void _buildAnimations({required bool reverseDirection}) {
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(reverseDirection ? -0.03 : 0.03, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppPhysics.houseSpringCurve));
  }

  @override
  void didUpdateWidget(covariant _PersistentTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _buildAnimations(reverseDirection: widget.index < oldWidget.index);
      _controller
        ..value = 0.0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: IndexedStack(
          index: widget.index,
          children: widget.children,
        ),
      ),
    );
  }
}

class UndoTopBarButton extends ConsumerWidget {
  final bool isLarge;
  const UndoTopBarButton({super.key, this.isLarge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    if (navState.currentTab != AppTab.discover) {
      return const SizedBox.shrink();
    }

    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;
    final deckState = ref.watch(isMovies ? discoverMoviesDeckProvider : discoverTvDeckProvider);
    final hasLastSwipe = deckState.lastSwipe != null;

    final accColor = context.ambianceColors.acc;
    final inkColor = context.ambianceColors.ink;
    final pillColor = context.ambianceColors.pill;

    return AnimatedScale(
      scale: hasLastSwipe ? 1.0 : 0.0,
      duration: AppPhysics.houseSpringDuration,
      curve: AppPhysics.houseSpringCurve,
      child: AnimatedOpacity(
        opacity: hasLastSwipe ? 1.0 : 0.0,
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        child: hasLastSwipe
            ? (isLarge
                ? PressableScale(
                    onTap: () {
                      ref.read(isMovies ? discoverMoviesDeckProvider.notifier : discoverTvDeckProvider.notifier).undoLastSwipe();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: pillColor,
                        border: Border.all(color: context.ambianceColors.lineRgba),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.undo, color: accColor, size: 18),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PressableScale(
                        onTap: () {
                          ref.read(isMovies ? discoverMoviesDeckProvider.notifier : discoverTvDeckProvider.notifier).undoLastSwipe();
                        },
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: pillColor,
                            border: Border.all(color: context.ambianceColors.lineRgba),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.undo, color: accColor, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Undo',
                                style: AppThemes.safeGeist(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: inkColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ))
            : const SizedBox.shrink(),
      ),
    );
  }
}
