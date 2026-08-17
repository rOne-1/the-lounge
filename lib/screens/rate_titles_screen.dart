import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/lounge_rating_sheet.dart';
import '../widgets/media_image.dart';
import '../widgets/pressable_scale.dart';

/// PERS-RATE-2: all watched titles that have no overall personal rating yet.
List<MediaItem> unratedWatchedTitles(MediaState state) {
  return state.watchedList.values
      .where((item) => findPrimaryWatchRecord(state.watchHistory, item.id, null) == null)
      .toList();
}

/// PERS-RATE-2: dedicated batch rating swipe tool. Snapshots the current
/// unrated-watched queue at open time (a "session" you work through), rather
/// than reactively re-sorting as ratings land -- rated titles simply drop
/// off the front of the local queue, kept in sync with the provider.
class RateTitlesScreen extends ConsumerStatefulWidget {
  const RateTitlesScreen({super.key});

  @override
  ConsumerState<RateTitlesScreen> createState() => _RateTitlesScreenState();
}

class _RateTitlesScreenState extends ConsumerState<RateTitlesScreen> {
  late List<MediaItem> _queue;

  @override
  void initState() {
    super.initState();
    _queue = unratedWatchedTitles(ref.read(mediaProvider));
  }

  void _rate(PersonalRating rating) {
    if (_queue.isEmpty) return;
    final item = _queue.first;
    ref.read(mediaProvider.notifier).addWatchRecord(
          item.id,
          WatchRecord(rating: rating, date: DateTime.now(), isFirstWatch: true),
        );
    setState(() => _queue.removeAt(0));
  }

  void _skip() {
    if (_queue.length <= 1) return;
    setState(() => _queue.add(_queue.removeAt(0)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    return Scaffold(
      backgroundColor: colors.base,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.ink),
        title: Text(
          'Rate Titles',
          style: AppThemes.safeGeist(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: _queue.isEmpty
            ? _EmptyState(onDone: () => Navigator.of(context).pop())
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      '${_queue.length} title${_queue.length == 1 ? '' : 's'} left to rate',
                      style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _RateTitleCard(
                        key: ValueKey(_queue.first.id),
                        item: _queue.first,
                        onSkip: _skip,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RatingTierGrid(onSelect: _rate),
                    const SizedBox(height: 12),
                    PressableScale(
                      onTap: _skip,
                      child: Container(
                        height: 44,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.lineRgba),
                        ),
                        child: Text(
                          'Skip',
                          style: AppThemes.safeGeist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.sub,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// A single swipeable card: horizontal drag (or the Skip button) advances
/// the queue without rating; a spring snap-back (House Spring preset)
/// returns the card to center if the drag doesn't clear the threshold.
class _RateTitleCard extends StatefulWidget {
  final MediaItem item;
  final VoidCallback onSkip;

  const _RateTitleCard({super.key, required this.item, required this.onSkip});

  @override
  State<_RateTitleCard> createState() => _RateTitleCardState();
}

class _RateTitleCardState extends State<_RateTitleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Offset>? _animation;
  Offset _dragOffset = Offset.zero;
  static const double _dismissThreshold = 120.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppPhysics.houseSpringDuration,
    )..addListener(() {
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

  void _flyOff(double direction) async {
    final screenWidth = MediaQuery.of(context).size.width;
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(direction * screenWidth, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.duration = const Duration(milliseconds: 250);
    await _controller.forward(from: 0.0);
    _controller.duration = AppPhysics.houseSpringDuration;
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final rotation = (_dragOffset.dx / 800).clamp(-0.25, 0.25);
    final yearStr = widget.item.releaseOrAirDate?.year != null
        ? '${widget.item.releaseOrAirDate!.year}'
        : null;

    return GestureDetector(
      onPanUpdate: (details) {
        if (_controller.isAnimating) return;
        setState(() => _dragOffset += details.delta);
      },
      onPanEnd: (details) {
        if (_dragOffset.dx.abs() > _dismissThreshold ||
            details.velocity.pixelsPerSecond.dx.abs() > 600) {
          _flyOff(_dragOffset.dx > 0 ? 1 : -1);
        } else {
          _snapBack();
        }
      },
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
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (yearStr != null) yearStr,
                            if (widget.item.genres.isNotEmpty)
                              widget.item.genres.take(3).join(' · '),
                          ].join(' · '),
                          style: AppThemes.safeGeist(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

class _RatingTierGrid extends StatelessWidget {
  final ValueChanged<PersonalRating> onSelect;

  const _RatingTierGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: PersonalRating.values.map((rating) {
        final tierColor = AppRatingColors.of(rating);
        return PressableScale(
          onTap: () => onSelect(rating),
          child: Container(
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tierColor.withValues(alpha: 0.6)),
            ),
            alignment: Alignment.center,
            child: Text(
              rating.label,
              style: AppThemes.safeGeist(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.isDark ? Colors.white : tierColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onDone;

  const _EmptyState({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_bar_rounded, size: 56, color: colors.acc),
            const SizedBox(height: 20),
            Text(
              "You're all caught up!",
              style: AppThemes.safeGeist(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'All watched titles are rated.',
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
