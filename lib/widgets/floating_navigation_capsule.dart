import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/ambiance_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/hall_provider.dart';
import '../screens/settings_screen.dart';
import 'ambient_glow.dart';
import 'pressable_scale.dart';
import 'hall_selector_sheet.dart';

/// IA-1/NAV-3: the single floating, draggable, edge-snapping navigation
/// capsule that replaces ShellScreen's fixed top bar and bottom nav bar.
/// Collapsed it is a minimal frosted orb showing the active tab + media
/// type; tapping it expands an ambient command sheet with all 5 tab
/// destinations, the movie/TV toggle, and utility actions (Hall switcher,
/// Settings). BUGFIX-5: Discover's own undo button used to live here too,
/// moved to Discover's own top bar 2026-08-26 -- undo should be scoped to
/// the screen it affects, matching Rate Titles/Cleanup Swipe.
class FloatingNavigationCapsule extends ConsumerStatefulWidget {
  final bool? enableAnimation;

  /// When the capsule is hosted outside the app's Navigator subtree (the
  /// global overlay in main.dart's MaterialApp.builder -- a Stack sibling
  /// of the routed Navigator, not a descendant), `Navigator.of(context)`
  /// has no Navigator ancestor to find. Pass the app's root navigator key
  /// so navigation still works from there; omitted when the capsule is
  /// hosted somewhere that already sits inside a real Navigator context.
  final GlobalKey<NavigatorState>? navigatorKey;

  const FloatingNavigationCapsule(
      {super.key, this.enableAnimation, this.navigatorKey});

  @override
  ConsumerState<FloatingNavigationCapsule> createState() =>
      _FloatingNavigationCapsuleState();
}

