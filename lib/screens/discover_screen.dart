import '../constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'dart:math' as math;
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/media_item.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/pressable_scale.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_screen.dart';

import '../widgets/drag_to_dismiss_sheet.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  List<MediaItem> _pool = [];
  bool _loading = true;
  Object? _error;
  bool _showLegend = true;
  bool _isSwiping = false;
  String? _activeSwipeDirection;
  final Map<String, GlobalKey<_SwipeCardState>> _cardKeys = {};

  @override
  void initState() {
    super.initState();
    _loadPool();
  }

  Future<void> _loadPool() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(movieRepositoryProvider);
      final mediaState = ref.read(mediaProvider);

      final excludedIds = <String>{
        ...mediaState.watchlist.keys,
        ...mediaState.maybeList.keys,
        ...mediaState.watchedList.keys,
        ...mediaState.watchingList.keys,
      };

      bool isExcluded(MediaItem item) {
        final cleanId = item.id.replaceFirst(RegExp(r'^(movie_|tv_)'), '');
        return excludedIds.contains(item.id) ||
            excludedIds.contains(item.prefixedId) ||
            excludedIds.contains(cleanId);
      }

      final navState = ref.read(navigationProvider);
      final isMovies = navState.activeMediaType == MediaTypeToggle.movies;

      final List<MediaItem> rawList = [];

      if (isMovies) {
        final t1 = await repo.getTrendingMovies(page: 1);
        final t2 = await repo.getTrendingMovies(page: 2);
        final p1 = await repo.getPopularMovies(page: 1);
        final p2 = await repo.getPopularMovies(page: 2);
        rawList.addAll([...t1, ...t2, ...p1, ...p2]);
      } else {
        final t1 = await repo.getTrendingTvShows(page: 1);
        final t2 = await repo.getTrendingTvShows(page: 2);
        final top1 = await repo.getTopRatedTvShows(page: 1);
        final top2 = await repo.getTopRatedTvShows(page: 2);
        rawList.addAll([...t1, ...t2, ...top1, ...top2]);
      }

      if (mounted) {
        setState(() {
          final seen = <String>{};
          final merged = rawList
              .where((item) => !isExcluded(item) && seen.add(item.id))
              .toList();
          _pool = merged;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
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
      // Skip
    } else if (direction == 'Right') {
      notifier.addToMaybeList(item);
    } else if (direction == 'Down') {
      notifier.addToWatchlist(item);
    } else if (direction == 'Up') {
      notifier.addToWatchedList(item);
    }

    if (mounted) {
      setState(() {
        _activeSwipeDirection = null;
        if (_pool.isNotEmpty) {
          final removed = _pool.removeAt(0);
          _cardKeys.remove(removed.id);
        }
      });
    }
  }

  void _triggerSwipe(String direction) {
    if (_pool.isEmpty || _isSwiping) return;
    _isSwiping = true;
    setState(() {
      _activeSwipeDirection = direction;
    });
    final topItem = _pool.first;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final subColor = isDark ? const Color.fromRGBO(239, 230, 216, 0.55) : const Color.fromRGBO(44, 32, 22, 0.55);
    final accColor = isDark ? const Color(0xFFCBA86A) : const Color(0xFFB0512B);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final message = _error.toString().replaceAll('Exception: ', '');
      return FullScreenErrorWidget(
        message: message.isNotEmpty
            ? message
            : 'Failed to load recommendations. Please check your connection.',
        onRetry: _loadPool,
      );
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;

    return Stack(
      children: [
        Column(
          children: [
            // Top bar: toggle + legend key
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isLarge ? 24 : 18, isLarge ? 0 : 2, isLarge ? 24 : 18, 10),
              child: Row(
                mainAxisAlignment: isLarge
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!isLarge)
                    Consumer(
                      builder: (context, ref, child) {
                        final navState = ref.watch(navigationProvider);
                        return SegmentedMediaTypeToggle(
                          activeType: navState.activeMediaType,
                          onChanged: (type) => ref
                              .read(navigationProvider.notifier)
                              .setMediaType(type),
                          isDark: isDark,
                          height: 28,
                          segmentWidth: 58,
                          fontSize: 11.5,
                        );
                      },
                    ),
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
                            color: isDark ? const Color(0xFF1C1510) : const Color(0xFFDCCDB2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? const Color.fromRGBO(201, 168, 106, 0.1) : const Color.fromRGBO(160, 74, 42, 0.1)),
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
                            color: isDark ? const Color(0xFF241A12) : const Color(0xFFE3D5BD),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? const Color.fromRGBO(201, 168, 106, 0.14) : const Color.fromRGBO(160, 74, 42, 0.14)),
                          ),
                          child: Opacity(opacity: isDark ? 0.7 : 0.8),
                        ),
                      ),
                    ),
                    // Active cards
                    if (_pool.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.movie_filter_outlined,
                                  size: 64, color: subColor),
                              const SizedBox(height: 16),
                              Text(
                                'No titles in recommendations',
                                style: AppThemes.safeGeist(
                                    color: isDark
                                        ? AppColors.srInk
                                        : AppColors.rrInk,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You\'ve gone through all available recommendations in this stack.',
                                textAlign: TextAlign.center,
                                style: AppThemes.safeGeist(
                                    color: subColor, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _loadPool,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reload deck'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._pool.reversed.map((item) {
                        final isTop = item.id == _pool.first.id;
                        return SwipeCard(
                          key: _getKeyFor(item.id),
                          item: item,
                          isInteractive: isTop,
                          onSwipe: (dir) => _onSwipe(item, dir),
                          onDirectionChanged: isTop ? _onDirectionChanged : null,
                          isDark: isDark,
                          accColor: accColor,
                        );
                      }),
                  ],
                ),
              ),
            ),
            // Action buttons row
            Padding(
              padding: EdgeInsets.fromLTRB(0, 14.0, 0, 14.0 + MediaQuery.of(context).padding.bottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    color: isDark ? const Color(0xFF9A9088) : const Color(0xFF8A8072),
                    borderColor: isDark ? const Color.fromRGBO(154, 144, 136, 0.5) : const Color.fromRGBO(138, 128, 114, 0.5),
                    direction: 'Left',
                    onTap: () => _triggerSwipe('Left'),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  _buildActionButton(
                    icon: Icons.star_border,
                    activeIcon: Icons.star,
                    color: isDark ? const Color(0xFFD69784) : const Color(0xFFA76A50),
                    borderColor: isDark ? const Color.fromRGBO(214, 151, 132, 0.55) : const Color.fromRGBO(167, 106, 80, 0.55),
                    direction: 'Right',
                    onTap: () => _triggerSwipe('Right'),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  _buildWatchlistActionButton(isDark: isDark, accColor: accColor),
                  const SizedBox(width: 14),
                  _buildActionButton(
                    icon: Icons.check,
                    color: isDark ? const Color(0xFF7E9BB5) : const Color(0xFF566F86),
                    borderColor: isDark ? const Color.fromRGBO(126, 155, 181, 0.55) : const Color.fromRGBO(86, 111, 134, 0.55),
                    direction: 'Up',
                    onTap: () => _triggerSwipe('Up'),
                    isDark: isDark,
                  ),
                ],
              ),
            )
          ],
        ),
        _buildLegendOverlay(isDark, accColor),
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
  }) {
    final isActive = _activeSwipeDirection == direction;
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
  }) {
    final isActive = _activeSwipeDirection == 'Down';
    final glowColor = isDark ? accColor : const Color(0xFFB0512B);

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
          decoration: isDark
              ? BoxDecoration(
                  color: accColor,
                  shape: BoxShape.circle,
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
                )
              : BoxDecoration(
                  gradient: AppColors.rrPrimaryGradient,
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: const Color(0xFFB0512B), width: 2)
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ]
                      : null,
                ),
          child: Icon(
            isActive ? Icons.bookmark : Icons.bookmark_border,
            color: isDark ? const Color(0xFF1A140C) : Colors.white,
            size: isActive ? 26 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendOverlay(bool isDark, Color accColor) {
    final titleColor = isDark ? const Color(0xFFEFE6D8) : const Color(0xFF2C2016);
    final subColor = isDark ? const Color.fromRGBO(239, 230, 216, 0.55) : const Color.fromRGBO(44, 32, 22, 0.55);
    final borderColor = isDark ? const Color.fromRGBO(201, 168, 106, 0.25) : const Color.fromRGBO(160, 74, 42, 0.25);
    final backdropColor = isDark ? const Color.fromRGBO(6, 4, 3, 0.72) : const Color.fromRGBO(44, 32, 22, 0.45);
    final sheetBgColors = isDark
        ? const [Color(0xFF1C1510), Color(0xFF120D0A)]
        : const [Color(0xFFF6EFE3), Color(0xFFE7DDC9)];
    final innerShadowColor = isDark ? const Color.fromRGBO(255, 255, 255, 0.08) : const Color.fromRGBO(255, 255, 255, 0.6);
    final btnTextColor = isDark ? const Color(0xFF1A140C) : Colors.white;

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
                          subtitle: 'Session only, won\'t reappear tonight — not permanent',
                          color: isDark ? const Color(0xFFB3A99F) : const Color(0xFF8A8072),
                          bgColor: isDark ? const Color.fromRGBO(154, 144, 136, 0.16) : const Color.fromRGBO(138, 128, 114, 0.16),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          isDark: isDark,
                          icon: Icons.arrow_forward,
                          title: 'Swipe right — Save for later',
                          subtitle: 'A "maybe" bookmark → lands in your Maybe pile',
                          color: isDark ? const Color(0xFFE0A894) : const Color(0xFFA76A50),
                          bgColor: isDark ? const Color.fromRGBO(214, 151, 132, 0.16) : const Color.fromRGBO(167, 106, 80, 0.16),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          isDark: isDark,
                          icon: Icons.arrow_downward,
                          title: 'Swipe down — Add to watchlist',
                          subtitle: 'A committed pick you intend to watch',
                          color: isDark ? const Color(0xFFC9A86A) : const Color(0xFFB0512B),
                          bgColor: isDark ? const Color.fromRGBO(201, 168, 106, 0.16) : const Color.fromRGBO(176, 81, 43, 0.16),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          isDark: isDark,
                          icon: Icons.arrow_upward,
                          title: 'Swipe up — Already watched',
                          subtitle: 'Logs to Watched history',
                          color: isDark ? const Color(0xFF8FAEC4) : const Color(0xFF566F86),
                          bgColor: isDark ? const Color.fromRGBO(126, 155, 181, 0.16) : const Color.fromRGBO(86, 111, 134, 0.16),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          isDark: isDark,
                          icon: Icons.touch_app,
                          title: 'Tap — Open full details',
                          subtitle: 'The complete Movie / TV detail view',
                          color: isDark ? const Color(0xFFEFE6D8) : const Color(0xFF2C2016),
                          bgColor: isDark ? const Color.fromRGBO(239, 230, 216, 0.08) : const Color.fromRGBO(44, 32, 22, 0.08),
                        ),
                        const SizedBox(height: 22),
                        PressableScale(
                          onTap: () => setState(() => _showLegend = false),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: AppColors.primaryButtonDecoration(
                              isDark: isDark,
                              borderRadius: 12,
                            ),
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
    final titleColor = isDark ? const Color(0xFFEFE6D8) : const Color(0xFF2C2016);
    final subtitleColor = isDark ? const Color.fromRGBO(239, 230, 216, 0.5) : const Color.fromRGBO(44, 32, 22, 0.55);

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

class SwipeCard extends StatefulWidget {
  final MediaItem item;
  final bool isInteractive;
  final Function(String) onSwipe;
  final ValueChanged<String?>? onDirectionChanged;
  final bool isDark;
  final Color accColor;

  const SwipeCard({
    super.key,
    required this.item,
    required this.isInteractive,
    required this.onSwipe,
    this.onDirectionChanged,
    required this.isDark,
    required this.accColor,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
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
    _motionController = AnimationController.unbounded(vsync: this);
    _motionController.addListener(() {
      if (_currentSimulation != null && mounted) {
        final elapsed = _motionController.lastElapsedDuration != null
            ? _motionController.lastElapsedDuration!.inMicroseconds / 1000000.0
            : 0.0;
        final newOffset = _currentSimulation!.dxOffset(elapsed);
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
    final phColor = widget.isDark ? const Color.fromRGBO(239, 230, 216, 0.09) : const Color.fromRGBO(44, 32, 22, 0.09);
    final borderColor = widget.isDark ? const Color.fromRGBO(201, 168, 106, 0.22) : const Color.fromRGBO(160, 74, 42, 0.24);

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
            color: widget.isDark
                ? const Color.fromRGBO(255, 255, 255, 0.06)
                : const Color.fromRGBO(255, 255, 255, 0.5),
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
          
          // Edge hints
          if (_dragOffset.dy < -20)
            Positioned(top: 12, left: 0, right: 0, child: Column(children: [Icon(Icons.check, color: widget.isDark ? const Color(0xFF7E9BB5) : const Color(0xFF566F86)), Text('Watched', style: AppThemes.safeGeist(fontSize: 9, fontWeight: FontWeight.w600, color: widget.isDark ? const Color(0xFF7E9BB5) : const Color(0xFF566F86), backgroundColor: Colors.black54))])),
          if (_dragOffset.dy > 20)
            Positioned(bottom: 80, left: 0, right: 0, child: Column(children: [Text('Watchlist', style: AppThemes.safeGeist(fontSize: 9, fontWeight: FontWeight.w600, color: widget.accColor, backgroundColor: Colors.black54)), Icon(Icons.bookmark, color: widget.accColor)])),
          if (_dragOffset.dx < -20)
            Positioned(top: 250, left: 10, child: Row(children: [Icon(Icons.close, color: widget.isDark ? const Color(0xFF9A9088) : const Color(0xFF8A8072)), Text('Skip', style: AppThemes.safeGeist(fontSize: 9, fontWeight: FontWeight.w600, color: widget.isDark ? const Color(0xFF9A9088) : const Color(0xFF8A8072), backgroundColor: Colors.black54))])),
          if (_dragOffset.dx > 20)
            Positioned(top: 250, right: 10, child: Row(children: [Text('Maybe', style: AppThemes.safeGeist(fontSize: 9, fontWeight: FontWeight.w600, color: widget.isDark ? const Color(0xFFD69784) : const Color(0xFFA76A50), backgroundColor: Colors.black54)), Icon(Icons.star, color: widget.isDark ? const Color(0xFFD69784) : const Color(0xFFA76A50))])),

          // Title Block
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, widget.isDark ? const Color.fromRGBO(0, 0, 0, 0.82) : const Color.fromRGBO(50, 30, 15, 0.78)],
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
                        child: Text('★ ${widget.item.rating}', style: AppThemes.safeGeist(fontSize: 11, fontWeight: FontWeight.w600, color: widget.isDark ? const Color(0xFF1A140C) : Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Text('2024 · Sci-fi', style: AppThemes.safeGeist(fontSize: 11, fontWeight: FontWeight.w500, color: const Color.fromRGBO(255, 255, 255, 0.8))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.item.title, style: GoogleFonts.bodoniModa(fontSize: 27, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.white, height: 1.02)),
                  const SizedBox(height: 5),
                  Text(widget.item.overview, style: AppThemes.safeGeist(fontSize: 12, height: 1.45, color: const Color.fromRGBO(255, 255, 255, 0.72)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text('Tap for full details ↗', style: AppThemes.safeGeist(fontSize: 11, fontWeight: FontWeight.w500, color: widget.isDark ? widget.accColor : const Color(0xFFF0C9A0))),
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
      openColor: widget.isDark ? AppColors.srBase : AppColors.rrBase,
      middleColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      closedBuilder: (context, openContainer) {
        return PressableScale(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openContainer,
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
              if (_dragOffset.dx > 100 || velocity.dx > 500) {
                flyOff('Right', () => widget.onSwipe('Right'), velocity: velocity);
              } else if (_dragOffset.dx < -100 || velocity.dx < -500) {
                flyOff('Left', () => widget.onSwipe('Left'), velocity: velocity);
              } else if (_dragOffset.dy > 100 || velocity.dy > 500) {
                flyOff('Down', () => widget.onSwipe('Down'), velocity: velocity);
              } else if (_dragOffset.dy < -100 || velocity.dy < -500) {
                flyOff('Up', () => widget.onSwipe('Up'), velocity: velocity);
              } else {
                _settleSpring(velocity: velocity);
              }
            },
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(angle: _angle, child: card),
            ),
          ),
        );
      },
      openBuilder: (context, _) => DetailScreen(id: widget.item.prefixedId),
    );
  }
}
