import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/services/api_call_tracker.dart';

// E6: session-only API call/failure counters.
void main() {
  setUp(() {
    ApiCallTracker.instance.reset();
  });

  test('recordCall increments totalCalls and notifies listeners', () {
    var notified = 0;
    ApiCallTracker.instance.addListener(() => notified++);

    expect(ApiCallTracker.instance.totalCalls, equals(0));
    ApiCallTracker.instance.recordCall();
    ApiCallTracker.instance.recordCall();

    expect(ApiCallTracker.instance.totalCalls, equals(2));
    expect(ApiCallTracker.instance.failedCalls, equals(0));
    expect(notified, equals(2));
  });

  test('recordFailure increments failedCalls independently of totalCalls', () {
    ApiCallTracker.instance.recordCall();
    ApiCallTracker.instance.recordFailure();

    expect(ApiCallTracker.instance.totalCalls, equals(1));
    expect(ApiCallTracker.instance.failedCalls, equals(1));
  });

  test('reset zeroes both counters', () {
    ApiCallTracker.instance.recordCall();
    ApiCallTracker.instance.recordFailure();
    ApiCallTracker.instance.reset();

    expect(ApiCallTracker.instance.totalCalls, equals(0));
    expect(ApiCallTracker.instance.failedCalls, equals(0));
  });
}
