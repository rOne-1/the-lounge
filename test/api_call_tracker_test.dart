import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/services/api_call_tracker.dart';

void main() {
  setUp(() {
    ApiCallTracker.instance.reset();
  });

  group('ApiCallTracker failure logging and JSON export', () {
    test('records calls and failures correctly', () {
      final tracker = ApiCallTracker.instance;
      expect(tracker.totalCalls, 0);
      expect(tracker.failedCalls, 0);
      expect(tracker.failureRecords, isEmpty);

      tracker.recordCall();
      tracker.recordCall();
      expect(tracker.totalCalls, 2);

      tracker.recordFailure(
        endpoint: '/movie/popular',
        uri: Uri.parse('https://api.themoviedb.org/3/movie/popular?api_key=secret_123&page=1'),
        statusCode: 401,
        error: 'Invalid API key',
        responseBody: '{"status_code":7,"status_message":"Invalid API key"}',
        queryParams: {'api_key': 'secret_123', 'page': 1},
      );

      expect(tracker.failedCalls, 1);
      expect(tracker.failureRecords.length, 1);

      final record = tracker.failureRecords.first;
      expect(record.endpoint, '/movie/popular');
      expect(record.statusCode, 401);
      expect(record.errorMessage, 'Invalid API key');
      expect(record.responseBody, contains('Invalid API key'));

      // Sensitive api_key must be redacted
      expect(record.url, isNot(contains('secret_123')));
      expect(record.url, contains('[REDACTED]'));
      expect(record.queryParams['api_key'], '[REDACTED]');
      expect(record.queryParams['page'], 1);
    });

    test('exportFailuresJsonPretty outputs valid JSON matching ApiFailureRecord schema', () {
      final tracker = ApiCallTracker.instance;
      tracker.recordFailure(
        endpoint: '/tv/top_rated',
        uri: Uri.parse('https://api.themoviedb.org/3/tv/top_rated'),
        statusCode: 500,
        error: 'Internal Server Error',
        responseBody: 'Server failure',
      );

      final jsonString = tracker.exportFailuresJsonPretty();
      expect(jsonString, isNotEmpty);

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      expect(decoded.length, 1);

      final first = decoded.first as Map<String, dynamic>;
      expect(first['endpoint'], '/tv/top_rated');
      expect(first['statusCode'], 500);
      expect(first['errorMessage'], 'Internal Server Error');
      expect(first['responseBody'], 'Server failure');
      expect(first['timestamp'], isNotNull);
    });

    test('enforces bounded FIFO queue of max 100 failure records', () {
      final tracker = ApiCallTracker.instance;
      for (int i = 0; i < 110; i++) {
        tracker.recordFailure(
          endpoint: '/item/$i',
          statusCode: 400 + (i % 10),
          error: 'Error $i',
        );
      }

      expect(tracker.failedCalls, 110);
      expect(tracker.failureRecords.length, 100);
      // The first 10 items (0..9) should have been evicted; first remaining is item 10
      expect(tracker.failureRecords.first.endpoint, '/item/10');
      expect(tracker.failureRecords.last.endpoint, '/item/109');
    });

    test('clearFailures resets records and failure count', () {
      final tracker = ApiCallTracker.instance;
      tracker.recordCall();
      tracker.recordFailure(endpoint: '/test', error: 'err');

      expect(tracker.totalCalls, 1);
      expect(tracker.failedCalls, 1);
      expect(tracker.failureRecords.length, 1);

      tracker.clearFailures();
      expect(tracker.totalCalls, 1); // total calls preserved
      expect(tracker.failedCalls, 0);
      expect(tracker.failureRecords, isEmpty);
    });
  });
}
