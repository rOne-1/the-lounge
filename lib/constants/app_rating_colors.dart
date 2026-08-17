import 'package:flutter/material.dart';
import '../models/personal_rating.dart';

/// PERS-RATE-1: theme-*independent* semantic colors for the 4-tier personal
/// rating axis, mirroring [AppStatusColors]'s "never hardcode a hex, always
/// reference this" convention -- but deliberately a distinct palette family
/// from status colors, since taste (how a user *felt* about a title) is a
/// different semantic axis from status (where a title *sits*). Not part of
/// the original locked design doc's color list (which only specified status
/// colors); introduced here as a small, easily-reversible technical call.
class AppRatingColors {
  AppRatingColors._();

  /// Loved it -- antique gold, the warmest/highest tier.
  static const Color loved = Color(0xFFC9A227);

  /// Liked it -- sage green.
  static const Color liked = Color(0xFF7FB77E);

  /// It was okay -- warm neutral gray.
  static const Color okay = Color(0xFF9C9691);

  /// Not for me -- muted plum. Quietly negative, deliberately not an alarm
  /// red (that's reserved for the Dropped *status*, a different concept).
  static const Color notForMe = Color(0xFF6B5B6E);

  static const List<Color> all = [loved, liked, okay, notForMe];

  static Color of(PersonalRating rating) {
    switch (rating) {
      case PersonalRating.loved:
        return loved;
      case PersonalRating.liked:
        return liked;
      case PersonalRating.okay:
        return okay;
      case PersonalRating.notForMe:
        return notForMe;
    }
  }
}
