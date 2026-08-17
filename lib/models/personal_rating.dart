/// 4-tier personal rating a user can assign to a watched title or season.
enum PersonalRating {
  loved(3, 'Loved it'),
  liked(2, 'Liked it'),
  okay(1, 'It was okay'),
  notForMe(0, 'Not for me');

  final int ordinal;
  final String label;
  const PersonalRating(this.ordinal, this.label);

  static PersonalRating? fromOrdinal(int? value) {
    if (value == null) return null;
    return PersonalRating.values.firstWhere(
      (e) => e.ordinal == value,
      orElse: () => PersonalRating.okay,
    );
  }
}
