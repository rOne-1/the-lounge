import 'package:flutter/material.dart';

/// TH-STATE (locked design decision): universal, theme-*independent*
/// semantic colors for media/watch tracking states. These deliberately do
/// NOT change per theme -- the whole point is instant visual identification
/// and muscle memory for a status regardless of which of the 6 ambiances is
/// active. Never hardcode one of these hexes directly in a widget/screen;
/// always reference these constants.
class AppStatusColors {
  AppStatusColors._();

  /// Watchlist -- Amber / Warm Gold.
  static const Color watchlist = Color(0xFFE5A93C);

  /// "Save for later" / Maybe list. Not in the original locked 6-color
  /// list, but the app has always tracked this as a distinct 7th status
  /// (Discover's right-swipe, MediaCard badges, QuickStatusSheet) --
  /// added here as Rose/Pink to keep full parity with existing usage,
  /// staying visually distinct from all six locked hues above.
  static const Color save = Color(0xFFEC4899);

  /// Watching -- Cerulean / Electric Blue.
  static const Color watching = Color(0xFF3B82F6);

  /// Watched -- Emerald / Mint Green.
  static const Color watched = Color(0xFF10B981);

  /// On-Hold -- Sunset Orange.
  static const Color onHold = Color(0xFFF97316);

  /// Dropped -- Crimson / Rose.
  static const Color dropped = Color(0xFFEF4444);

  /// Skip/"not now" gesture -- deliberately muted and low-signal, distinct
  /// from the other persisted status hues -- Amethyst / Purple.
  static const Color skip = Color(0xFF8B5CF6);

  static const List<Color> all = [
    watchlist,
    save,
    watching,
    watched,
    onHold,
    dropped,
    skip,
  ];
}
