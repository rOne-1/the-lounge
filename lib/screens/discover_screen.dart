import '../constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'dart:math' as math;
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/media_item.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_screen.dart';

import '../widgets/drag_to_dismiss_sheet.dart';
import '../widgets/lounge_toast.dart';
import '../widgets/quick_status_sheet.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  bool _showLegend = true;
  bool _isSwiping = false;
  String? _activeSwipeDirection;
  final Map<String, GlobalKey<_SwipeCardState>> _cardKeys = {};

  bool _isUnreleased(MediaItem item) {
    if (item.releaseDate != null && item.releaseDate!.isAfter(DateTime.now())) {
      return true;
    }
    if (item.status != null) {
      final s = item.status!.toLowerCase();
      if (s == 'unreleased' || s == 'in production' || s == 'planned') {
        return true;
      }
    }
    return false;
  }

  void _onDirectionChanged(String? direction) {
    if (_activeSwipeDirection != direction) {
      setState(() {
        _activeSwipeDirection = direction;
      });
    }
  }

  void _onSwipe(MediaItem item, String direction) {

    final notifier = ref.read(mediaProvider.notifier);
    if (direction == 'Left') {
      ref.read(skippedMediaIdsProvider.notifier).add(item.id);
      ref.read(skippedMediaIdsProvider.notifier).add(item.prefixedId);
    } else if (direction == 'Right') {
      notifier.addToMaybeList(item);
    } else if (direction == 'Down') {
      notifier.addToWatchlist(item);
    } else if (direction == 'Up') {
      if (_isUnreleased(item)) {
        LoungeToast.show(context, 'This title has not been released yet.');
        return;
      }
      notifier.addToWatchedList(item);
    }

    if (mounted) {
      setState(() {
        _activeSwipeDirection = null;
        _cardKeys.remove(item.id);
      });
      
      final isMovies = ref.read(navigationProvider).activeMediaType == MediaTypeToggle.movies;
      final deckNotifier = isMovies ? ref.read(discoverMoviesDeckProvider.notifier) : ref.read(discoverTvDeckProvider.notifier);
      deckNotifier.popCard(item, direction);
    }
  }

  void _triggerSwipe(String direction) {
    final navState = ref.read(navigationProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;
    final deckState = ref.read(isMovies ? discoverMoviesDeckProvider : discoverTvDeckProvider);
    final pool = deckState.pool;

    if (pool.isEmpty || _isSwiping) return;
    _isSwiping = true;
    setState(() {
      _activeSwipeDirection = direction;
    });
    final topItem = pool.first;
    final topKey = _cardKeys[topItem.id];

    if (topKey?.currentState != null) {
      topKey!.currentState!.flyOff(direction, () {
        _onSwipe(topItem, direction);
        _isSwiping = false;
      });
    } else {
      _onSwipe(topItem, direction);
      _isSwiping = false;
    }
  }

  GlobalKey<_SwipeCardState> _getKeyFor(String id) {
    return _cardKeys.putIfAbsent(id, () => GlobalKey<_SwipeCardState>());
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;
    final deckState = ref.watch(isMovies ? discoverMoviesDeckProvider : discoverTvDeckProvider);
    final pool = deckState.pool;
    final loading = deckState.isLoading;
    final error = deckState.error;

    final isDark = context.ambianceColors.isDark;
    
    final subColor = context.ambianceColors.sub;
    final accColor = context.ambianceColors.acc;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      final message = error.toString().replaceAll('Exception: ', '');
      return FullScreenErrorWidget(
        message: message.isNotEmpty
            ? message
            : 'Failed to load recommendations. Please check your connection.',
        onRetry: () => ref.read(isMovies ? discoverMoviesDeckProvider.notifier : discoverTvDeckProvider.notifier).loadPool(isReload: true),
      );
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;

    return Stack(
      children: [
        Column(
          children: [
            // Top bar: legend key (media toggle now lives in the floating
            // navigation capsule, NAV-3).
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isLarge ? 24 : 18, isLarge ? 0 : 2, isLarge ? 24 : 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PressableScale(
                    onTap: () => setState(() => _showLegend = true),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: subColor, size: 15),
                        const SizedBox(width: 6),
                        Text('Legend',
                            style: AppThemes.safeGeist(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: subColor)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            // Card Stack
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Back cards
                    Positioned(
                      top: 26, left: 8, right: 8, bottom: 20,
                      child: Transform.scale(
                        scale: 0.92,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.ambianceColors.card2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.ambianceColors.lineRgba.withValues(alpha: 0.1)),
                          ),
                          child: Opacity(opacity: isDark ? 0.5 : 0.6),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16, left: 4, right: 4, bottom: 20,
                      child: Transform.scale(
                        scale: 0.96,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.ambianceColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.ambianceColors.lineRgba.withValues(alpha: 0.14)),
                          ),
                          child: Opacity(opacity: isDark ? 0.7 : 0.8),
                        ),
                      ),
                    ),
                    // Active cards
                    if (pool.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  deckState.canManuallyReloadToday
                                      ? Icons.movie_filter_outlined
                                      : Icons.nightlight_round,
                                  size: 64, color: subColor),
                              const SizedBox(height: 16),
                              Text(
                                deckState.canManuallyReloadToday
                                    ? 'No titles in recommendations'
                                    : 'You\'re all caught up',
                                style: AppThemes.safeGeist(
                                    color: context.ambianceColors.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                deckState.canManuallyReloadToday
                                    ? 'You\'ve gone through all available recommendations in this stack.'
                                    : 'Come back tomorrow for more — today\'s deck (and its one reload) is used up.',
                                textAlign: TextAlign.center,
                                style: AppThemes.safeGeist(
                                    color: subColor, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              // B9: normal swipe pagination stays unlimited
                              // within a session (see popCard) -- this
                              // button is the one thing capped to once per
                              // calendar day, per dev decision.
                              if (deckState.canManuallyReloadToday)
                                FilledButton.icon(
                                  onPressed: loading
                                      ? null
                                      : () => ref
                                          .read(isMovies
                                              ? discoverMoviesDeckProvider.notifier
                                              : discoverTvDeckProvider.notifier)
                                          .manualReload(),
                                  icon: loading
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.refresh),
                                  label: const Text('Reload deck'),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...pool.reversed.map((item) {
                        final isTop = item.id == pool.first.id;
                        final isUndone = item.id == deckState.undoneMediaId;
                        return SwipeCard(
                          key: _getKeyFor(item.id),
                          item: item,
                          isInteractive: isTop,
                          onSwipe: (dir) => _onSwipe(item, dir),
                          onDirectionChanged: isTop ? _onDirectionChanged : null,
                          isDark: isDark,
                          accColor: accColor,
                          entryDirection: isUndone ? deckState.undoneDirection : null,
                        );
                      }),
                  ],
                ),
              ),
            ),
            // Action buttons row
            Builder(builder: (context) {
              final mediaState = ref.watch(mediaProvider);
              final topItem = pool.isNotEmpty ? pool.first : null;
              final isWatchlist = topItem != null &&
                  (mediaState.watchlist.containsKey(topItem.prefixedId) ||
                      mediaState.watchlist.containsKey(topItem.id));
              final isMaybe = topItem != null &&
                  (mediaState.maybeList.containsKey(topItem.prefixedId) ||
                      mediaState.maybeList.containsKey(topItem.id));
              final isWatched = topItem != null &&
                  (mediaState.watchedList.containsKey(topItem.prefixedId) ||
                      mediaState.watchedList.containsKey(topItem.id));
              final isSkipped = topItem != null &&
                  (ref.watch(skippedMediaIdsProvider).containsKey(topItem.prefixedId) ||
                      ref.watch(skippedMediaIdsProvider).containsKey(topItem.id));

              return Padding(
                padding: EdgeInsets.fromLTRB(0, 14.0, 0, 14.0 + MediaQuery.of(context).padding.bottom),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButtonWithLabel(
                      label: '← Skip',
                      button: _buildActionButton(
                        icon: Icons.close,
                        color: context.ambianceColors.sub,
                        borderColor: context.ambianceColors.lineRgba,
                        direction: 'Left',
                        onTap: () => _triggerSwipe('Left'),
                        isDark: isDark,
                        isHighlighted: isSkipped,
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 14),
                    _buildActionButtonWithLabel(
                      label: '→ Saved',
                      button: _buildActionButton(
                        icon: Icons.star_border,
                        activeIcon: Icons.star,
                        color: AppStatusColors.save,
                        borderColor: AppStatusColors.save.withValues(alpha: 0.55),
                        direction: 'Right',
                        onTap: () => _triggerSwipe('Right'),
                        isDark: isDark,
                        isHighlighted: isMaybe,
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 14),
                    _buildActionButtonWithLabel(
                      label: '↓ Watchlist',
                      button: _buildWatchlistActionButton(
                        isDark: isDark,
                        accColor: accColor,
                        isWatchlist: isWatchlist,
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 14),
                    _buildActionButtonWithLabel(
                      label: '↑ Watched',
                      button: _buildActionButton(
                        icon: Icons.check,
                        color: AppStatusColors.watched,
                        borderColor: AppStatusColors.watched.withValues(alpha: 0.55),
                        direction: 'Up',
                        onTap: () => _triggerSwipe('Up'),
                        isDark: isDark,
                        isHighlighted: isWatched,
                      ),
                      isDark: isDark,
                    ),
                  ],
                ),
              );
            })
          ],
        ),
        _buildLegendOverlay(isDark, accColor),
      ],
    );
  }

  Widget _buildActionButtonWithLabel({
    required String label,
    required Widget button,
    required bool isDark,
  }) {
    final subColor = context.ambianceColors.sub;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 4),
        Text(
          label,
          style: AppThemes.safeGeist(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: subColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    IconData? activeIcon,
    required Color color,
    required Color borderColor,
    required String direction,
    required VoidCallback onTap,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    final isActive = _activeSwipeDirection == direction || isHighlighted;
    final effectiveIcon = isActive && activeIcon != null ? activeIcon : icon;
    final activeBg = color.withValues(alpha: isDark ? 0.35 : 0.25);

    return AnimatedScale(
      scale: isActive ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeBg : Colors.transparent,
            border: Border.all(
              color: isActive ? color : borderColor,
              width: isActive ? 2.0 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.5 : 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            effectiveIcon,
            color: color,
            size: isActive ? 21 : 19,
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistActionButton({
    required bool isDark,
    required Color accColor,
    bool isWatchlist = false,
  }) {
    final isActive = _activeSwipeDirection == 'Down' || isWatchlist;
    final glowColor = accColor;

    return AnimatedScale(
      scale: isActive ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: PressableScale(
        onTap: () => _triggerSwipe('Down'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: 54,
          height: 54,
          decoration: context.ambianceColors.primaryButtonDecoration.copyWith(
                  border: isActive
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.6),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ]
                      : null,
                ),
          child: Icon(
            isActive ? Icons.bookmark : Icons.bookmark_border,
            color: Theme.of(context).colorScheme.onPrimary,
            size: isActive ? 26 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendOverlay(bool isDark, Color accColor) {
    final titleColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final borderColor = context.ambianceColors.lineRgba;
    final backdropColor = context.ambianceColors.base.withValues(alpha: 0.85);
    
    // Instead of using hardcoded sheetBgColors, we can reuse base and card colors
    final sheetBgColors = [context.ambianceColors.base, context.ambianceColors.card];
    final innerShadowColor = context.ambianceColors.surfaceHighlight;
    final btnTextColor = Theme.of(context).colorScheme.onPrimary;

    return IgnorePointer(
      ignoring: !_showLegend,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: _showLegend ? 1.0 : 0.0,
            child: GestureDetector(
              onTap: () => setState(() => _showLegend = false),
              child: Container(
                color: backdropColor,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              offset: _showLegend ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                opacity: _showLegend ? 1.0 : 0.0,
                child: DragToDismissSheet(
                  isDark: isDark,
                  onDismiss: () => setState(() => _showLegend = false),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      10,
                      24,
                      34.0 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: sheetBgColors,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                      border: Border(top: BorderSide(color: borderColor)),
                      boxShadow: [
                        BoxShadow(
                          color: innerShadowColor,
                          blurRadius: 0,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                          blurStyle: BlurStyle.inner,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'How the deck works',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Swipe a card, or use the buttons. Shown once.',
                          style: AppThemes.safeGeist(
                            fontSize: 12.5,
                            color: subColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLegendItem(
                          isDark: isDark,
                          icon: Icons.arrow_back,
                          title: 'Swipe left — Skip for now',
                          subtitle: 'Won\'t reappear for 6 months — skip it 6 times and it\'s gone for good',
                          color: context.ambianceColors.sub,
                          bgColor: context.ambianceColors.sub.withValues(alpha: 0.16),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          isDark: isDark,
                          icon: Icons.arrow_forward,
                          title: 'Swipe right — Save for later',
                          subtitle: 'A "maybe" bookmark → lands in your Maybe pile',
                          color: AppStatusColors.save,
                          bgColor: AppStatusColors.save.withValues(alpha: 0.16),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          isDark: isDark,
                          icon: Icons.arrow_downward,
                          title: 'Swipe down — Add to watchlist',
                          subtitle: 'A committed pick you intend to watch',
                          color: AppStatusColors.watchlist,
                          bgColor: AppStatusColors.watchlist.withValues(alpha: 0.16),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          isDark: isDark,
                          icon: Icons.arrow_upward,
                          title: 'Swipe up — Already watched',
                          subtitle: 'Logs to Watched history',
                          color: AppStatusColors.watched,
                          bgColor: AppStatusColors.watched.withValues(alpha: 0.16),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          isDark: isDark,
                          icon: Icons.touch_app,
                          title: 'Tap — Open full details',
                          subtitle: 'The complete Movie / TV detail view',
                          color: context.ambianceColors.ink,
                          bgColor: context.ambianceColors.ink.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 22),
                        PressableScale(
                          onTap: () => setState(() => _showLegend = false),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: context.ambianceColors.primaryButtonDecoration.copyWith(borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Text(
                              'Got it — start swiping',
                              style: AppThemes.safeGeist(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: btnTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    final titleColor = context.ambianceColors.ink;
    final subtitleColor = context.ambianceColors.sub;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppThemes.safeGeist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              Text(
                subtitle,
                style: AppThemes.safeGeist(
                  fontSize: 11.5,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class SwipeCard extends ConsumerStatefulWidget {
  final MediaItem item;
  final bool isInteractive;
  final Function(String) onSwipe;
  final ValueChanged<String?>? onDirectionChanged;
  final bool isDark;
  final Color accColor;
  final String? entryDirection;

  const SwipeCard({
    super.key,
    required this.item,
    required this.isInteractive,
    required this.onSwipe,
    this.onDirectionChanged,
    required this.isDark,
    required this.accColor,
    this.entryDirection,
  });

  @override
  ConsumerState<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends ConsumerState<SwipeCard> with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  double _angle = 0;
  late AnimationController _motionController;
  OffsetSpringSimulation? _currentSimulation;
  VoidCallback? _onFlyOffComplete;
  bool _isFlyingOff = false;
  bool _hasTriggeredComplete = false;
  String? _flyOffDirection;
  String? _lastNotifiedDirection;

  @override
  void initState() {
    super.initState();
    if (widget.entryDirection != null) {
      double w = 1500;
      double h = 1500;
      try {
        final view = WidgetsBinding.instance.platformDispatcher.implicitView;
        if (view != null) {
          final s = view.physicalSize / view.devicePixelRatio;
          w = s.width;
          h = s.height;
        }
      } catch (_) {}
      
      switch (widget.entryDirection) {
        case 'Left':
          _dragOffset = Offset(-w * 1.2, 0);
          break;
        case 'Right':
          _dragOffset = Offset(w * 1.2, 0);
          break;
        case 'Up':
          _dragOffset = Offset(0, -h * 1.2);
          break;
        case 'Down':
          _dragOffset = Offset(0, h * 1.2);
          break;
      }
      _angle = _dragOffset.dx / 300 * (math.pi / 8);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _settleSpring();
      });
    }

    _motionController = AnimationController.unbounded(vsync: this);
    _motionController.addListener(() {
      if (_currentSimulation != null && mounted) {
        final elapsed = _motionController.lastElapsedDuration != null
            ? _motionController.lastElapsedDuration!.inMicroseconds / 1000000.0
            : 0.0;
        var newOffset = _currentSimulation!.dxOffset(elapsed);
        // DISC-1: settling toward rest (a released drag, or a re-entering
        // undone card flying back in from off-screen) target Offset.zero.
        // The underdamped house spring only satisfies SpringSimulation's
        // own sub-pixel isDone() tolerance after a very long tail relative
        // to how far it started -- for a normal small drag release that's
        // imperceptible, but the undo re-entry starts a full screen width
        // off-screen, so that tail could leave the card visibly parked
        // far from its resting position for an extended stretch. Snap the
        // last visually-imperceptible fraction instead of waiting on the
        // simulation to fully converge.
        if (!_isFlyingOff && newOffset.distance < 1.0) {
          newOffset = Offset.zero;
          _motionController.stop();
        }
        setState(() {
          _dragOffset = newOffset;
          _angle = _dragOffset.dx / 300 * (math.pi / 8);
        });
        _updateActiveDirection();
        _checkEarlyCompletion();
      }
    });
    _motionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerFlyOffComplete();
      }
    });
  }

  void _updateActiveDirection() {
    if (!widget.isInteractive) return;

    String? currentDir;
    if (_isFlyingOff) {
      currentDir = _flyOffDirection;
    } else {
      final dx = _dragOffset.dx;
      final dy = _dragOffset.dy;
      const threshold = 30.0;

      if (dx.abs() > threshold || dy.abs() > threshold) {
        if (dx.abs() > dy.abs()) {
          currentDir = dx > 0 ? 'Right' : 'Left';
        } else {
          currentDir = dy > 0 ? 'Down' : 'Up';
        }
      }
    }

    if (_lastNotifiedDirection != currentDir) {
      _lastNotifiedDirection = currentDir;
      widget.onDirectionChanged?.call(currentDir);
    }
  }

  void _checkEarlyCompletion() {
    if (!_isFlyingOff || _hasTriggeredComplete || !mounted) return;
    final size = MediaQuery.maybeOf(context)?.size;
    if (size != null) {
      if (_dragOffset.dx.abs() > size.width * 0.7 || _dragOffset.dy.abs() > size.height * 0.7) {
        _triggerFlyOffComplete();
      }
    }
  }

  void _triggerFlyOffComplete() {
    if (_isFlyingOff && !_hasTriggeredComplete) {
      _hasTriggeredComplete = true;
      _onFlyOffComplete?.call();
    }
  }

  @override
  void dispose() {
    if (_lastNotifiedDirection != null) {
      widget.onDirectionChanged?.call(null);
    }
    _motionController.dispose();
    super.dispose();
  }

  void _settleSpring({Offset velocity = Offset.zero}) {
    _isFlyingOff = false;
    _flyOffDirection = null;
    _hasTriggeredComplete = false;
    _onFlyOffComplete = null;

    final sim = OffsetSpringSimulation(
      startX: _dragOffset.dx,
      endX: 0.0,
      velocityX: velocity.dx,
      startY: _dragOffset.dy,
      endY: 0.0,
      velocityY: velocity.dy,
    );

    _motionController.stop();
    _currentSimulation = sim;
    _motionController.animateWith(sim);
    _updateActiveDirection();
  }

  void flyOff(String direction, VoidCallback onComplete, {Offset velocity = Offset.zero}) {
    if (_isFlyingOff) return;
    _isFlyingOff = true;
    _flyOffDirection = direction;
    _hasTriggeredComplete = false;
    _onFlyOffComplete = onComplete;

    final size = MediaQuery.of(context).size;
    Offset targetOffset;
    switch (direction) {
      case 'Left':
        targetOffset = Offset(-size.width * 1.5, _dragOffset.dy);
        break;
      case 'Right':
        targetOffset = Offset(size.width * 1.5, _dragOffset.dy);
        break;
      case 'Up':
        targetOffset = Offset(_dragOffset.dx, -size.height * 1.5);
        break;
      case 'Down':
        targetOffset = Offset(_dragOffset.dx, size.height * 1.5);
        break;
      default:
        targetOffset = Offset(-size.width * 1.5, _dragOffset.dy);
    }

    final effectiveVelocity = (velocity.dx.abs() < 10 && velocity.dy.abs() < 10)
        ? Offset(
            targetOffset.dx.clamp(-1200.0, 1200.0),
            targetOffset.dy.clamp(-1200.0, 1200.0),
          )
        : velocity;

    final sim = OffsetSpringSimulation(
      startX: _dragOffset.dx,
      endX: targetOffset.dx,
      velocityX: effectiveVelocity.dx,
      startY: _dragOffset.dy,
      endY: targetOffset.dy,
      velocityY: effectiveVelocity.dy,
    );

    _currentSimulation = sim;
    _motionController.stop();
    _motionController.animateWith(sim);
    _updateActiveDirection();
    _checkEarlyCompletion();
  }

  @override
  Widget build(BuildContext context) {
    final phColor = context.ambianceColors.ph;
    final borderColor = context.ambianceColors.lineRgba;

    const double commitThreshold = 100.0;
    final bool isHorizontalDominant = _dragOffset.dx.abs() > _dragOffset.dy.abs();
    final double dragDistance = isHorizontalDominant ? _dragOffset.dx.abs() : _dragOffset.dy.abs();
    double hintOpacity = (dragDistance / commitThreshold).clamp(0.0, 1.0);

    String? activeDirection;
    Color? activeColor;
    Alignment activeAlignment = Alignment.center;

    if (_isFlyingOff && _flyOffDirection != null) {
      activeDirection = _flyOffDirection;
      hintOpacity = 1.0;
      switch (activeDirection) {
        case 'Left':
          activeColor = AppStatusColors.skip;
          activeAlignment = Alignment.centerLeft;
          break;
        case 'Right':
          activeColor = AppStatusColors.save;
          activeAlignment = Alignment.centerRight;
          break;
        case 'Up':
          activeColor = AppStatusColors.watched;
          activeAlignment = Alignment.topCenter;
          break;
        case 'Down':
          activeColor = AppStatusColors.watchlist;
          activeAlignment = Alignment.bottomCenter;
          break;
      }
    } else if (hintOpacity > 0) {
      if (isHorizontalDominant) {
        if (_dragOffset.dx < 0) {
          activeDirection = 'Left';
          activeColor = AppStatusColors.skip;
          activeAlignment = Alignment.centerLeft;
        } else if (_dragOffset.dx > 0) {
          activeDirection = 'Right';
          activeColor = AppStatusColors.save; // Saved / Maybe
          activeAlignment = Alignment.centerRight;
        }
      } else {
        if (_dragOffset.dy < 0) {
          activeDirection = 'Up';
          activeColor = AppStatusColors.watched;
          activeAlignment = Alignment.topCenter;
        } else if (_dragOffset.dy > 0) {
          activeDirection = 'Down';
          activeColor = AppStatusColors.watchlist;
          activeAlignment = Alignment.bottomCenter;
        }
      }
    }

    Widget card = Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: phColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          widget.isDark
              ? const BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.6),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                  spreadRadius: -12,
                )
              : const BoxShadow(
                  color: Color.fromRGBO(80, 55, 30, 0.12),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                  spreadRadius: -6,
                ),
          BoxShadow(
            color: context.ambianceColors.surfaceHighlight,
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaImage(
            item: widget.item,
            fit: BoxFit.cover,
            showFallbackTitle: false,
          ),
          if (widget.item.releaseDate != null && widget.item.releaseDate!.isAfter(DateTime.now()))
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.ambianceColors.danger,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'UPCOMING • ${widget.item.releaseDate!.year}',
                  style: AppThemes.safeGeist(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          
          // Soft Edge Glow / Tint overlay
          if (hintOpacity > 0 && activeColor != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.6 * hintOpacity),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35 * hintOpacity),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: RadialGradient(
                        center: activeAlignment,
                        radius: 1.2,
                        colors: [
                          activeColor.withValues(alpha: 0.3 * hintOpacity),
                          activeColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Proportional Edge hints (Icon + Label)
          if (hintOpacity > 0 && activeDirection == 'Up' && activeColor != null)
            Positioned(
              top: 14, left: 0, right: 0,
              child: Opacity(
                opacity: hintOpacity,
                child: Column(
                  children: [
                    Icon(Icons.check, color: activeColor),
                    Text('Watched', style: AppThemes.safeGeist(fontSize: 10, fontWeight: FontWeight.w600, color: activeColor, backgroundColor: Colors.black54)),
                  ],
                ),
              ),
            ),
          if (hintOpacity > 0 && activeDirection == 'Down' && activeColor != null)
            Positioned(
              bottom: 82, left: 0, right: 0,
              child: Opacity(
                opacity: hintOpacity,
                child: Column(
                  children: [
                    Text('Watchlist', style: AppThemes.safeGeist(fontSize: 10, fontWeight: FontWeight.w600, color: activeColor, backgroundColor: Colors.black54)),
                    Icon(Icons.bookmark, color: activeColor),
                  ],
                ),
              ),
            ),
          if (hintOpacity > 0 && activeDirection == 'Left' && activeColor != null)
            Positioned(
              top: 250, left: 12,
              child: Opacity(
                opacity: hintOpacity,
                child: Row(
                  children: [
                    Icon(Icons.close, color: activeColor),
                    const SizedBox(width: 4),
                    Text('Skip', style: AppThemes.safeGeist(fontSize: 10, fontWeight: FontWeight.w600, color: activeColor, backgroundColor: Colors.black54)),
                  ],
                ),
              ),
            ),
          if (hintOpacity > 0 && activeDirection == 'Right' && activeColor != null)
            Positioned(
              top: 250, right: 12,
              child: Opacity(
                opacity: hintOpacity,
                child: Row(
                  children: [
                    Text('Saved', style: AppThemes.safeGeist(fontSize: 10, fontWeight: FontWeight.w600, color: activeColor, backgroundColor: Colors.black54)),
                    const SizedBox(width: 4),
                    Icon(Icons.star, color: activeColor),
                  ],
                ),
              ),
            ),

          // Title Block
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, context.ambianceColors.scrim],
                )
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: widget.accColor, borderRadius: BorderRadius.circular(5)),
                        child: Text('★ ${widget.item.rating}', style: AppThemes.safeGeist(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Builder(builder: (context) {
                          final yearStr = widget.item.releaseDate != null ? widget.item.releaseDate!.year.toString() : '';
                          final genreStr = widget.item.genres.isNotEmpty ? widget.item.genres.take(2).join(', ') : '';
                          final metaText = [if (yearStr.isNotEmpty) yearStr, if (genreStr.isNotEmpty) genreStr].join(' · ');
                          return Text(
                            metaText.isNotEmpty ? metaText : 'Discover',
                            overflow: TextOverflow.ellipsis,
                            style: AppThemes.safeGeist(fontSize: 11, fontWeight: FontWeight.w500, color: const Color.fromRGBO(255, 255, 255, 0.8)),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.item.title, style: GoogleFonts.bodoniModa(fontSize: 27, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.white, height: 1.02)),
                  const SizedBox(height: 5),
                  Text(widget.item.overview, style: AppThemes.safeGeist(fontSize: 12, height: 1.45, color: const Color.fromRGBO(255, 255, 255, 0.72)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text('Tap for full details ↗', style: AppThemes.safeGeist(fontSize: 11, fontWeight: FontWeight.w500, color: widget.accColor)),
                ],
              ),
            ),
          )
        ],
      ),
    );

    if (!widget.isInteractive) return card;

    return OpenContainer(
      transitionDuration: AppPhysics.houseSpringDuration,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: context.ambianceColors.base,
      middleColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      closedBuilder: (context, openContainer) {
        return PressableScale(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openContainer,
            onLongPress: () => showQuickStatusSheet(context, ref, widget.item),
            onPanUpdate: (details) {
              if (_isFlyingOff) return;
              if (_motionController.isAnimating) {
                _motionController.stop();
              }
              setState(() {
                _dragOffset += details.delta;
                _angle = _dragOffset.dx / 300 * (math.pi / 8);
              });
            },
            onPanEnd: (details) {
              if (_isFlyingOff) return;
              final velocity = details.velocity.pixelsPerSecond;
              final isHorizontalDominant = _dragOffset.dx.abs() > _dragOffset.dy.abs();

              if (isHorizontalDominant) {
                if (_dragOffset.dx > 100 || velocity.dx > 500) {
                  flyOff('Right', () => widget.onSwipe('Right'), velocity: velocity);
                } else if (_dragOffset.dx < -100 || velocity.dx < -500) {
                  flyOff('Left', () => widget.onSwipe('Left'), velocity: velocity);
                } else {
                  _settleSpring(velocity: velocity);
                }
              } else {
                if (_dragOffset.dy > 100 || velocity.dy > 500) {
                  flyOff('Down', () => widget.onSwipe('Down'), velocity: velocity);
                } else if (_dragOffset.dy < -100 || velocity.dy < -500) {
                  flyOff('Up', () => widget.onSwipe('Up'), velocity: velocity);
                } else {
                  _settleSpring(velocity: velocity);
                }
              }
            },
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(angle: _angle, child: card),
            ),
          ),
        );
      },
      openBuilder: (context, _) => DetailScreen(
        id: widget.item.prefixedId,
        initialItem: widget.item,
      ),
    );
  }
}
