import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/ambiance_provider.dart';
import '../widgets/whats_new_dialog.dart';
import '../constants.dart';
import 'lobby_screen.dart';
import 'discover_screen.dart';
import 'search_screen.dart';
import 'lounge_screen.dart';
import 'calendar_screen.dart';

class ShellScreen extends ConsumerWidget {
  final bool? enableAnimation;

  const ShellScreen({super.key, this.enableAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final ambiance = ref.watch(ambianceProvider);

    // NAV-1/PERS-NAV-1 / NAME-1: the last back press before exiting the app must
    // return to The Lounge first (the app's navigation anchor), not
    // terminate immediately from Lobby/Discover/Search/Calendar. canPop is
    // only true once already on The Lounge, so the OS pop/back gesture is
    // intercepted everywhere else and redirected.
    return PopScope(
      canPop: navigationState.currentTab == AppTab.lounge,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(navigationProvider.notifier).setTab(AppTab.lounge);
      },
      // IA-1/NAV-3: fixed chrome (top bar, bottom nav bar, per-screen media
      // toggles) is gone -- ShellScreen now reserves zero screen space for
      // navigation. The FloatingNavigationCapsule is the sole nav surface,
      // drawn as a free-floating overlay on top of full-bleed content.
      child: SizedBox.expand(
        child: AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          decoration: context.ambianceColors.background,
          child: AnimatedTheme(
            duration: AppPhysics.houseSpringDuration,
            curve: Curves.easeInOutCubic,
            data: ambiance.themeData,
            child: Stack(
              children: [
                Scaffold(
                  backgroundColor: Colors.transparent,
                  extendBody: true,
                  body: SafeArea(
                    bottom: false,
                    child: _buildBody(ref, navigationState.currentTab),
                  ),
                ),
                // FEAT-GRAIN-1: the grain overlay now lives once at the
                // MaterialApp.builder level (main.dart) so it covers every
                // route -- shell tabs AND pushed screens -- rather than
                // just here.
                WhatsNewGate(enableAnimation: enableAnimation),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _tabIndex(AppTab tab) {
    switch (tab) {
      case AppTab.lobby:
        return 0;
      case AppTab.discover:
        return 1;
      case AppTab.search:
        return 2;
      case AppTab.lounge:
        return 3;
      case AppTab.calendar:
        return 4;
    }
  }

  Widget _buildBody(WidgetRef ref, AppTab tab) {
    final index = _tabIndex(tab);

    VoidCallback? onSwipeLeft;
    VoidCallback? onSwipeRight;

    // HIERARCHICAL SWIPE MODEL:
    // 1. "The Lounge" is the elevated Sanctuary Gateway -- isolated with ZERO swipe navigation.
    // 2. "Discover" has dedicated 2D card deck gestures -- isolated with ZERO shell swipe interception.
    // 3. The Browse cycle forms an isolated 3-screen sequence: Lobby <-> Search <-> Calendar.
    switch (tab) {
      case AppTab.lobby:
        onSwipeLeft = () => ref.read(navigationProvider.notifier).setTab(AppTab.search);
        onSwipeRight = null;
        break;
      case AppTab.discover:
        onSwipeLeft = null;
        onSwipeRight = null;
        break;
      case AppTab.search:
        onSwipeLeft = () => ref.read(navigationProvider.notifier).setTab(AppTab.calendar);
        onSwipeRight = () => ref.read(navigationProvider.notifier).setTab(AppTab.lobby);
        break;
      case AppTab.calendar:
        onSwipeLeft = null;
        onSwipeRight = () => ref.read(navigationProvider.notifier).setTab(AppTab.search);
        break;
      case AppTab.lounge:
        onSwipeLeft = null;
        onSwipeRight = null;
        break;
    }

    return _PersistentTabView(
      index: index,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      children: [
        LobbyScreen(
          key: const PageStorageKey(AppTab.lobby),
          enableAnimation: enableAnimation,
        ),
        const DiscoverScreen(key: PageStorageKey(AppTab.discover)),
        const SearchScreen(key: PageStorageKey(AppTab.search)),
        LoungeScreen(
          key: const PageStorageKey(AppTab.lounge),
          enableAnimation: enableAnimation,
        ),
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
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const _PersistentTabView({
    required this.index,
    required this.children,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<_PersistentTabView> createState() => _PersistentTabViewState();
}

class _PersistentTabViewState extends State<_PersistentTabView>
    with SingleTickerProviderStateMixin {
  // Tuned for luxury micro-depth & parallax motion (360ms) with house spring curve
  // settling and easeOutCubic alpha fade.
  static const Duration _duration = Duration(milliseconds: 360);

  late final AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

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
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppPhysics.houseSpringCurve),
    );
    _slide = Tween<Offset>(
      begin: Offset(reverseDirection ? -0.05 : 0.05, 0),
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
    final transitionContent = FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: SlideTransition(
          position: _slide,
          child: IndexedStack(
            index: widget.index,
            children: widget.children,
          ),
        ),
      ),
    );

    // If swipe navigation is disabled for this tab (e.g. Discover screen's 2D swipe deck),
    // omit the GestureDetector entirely so child gestures are 100% unintercepted.
    if (widget.onSwipeLeft == null && widget.onSwipeRight == null) {
      return transitionContent;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0.0;
        // Require a deliberate swipe gesture (velocity > 300 dp/s)
        if (velocity < -300) {
          widget.onSwipeLeft?.call();
        } else if (velocity > 300) {
          widget.onSwipeRight?.call();
        }
      },
      child: transitionContent,
    );
  }
}
