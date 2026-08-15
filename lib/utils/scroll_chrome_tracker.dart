import 'package:flutter/widgets.dart';

/// Tracks scroll direction with hysteresis to decide when a piece of fixed
/// chrome (top bar, search header, ...) should collapse out of view vs. be
/// revealed again (E1/TF-4/TF-9).
///
/// Deliberately threshold + snap based -- chrome flips to hidden/visible as
/// a single state change once enough cumulative scroll passes
/// [collapseThreshold] in one direction, for the caller to animate with a
/// houseSpring transition -- rather than a continuous per-pixel drag-follow.
/// That matches AppPhysics' existing discrete-state motion language (SP-2)
/// instead of a stock SliverAppBar snap.
class ScrollChromeTracker {
  ScrollChromeTracker({this.collapseThreshold = 24.0});

  final double collapseThreshold;

  double _accumulator = 0.0;
  double? _lastOffset;

  /// Feeds a bubbled [ScrollNotification] in. Returns the chrome's new
  /// visibility (`true` = show, `false` = hide) if this notification should
  /// change it, or `null` if nothing should change yet.
  bool? handle(ScrollNotification notification) {
    final metrics = notification.metrics;
    // Chrome should only react to the primary page scroll -- ignore nested
    // horizontal carousels (e.g. Home's MediaRail rows) bubbling their own
    // ScrollNotifications up through the same NotificationListener, which
    // would otherwise contaminate the collapse/expand signal with
    // horizontal-swipe noise unrelated to the user scrolling the page.
    if (metrics.axis != Axis.vertical) return null;
    if (!metrics.hasContentDimensions || metrics.maxScrollExtent <= 0) {
      return null;
    }

    // Seed the baseline at the start of a gesture -- a single drag/fling
    // can arrive as one ScrollUpdateNotification spanning the whole
    // movement (no intermediate steps), so without this the first update's
    // "previous" offset would fall back to its own current offset and
    // compute a false zero delta.
    if (notification is ScrollStartNotification) {
      _lastOffset = metrics.pixels;
      return null;
    }
    if (notification is ScrollEndNotification) {
      _lastOffset = metrics.pixels;
      return null;
    }
    if (notification is! ScrollUpdateNotification) return null;

    final currentOffset = metrics.pixels;
    final previousOffset = _lastOffset ?? currentOffset;
    final delta = currentOffset - previousOffset;
    _lastOffset = currentOffset;

    if (currentOffset <= metrics.minScrollExtent + 4) {
      _accumulator = 0.0;
      return true;
    }

    if (delta == 0) return null;
    if (_accumulator != 0 && delta.sign != _accumulator.sign) {
      _accumulator = 0.0;
    }
    _accumulator += delta;

    if (_accumulator > collapseThreshold) {
      _accumulator = 0.0;
      return false;
    } else if (_accumulator < -collapseThreshold) {
      _accumulator = 0.0;
      return true;
    }
    return null;
  }

  void reset() {
    _accumulator = 0.0;
    _lastOffset = null;
  }
}
