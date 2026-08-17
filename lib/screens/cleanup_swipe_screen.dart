import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/media_image.dart';
import '../widgets/pressable_scale.dart';

/// PERS-SORT-1: the pile size that triggers the (non-blocking, dismissible)
/// cleanup prompt.
const int kPileCleanupThreshold = 50;

/// PERS-SORT-1: the 50-item periodic cleanup swipe tool. Works through the
/// Saved pile one title at a time: swipe/tap right promotes to Watchlist,
/// left keeps it in Saved (just advances), down releases it (Dropped).
/// Never forced -- the caller (Your Space's Saved tab banner) is itself
/// dismissible, and this screen can always be backed out of mid-session
/// with whatever's left simply remaining in Saved untouched.
class CleanupSwipeScreen extends ConsumerStatefulWidget {
  const CleanupSwipeScreen({super.key});

  @override
  ConsumerState<CleanupSwipeScreen> createState() => _CleanupSwipeScreenState();
}

class _CleanupSwipeScreenState extends ConsumerState<CleanupSwipeScreen> {
  late List<MediaItem> _queue;
  late int _startCount;

  @override
  void initState() {
    super.initState();
    // PERS-SORT-1: scoped to the active Movies/TV toggle, mirroring every
    // Piles screen -- previously this pulled the whole Saved pile regardless
    // of the toggle.
    final activeType = ref.read(navigationProvider).activeMediaType == MediaTypeToggle.movies
        ? MediaType.movie
        : MediaType.tv;
    _queue = ref
        .read(mediaProvider)
        .maybeList
        .values
        .where((item) => item.type == activeType)
        .toList();
    _startCount = _queue.length;
  }

  void _promote() {
    if (_queue.isEmpty) return;
    final item = _queue.first;
    ref.read(mediaProvider.notifier).addToWatchlist(item);
    setState(() => _queue.removeAt(0));
  }

  void _keep() {
    if (_queue.isEmpty) return;
    setState(() => _queue.removeAt(0));
  }

  void _drop() {
    if (_queue.isEmpty) return;
    final item = _queue.first;
    ref.read(mediaProvider.notifier).addToDroppedList(item);
    setState(() => _queue.removeAt(0));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final processed = _startCount - _queue.length;

    return Scaffold(
      backgroundColor: colors.base,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.ink),
        title: Text(
          'Clean Up Saved',
          style: AppThemes.safeGeist(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: _queue.isEmpty
            ? _EmptyState(processed: processed, onDone: () => Navigator.of(context).pop())
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      '$processed of $_startCount reviewed',
                      style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _CleanupCard(
                        key: ValueKey(_queue.first.id),
                        item: _queue.first,
                        onPromote: _promote,
                        onKeep: _keep,
                        onDrop: _drop,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.pause_circle_outline_rounded,
                            label: 'Keep',
                            color: colors.sub,
                            onTap: _keep,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.remove_circle_outline_rounded,
                            label: 'Drop',
                            color: AppStatusColors.dropped,
                            onTap: _drop,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.bookmark_outline_rounded,
                            label: 'Promote',
                            color: AppStatusColors.watchlist,
                            onTap: _promote,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: colors.card2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppThemes.safeGeist(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A swipeable card: horizontal drag right/left promotes/keeps, drag down
/// drops -- direction resolved by whichever axis moved further at release.
class _CleanupCard extends StatefulWidget {
  final MediaItem item;
  final VoidCallback onPromote;
  final VoidCallback onKeep;
  final VoidCallback onDrop;

  const _CleanupCard({
    super.key,
    required this.item,
    required this.onPromote,
    required this.onKeep,
    required this.onDrop,
  });

  @override
  State<_CleanupCard> createState() => _CleanupCardState();
}

class _CleanupCardState extends State<_CleanupCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Offset>? _animation;
  Offset _dragOffset = Offset.zero;
  static const double _dismissThreshold = 110.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppPhysics.houseSpringDuration)
      ..addListener(() {
        setState(() => _dragOffset = _animation!.value);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snapBack() {
    _animation = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppPhysics.houseSpringCurve),
    );
    _controller.forward(from: 0.0);
  }

  Future<void> _flyOff(Offset direction, VoidCallback onComplete) async {
    final screenSize = MediaQuery.of(context).size;
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(direction.dx * screenSize.width, direction.dy * screenSize.height),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.duration = const Duration(milliseconds: 250);
    await _controller.forward(from: 0.0);
    _controller.duration = AppPhysics.houseSpringDuration;
    onComplete();
  }

  void _resolveDrag() {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    final horizontalDominant = dx.abs() >= dy.abs();

    if (horizontalDominant && dx.abs() > _dismissThreshold) {
      _flyOff(Offset(dx > 0 ? 1 : -1, 0), dx > 0 ? widget.onPromote : widget.onKeep);
    } else if (!horizontalDominant && dy > _dismissThreshold) {
      _flyOff(const Offset(0, 1), widget.onDrop);
    } else {
      _snapBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final rotation = (_dragOffset.dx / 800).clamp(-0.25, 0.25);
    final yearStr = widget.item.releaseOrAirDate?.year != null
        ? '${widget.item.releaseOrAirDate!.year}'
        : null;

    // Directional tint hint as the user drags, so the outcome is legible
    // before release: green-ish toward Watchlist, red toward Drop.
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    Color? tint;
    double tintOpacity = 0;
    if (dx.abs() >= dy.abs() && dx.abs() > 20) {
      tint = dx > 0 ? AppStatusColors.watchlist : colors.sub;
      tintOpacity = (dx.abs() / 200).clamp(0.0, 0.35);
    } else if (dy > 20) {
      tint = AppStatusColors.dropped;
      tintOpacity = (dy / 200).clamp(0.0, 0.35);
    }

    return GestureDetector(
      onPanUpdate: (details) {
        if (_controller.isAnimating) return;
        setState(() => _dragOffset += details.delta);
      },
      onPanEnd: (_) => _resolveDrag(),
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.lineRgba),
              boxShadow: const [
                BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.35), blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaImage(item: widget.item, fit: BoxFit.cover, showFallbackTitle: false),
                if (tint != null)
                  Container(color: tint.withValues(alpha: tintOpacity)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.85)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: AppThemes.safeGeist(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (yearStr != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            yearStr,
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ],
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

class _EmptyState extends StatelessWidget {
  final int processed;
  final VoidCallback onDone;

  const _EmptyState({required this.processed, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rounded, size: 56, color: colors.acc),
            const SizedBox(height: 20),
            Text(
              'All cleaned up!',
              style: AppThemes.safeGeist(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You reviewed $processed title${processed == 1 ? '' : 's'}.',
              style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PressableScale(
              onTap: onDone,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: colors.acc,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Done',
                  style: AppThemes.safeGeist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
