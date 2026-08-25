import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/archive_sort_group.dart';

/// PERS-SORT-2: the archive shelf's sort/group selection -- previously local
/// `State` on `ArchiveShelfScreen`, reset every time that screen's widget
/// was disposed and recreated (e.g. navigating to another tab and back to
/// Archive). Lifted into a provider so it survives for the life of the app
/// session instead, shared across every shelf kind, matching how it already
/// behaved when swiping between shelf kinds within one screen instance.
class ArchiveViewState {
  final ArchiveSortOption sort;
  final ArchiveGroupOption group;
  final bool sortAscending;
  final bool watchedSortByRating;
  final bool watchedGroupByCollection;

  const ArchiveViewState({
    this.sort = ArchiveSortOption.lastAdded,
    this.group = ArchiveGroupOption.none,
    this.sortAscending = false,
    this.watchedSortByRating = false,
    this.watchedGroupByCollection = false,
  });

  ArchiveViewState copyWith({
    ArchiveSortOption? sort,
    ArchiveGroupOption? group,
    bool? sortAscending,
    bool? watchedSortByRating,
    bool? watchedGroupByCollection,
  }) {
    return ArchiveViewState(
      sort: sort ?? this.sort,
      group: group ?? this.group,
      sortAscending: sortAscending ?? this.sortAscending,
      watchedSortByRating: watchedSortByRating ?? this.watchedSortByRating,
      watchedGroupByCollection: watchedGroupByCollection ?? this.watchedGroupByCollection,
    );
  }
}

class ArchiveViewStateNotifier extends Notifier<ArchiveViewState> {
  @override
  ArchiveViewState build() => const ArchiveViewState();

  void setSort(ArchiveSortOption sort) => state = state.copyWith(sort: sort);

  /// Choosing an explicit sort from the dropdown supersedes Watched's
  /// "My Rating" toggle, matching the existing precedence rule.
  void setSortClearingRatingToggle(ArchiveSortOption sort) =>
      state = state.copyWith(sort: sort, watchedSortByRating: false);

  void setGroup(ArchiveGroupOption group) => state = state.copyWith(group: group);

  void toggleSortAscending() =>
      state = state.copyWith(sortAscending: !state.sortAscending);

  void toggleWatchedSortByRating() =>
      state = state.copyWith(watchedSortByRating: !state.watchedSortByRating);

  void toggleWatchedGroupByCollection() =>
      state = state.copyWith(watchedGroupByCollection: !state.watchedGroupByCollection);
}

final archiveViewStateProvider =
    NotifierProvider<ArchiveViewStateNotifier, ArchiveViewState>(() {
  return ArchiveViewStateNotifier();
});
