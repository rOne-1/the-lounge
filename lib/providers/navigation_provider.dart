import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab {
  lobby,
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

  // PERS-NAV-1: Your Space is the app's default startup destination and
  // navigation anchor (see ShellScreen's PopScope and
  // FloatingNavigationCapsule's destination ordering).
  const NavigationState({
    this.currentTab = AppTab.yourSpace,
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

class SearchGenreNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setGenre(String genre) {
    state = genre;
  }
}

final searchGenreProvider = NotifierProvider<SearchGenreNotifier, String>(() {
  return SearchGenreNotifier();
});

class SearchKeywordNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setKeyword(String? keyword) {
    state = keyword;
  }

  void clearKeyword() {
    state = null;
  }
}

final searchKeywordProvider =
    NotifierProvider<SearchKeywordNotifier, String?>(() {
  return SearchKeywordNotifier();
});

class LoungeRouteObserver extends NavigatorObserver {
  final void Function(int depth)? onDepthChanged;
  final List<Route<dynamic>> _history = [];

  LoungeRouteObserver({this.onDepthChanged});

  int get depth => (_history.length - 1).clamp(0, 999);

  void _notify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onDepthChanged?.call(depth);
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _history.add(route);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _history.remove(route);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _history.remove(route);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _history.remove(oldRoute);
    if (newRoute != null) _history.add(newRoute);
    _notify();
  }
}

class RouteDepthNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setDepth(int depth) => state = depth;
}

final routeDepthProvider =
    NotifierProvider<RouteDepthNotifier, int>(() => RouteDepthNotifier());

final loungeRouteObserverProvider = Provider<LoungeRouteObserver>((ref) {
  return LoungeRouteObserver(
    onDepthChanged: (depth) {
      ref.read(routeDepthProvider.notifier).setDepth(depth);
    },
  );
});


