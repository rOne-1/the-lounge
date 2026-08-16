import 'package:flutter/foundation.dart';

/// E6: lightweight, in-memory (session-only, not persisted) counter of TMDB
/// API calls and failures, surfaced in Settings' Debug section so testers
/// can see at a glance how chatty/reliable a session was without needing
/// Sentry access.
class ApiCallTracker extends ChangeNotifier {
  ApiCallTracker._();

  static final ApiCallTracker instance = ApiCallTracker._();

  int _totalCalls = 0;
  int _failedCalls = 0;

  int get totalCalls => _totalCalls;
  int get failedCalls => _failedCalls;

  void recordCall() {
    _totalCalls++;
    notifyListeners();
  }

  void recordFailure() {
    _failedCalls++;
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _totalCalls = 0;
    _failedCalls = 0;
    notifyListeners();
  }
}
