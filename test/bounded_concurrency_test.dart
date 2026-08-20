import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/utils/bounded_concurrency.dart';

void main() {
  test('returns results in the same order as the input items', () async {
    final results = await mapBounded<int, int>(
      [5, 1, 4, 2, 3],
      (i) async {
        await Future.delayed(Duration(milliseconds: i));
        return i * 10;
      },
      maxConcurrent: 3,
    );
    expect(results, [50, 10, 40, 20, 30]);
  });

  test('never runs more than maxConcurrent actions at once', () async {
    var inFlight = 0;
    var maxObserved = 0;
    await mapBounded<int, void>(
      List.generate(10, (i) => i),
      (i) async {
        inFlight++;
        maxObserved = maxObserved < inFlight ? inFlight : maxObserved;
        await Future.delayed(const Duration(milliseconds: 5));
        inFlight--;
      },
      maxConcurrent: 3,
    );
    expect(maxObserved, lessThanOrEqualTo(3));
  });

  test('empty input returns an empty list without calling action', () async {
    var callCount = 0;
    final results = await mapBounded<int, int>(
      [],
      (i) async {
        callCount++;
        return i;
      },
    );
    expect(results, isEmpty);
    expect(callCount, 0);
  });

  test('propagates an error from action', () async {
    expect(
      () => mapBounded<int, int>(
        [1, 2, 3],
        (i) async {
          if (i == 2) throw Exception('boom');
          return i;
        },
      ),
      throwsA(isA<Exception>()),
    );
  });
}