class _FloatingNavigationCapsuleState
    extends ConsumerState<FloatingNavigationCapsule>
    with TickerProviderStateMixin {
  static const _prefsDxFractionKey = 'floating_nav_capsule_dx_fraction';
  static const _prefsDyFractionKey = 'floating_nav_capsule_dy_fraction';
  static const double _collapsedSize = 64.0;
  static const double _edgeMargin = 14.0;
  static const double _expandedWidth = 324.0;
  static const double _expandedHeight = 238.0;

  late final AnimationController _motionController;
  OffsetSpringSimulation? _currentSimulation;

  Offset? _topLeft;
  bool _expanded = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController.unbounded(vsync: this)
      ..addListener(_onMotionTick);
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  void _onMotionTick() {
    final sim = _currentSimulation;
    if (sim == null || !mounted) return;
    final elapsed = _motionController.lastElapsedDuration != null
        ? _motionController.lastElapsedDuration!.inMicroseconds / 1000000.0
        : 0.0;
    setState(() {
      _topLeft = sim.dxOffset(elapsed);
    });
  }

  Rect _dragBounds(Size screenSize, EdgeInsets safePadding) {
    return Rect.fromLTWH(
      _edgeMargin,
      safePadding.top + _edgeMargin,
      (screenSize.width - _collapsedSize - _edgeMargin * 2)
          .clamp(0.0, double.infinity),
      (screenSize.height -
              safePadding.top -
              safePadding.bottom -
              _collapsedSize -
              _edgeMargin * 2)
          .clamp(0.0, double.infinity),
    );
  }

  void _restoreOrDefault(Rect bounds) {
    if (_topLeft != null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final fx = prefs.getDouble(_prefsDxFractionKey);
    final fy = prefs.getDouble(_prefsDyFractionKey);
    if (fx != null && fy != null) {
      _topLeft = Offset(
        bounds.left + fx.clamp(0.0, 1.0) * bounds.width,
        bounds.top + fy.clamp(0.0, 1.0) * bounds.height,
      );
    } else {
      // Default dock: lower-right, thumb-reachable.
      _topLeft = Offset(bounds.right, bounds.top + bounds.height * 0.72);
    }
  }

  void _savePosition(Rect bounds) {
    final topLeft = _topLeft;
    if (topLeft == null || bounds.width <= 0 || bounds.height <= 0) return;
    final fx = ((topLeft.dx - bounds.left) / bounds.width).clamp(0.0, 1.0);
    final fy = ((topLeft.dy - bounds.top) / bounds.height).clamp(0.0, 1.0);
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setDouble(_prefsDxFractionKey, fx);
    prefs.setDouble(_prefsDyFractionKey, fy);
  }

  void _handlePanStart(DragStartDetails details) {
    if (_expanded) return;
    _motionController.stop();
    _currentSimulation = null;
    setState(() => _dragging = true);
  }

  void _handlePanUpdate(DragUpdateDetails details, Rect bounds) {
    if (_expanded || _topLeft == null) return;
    setState(() {
      _topLeft = Offset(
        (_topLeft!.dx + details.delta.dx).clamp(bounds.left, bounds.right),
        (_topLeft!.dy + details.delta.dy).clamp(bounds.top, bounds.bottom),
      );
    });
  }

  void _handlePanEnd(DragEndDetails details, Rect bounds) {
    if (_expanded || _topLeft == null) return;
    setState(() => _dragging = false);

    final center = _topLeft!.dx + _collapsedSize / 2;
    final midpoint = bounds.left + (bounds.width + _collapsedSize) / 2;
    final targetX = center < midpoint ? bounds.left : bounds.right;
    final targetY = _topLeft!.dy.clamp(bounds.top, bounds.bottom);

    final sim = OffsetSpringSimulation(
      startX: _topLeft!.dx,
      endX: targetX,
      velocityX: details.velocity.pixelsPerSecond.dx,
      startY: _topLeft!.dy,
      endY: targetY,
      velocityY: details.velocity.pixelsPerSecond.dy,
    );
    _currentSimulation = sim;
    _motionController.stop();
    _motionController.animateWith(sim).whenComplete(() {
      if (mounted) _savePosition(bounds);
    });
    HapticFeedback.selectionClick();
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  void _collapse() {
    if (!_expanded) return;
    setState(() => _expanded = false);
  }

  NavigatorState get _navigator =>
      widget.navigatorKey?.currentState ??
      Navigator.of(context, rootNavigator: true);

  void _selectTab(AppTab tab) {
    HapticFeedback.selectionClick();
    final nav = _navigator;
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
    ref.read(navigationProvider.notifier).setTab(tab);
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bounds = _dragBounds(mediaQuery.size, mediaQuery.padding);
    if (bounds.width <= 0 || bounds.height <= 0) {
      return const SizedBox.shrink();
    }
    _restoreOrDefault(bounds);
    final topLeft = _topLeft!;

    final expandedLeft = (topLeft.dx + _collapsedSize / 2 - _expandedWidth / 2)
        .clamp(
            _edgeMargin, mediaQuery.size.width - _expandedWidth - _edgeMargin);
    final maxExpandedTop = mediaQuery.size.height -
        mediaQuery.padding.bottom -
        _expandedHeight -
        _edgeMargin;
    final expandedTop = (topLeft.dy + _collapsedSize / 2 - _expandedHeight / 2)
        .clamp(mediaQuery.padding.top + _edgeMargin,
            maxExpandedTop.clamp(0.0, double.infinity));

    final bool isSettling = _motionController.isAnimating;
    final Duration positionDuration = (_dragging || isSettling)
        ? Duration.zero
        : AppPhysics.houseSpringDuration;

    final scrimColor = context.ambianceColors.scrim;

    return Stack(
      children: [
        // NAV-DIM-1: dims the screen behind the capsule while expanded, so
        // its text/icons stay readable over busy backgrounds. Always
        // present (not `if (_expanded)`) so AnimatedOpacity can fade it in
        // and out instead of popping instantly; IgnorePointer keeps it out
        // of the hit-test tree entirely while invisible, so it never
        // intercepts taps meant for the screen underneath.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_expanded,
            child: AnimatedOpacity(
              opacity: _expanded ? 1 : 0,
              duration: AppPhysics.houseSpringDuration,
              curve: AppPhysics.houseSpringCurve,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _collapse,
                child: Container(color: scrimColor),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: positionDuration,
          curve: AppPhysics.houseSpringCurve,
          left: _expanded ? expandedLeft : topLeft.dx,
          top: _expanded ? expandedTop : topLeft.dy,
          child: GestureDetector(
            key: const ValueKey('floating_nav_capsule'),
            onTap: _toggleExpanded,
            onPanStart: _handlePanStart,
            onPanUpdate: (d) => _handlePanUpdate(d, bounds),
            onPanEnd: (d) => _handlePanEnd(d, bounds),
            child: _CapsuleBody(
              expanded: _expanded,
              collapsedSize: _collapsedSize,
              expandedWidth: _expandedWidth,
              expandedHeight: _expandedHeight,
              enableAnimation: widget.enableAnimation,
              onSelectTab: _selectTab,
              onSettings: () {
                HapticFeedback.selectionClick();
                setState(() => _expanded = false);
                _navigator.push(
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
              onProfileSelector: () {
                HapticFeedback.selectionClick();
                setState(() => _expanded = false);
                HallSelectorSheet.show(_navigator.context);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CapsuleBody extends ConsumerWidget {
  final bool expanded;
  final double collapsedSize;
  final double expandedWidth;
  final double expandedHeight;
  final bool? enableAnimation;
  final ValueChanged<AppTab> onSelectTab;
  final VoidCallback onSettings;
  final VoidCallback onProfileSelector;

  const _CapsuleBody({
    required this.expanded,
    required this.collapsedSize,
    required this.expandedWidth,
    required this.expandedHeight,
    required this.enableAnimation,
    required this.onSelectTab,
    required this.onSettings,
    required this.onProfileSelector,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambiance = context.ambianceColors;
    final animDuration = (enableAnimation ?? true)
        ? AppPhysics.houseSpringDuration
        : Duration.zero;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: expanded ? 1.0 : 0.0,
        end: expanded ? 1.0 : 0.0,
      ),
      duration: animDuration,
      curve: AppPhysics.houseSpringCurve,
      builder: (context, expandProgress, child) {
        final currentWidth =
            lerpDouble(collapsedSize, expandedWidth, expandProgress)!;
        final currentHeight =
            lerpDouble(collapsedSize, expandedHeight, expandProgress)!;
        final currentRadius =
            lerpDouble(collapsedSize / 2, 28, expandProgress.clamp(0.0, 1.0))!;

        return Container(
          width: currentWidth,
          height: currentHeight,
          decoration: BoxDecoration(
            color:
                ambiance.card2.withValues(alpha: ambiance.isDark ? 0.82 : 0.95),
            borderRadius: BorderRadius.circular(currentRadius),
            border: Border.all(color: ambiance.surfaceHighlight, width: 1),
            boxShadow: ambiance.ambientGlowShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );
      },
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            type: MaterialType.transparency,
            child: AnimatedSwitcher(
              duration: animDuration,
              switchInCurve: AppPhysics.houseSpringCurve,
              switchOutCurve: Curves.easeOut,
              child: expanded
                  ? OverflowBox(
                      key: const ValueKey('expanded'),
                      alignment: Alignment.topLeft,
                      minWidth: 0,
                      maxWidth: expandedWidth,
                      minHeight: 0,
                      maxHeight: expandedHeight,
                      child: SizedBox(
                        width: expandedWidth,
                        height: expandedHeight,
                        child: _ExpandedContent(
                          onSelectTab: onSelectTab,
                          onSettings: onSettings,
                          onProfileSelector: onProfileSelector,
                        ),
                      ),
                    )
                  : OverflowBox(
                      key: const ValueKey('collapsed'),
                      alignment: Alignment.center,
                      minWidth: 0,
                      maxWidth: collapsedSize,
                      minHeight: 0,
                      maxHeight: collapsedSize,
                      child: SizedBox(
                        width: collapsedSize,
                        height: collapsedSize,
                        child:
                            _CollapsedContent(enableAnimation: enableAnimation),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedContent extends ConsumerWidget {
  final bool? enableAnimation;

  const _CollapsedContent({required this.enableAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final ambiance = context.ambianceColors;
    final icon = _iconForTab(navState.currentTab);
    final mediaIcon = navState.activeMediaType == MediaTypeToggle.movies
        ? Icons.movie_creation_outlined
        : Icons.live_tv_outlined;

    return AmbientGlowWidget(
      enableAnimation: enableAnimation,
      borderRadius: BorderRadius.circular(999),
      baseColor: ambiance.card2.withValues(alpha: 0.72),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: ambiance.acc, size: 24),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: ambiance.pill,
                shape: BoxShape.circle,
                border: Border.all(color: ambiance.lineRgba, width: 0.5),
              ),
              child: Icon(mediaIcon, color: ambiance.sub, size: 10),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForTab(AppTab tab) {
    switch (tab) {
      case AppTab.lobby:
        return Icons.theaters_outlined;
      case AppTab.discover:
        return Icons.style_outlined;
      case AppTab.search:
        return Icons.search;
      case AppTab.lounge:
        return Icons.bookmark_outline;
      case AppTab.calendar:
        return Icons.calendar_today_outlined;
    }
  }
}

class _ExpandedContent extends ConsumerWidget {
  final ValueChanged<AppTab> onSelectTab;
  final VoidCallback onSettings;
  final VoidCallback onProfileSelector;

  const _ExpandedContent({
    required this.onSelectTab,
    required this.onSettings,
    required this.onProfileSelector,
  });

  // PERS-NAV-1 / NAME-1: The Lounge leads the list, reflecting its role as the app's
  // navigation anchor (default startup tab, and where back-navigation from
  // every other tab lands).
  static const _destinations = [
    (AppTab.lounge, 'Lounge', Icons.bookmark_outline),
    (AppTab.lobby, 'Lobby', Icons.theaters_outlined),
    (AppTab.discover, 'Discover', Icons.style_outlined),
    (AppTab.search, 'Search', Icons.search),
    (AppTab.calendar, 'Calendar', Icons.calendar_today_outlined),
  ];

  static IconData _iconForHall(String iconKey) {
    switch (iconKey) {
      case 'arch':
        return Icons.meeting_room_rounded;
      case 'reel':
        return Icons.movie_filter_rounded;
      case 'curtain':
        return Icons.auto_awesome_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'sparkles':
        return Icons.auto_awesome_rounded;
      case 'popcorn':
        return Icons.movie_filter_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'movie':
        return Icons.local_movies_rounded;
      default:
        return Icons.theater_comedy_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final activeHall = ref.watch(activeHallSpaceProvider);
    final notifier = ref.read(navigationProvider.notifier);
    final ambiance = context.ambianceColors;

    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final destination in _destinations)
                Expanded(
                  child: _DestinationPill(
                    key: ValueKey('floating_nav_tab_${destination.$1.name}'),
                    isSelected: navState.currentTab == destination.$1,
                    icon: destination.$3,
                    label: destination.$2,
                    onTap: () => onSelectTab(destination.$1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: ambiance.lineRgba),
          const SizedBox(height: 12),
          _MediaTypeRow(
            isMovies: isMovies,
            onChanged: (type) {
              HapticFeedback.selectionClick();
              notifier.setMediaType(type);
            },
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: ambiance.lineRgba),
          const SizedBox(height: 12),
          Row(
            children: [
              _UtilityAction(
                key: const ValueKey('floating_nav_profile_button'),
                icon: _iconForHall(activeHall.iconKey),
                label: activeHall.name,
                // BETA3-A11Y-1: explicit active-Hall announcement -- the
                // bare Hall name alone (e.g. "The Grand Hall") doesn't
                // convey that this button switches Halls or which one is
                // currently active.
                semanticLabel: 'Switch Hall, current Hall: ${activeHall.name}',
                onTap: onProfileSelector,
              ),
              const SizedBox(width: 8),
              _UtilityAction(
                key: const ValueKey('floating_nav_settings_button'),
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: onSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DestinationPill extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DestinationPill({
    super.key,
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;
    final color = isSelected ? ambiance.acc : ambiance.sub;

    // BETA3-A11Y-1: one explicit merged announcement ("Lobby tab, selected")
    // instead of the icon (no label) and Text being read as two separate,
    // disconnected fragments.
    return Semantics(
      label: '$label tab',
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppPhysics.houseSpringDuration,
              curve: AppPhysics.houseSpringCurve,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? ambiance.pill : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppThemes.safeGeist(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTypeRow extends StatelessWidget {
  final bool isMovies;
  final ValueChanged<MediaTypeToggle> onChanged;

  const _MediaTypeRow({required this.isMovies, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;
    final onAccColor = Theme.of(context).colorScheme.onPrimary;

    Widget segment(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: Semantics(
          label: label,
          selected: selected,
          button: true,
          excludeSemantics: true,
          child: PressableScale(
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppPhysics.houseSpringDuration,
              curve: AppPhysics.houseSpringCurve,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? ambiance.acc : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: AppThemes.safeGeist(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? onAccColor : ambiance.sub,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: ambiance.pill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          segment('Movies', isMovies, () => onChanged(MediaTypeToggle.movies)),
          segment('TV', !isMovies, () => onChanged(MediaTypeToggle.tv)),
        ],
      ),
    );
  }
}

class _UtilityAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const _UtilityAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;
    final color = ambiance.ink;

    return Expanded(
      child: Semantics(
        label: semanticLabel ?? label,
        button: true,
        excludeSemantics: semanticLabel != null,
        child: PressableScale(
          onTap: onTap ?? () {},
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: ambiance.pill,
              border: Border.all(color: ambiance.lineRgba),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: AppPhysics.houseSpringDuration,
                    switchInCurve: AppPhysics.houseSpringCurve,
                    switchOutCurve: Curves.easeOut,
                    child: Text(
                      label,
                      key: ValueKey(label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemes.safeGeist(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
