import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/ambiance_provider.dart';
import '../widgets/noise_texture_overlay.dart';
import '../widgets/floating_navigation_capsule.dart';
import '../widgets/whats_new_dialog.dart';
import '../constants.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'browse_screen.dart';
import 'your_space_screen.dart';
import 'calendar_screen.dart';

class ShellScreen extends ConsumerWidget {
  final bool? enableAnimation;

  const ShellScreen({super.key, this.enableAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final ambiance = ref.watch(ambianceProvider);

    // NAV-1: the last back press before exiting the app must return to
    // Home first, not terminate immediately from Discover/Browse/YourSpace/
    // Calendar. canPop is only true once already on Home, so the OS
    // pop/back gesture is intercepted everywhere else and redirected.
    return PopScope(
      canPop: navigationState.currentTab == AppTab.home,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(navigationProvider.notifier).setTab(AppTab.home);
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
            curve: AppPhysics.houseSpringCurve,
            data: ambiance.themeData,
            child: Stack(
              children: [
                Scaffold(
                  backgroundColor: Colors.transparent,
                  extendBody: true,
                  body: SafeArea(
                    bottom: false,
                    child: _buildBody(navigationState.currentTab),
                  ),
                ),
                const Positioned.fill(
                  child: AppNoiseTexture(),
                ),
                FloatingNavigationCapsule(enableAnimation: enableAnimation),
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
