import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/scroll_chrome_tracker.dart';

/// Whether ShellScreen's compact-layout top bar (E1/TF-4) is currently
/// visible. Global rather than per-tab because the top bar itself is
/// rendered once by ShellScreen, shared across every tab in the persistent
/// IndexedStack (see ShellScreen._buildBody) -- ShellScreen resets this to
/// visible on every tab switch so arriving at a fresh tab never strands the
/// bar hidden.
class ChromeVisibilityNotifier extends Notifier<bool> {
  final _tracker = ScrollChromeTracker();

  @override
  bool build() => true;

  void handleScrollNotification(ScrollNotification notification) {
    final next = _tracker.handle(notification);
    if (next != null && next != state) {
      state = next;
    }
  }

  void reset() {
    _tracker.reset();
    if (!state) state = true;
  }
}

final chromeVisibilityProvider =
    NotifierProvider<ChromeVisibilityNotifier, bool>(() {
  return ChromeVisibilityNotifier();
});
