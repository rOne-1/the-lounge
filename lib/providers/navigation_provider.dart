import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab {
  home,
  discover,
  search,
  yourSpace,
  calendar,
}

enum MediaTypeToggle {
  movies,
  tv,
}

class NavigationState {
  final AppTab currentTab;
  final MediaTypeToggle activeMediaType;

  const NavigationState({
    this.currentTab = AppTab.home,
    this.activeMediaType = MediaTypeToggle.movies,
  });

  NavigationState copyWith({
    AppTab? currentTab,
    MediaTypeToggle? activeMediaType,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
      activeMediaType: activeMediaType ?? this.activeMediaType,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return const NavigationState();
  }

  void setTab(AppTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void setMediaType(MediaTypeToggle type) {
    state = state.copyWith(activeMediaType: type);
  }

  void toggleMediaType() {
    state = state.copyWith(
      activeMediaType: state.activeMediaType == MediaTypeToggle.movies
          ? MediaTypeToggle.tv
          : MediaTypeToggle.movies,
    );
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(() {
  return NavigationNotifier();
});

class BrowseGenreNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setGenre(String genre) {
    state = genre;
  }
}

final browseGenreProvider = NotifierProvider<BrowseGenreNotifier, String>(() {
  return BrowseGenreNotifier();
});

class BrowseKeywordNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setKeyword(String? keyword) {
    state = keyword;
  }

  void clearKeyword() {
    state = null;
  }
}

final browseKeywordProvider =
    NotifierProvider<BrowseKeywordNotifier, String?>(() {
  return BrowseKeywordNotifier();
});


