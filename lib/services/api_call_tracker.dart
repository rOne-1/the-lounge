import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Structured failure record containing sanitised details of failed API requests.
class ApiFailureRecord {
  final String timestamp;
  final String endpoint;
  final String url;
  final int? statusCode;
  final String errorMessage;
  final String? responseBody;
  final Map<String, dynamic> queryParams;

  ApiFailureRecord({
    required this.timestamp,
    required this.endpoint,
    required this.url,
    this.statusCode,
    required this.errorMessage,
    this.responseBody,
    this.queryParams = const {},
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'endpoint': endpoint,
        'url': url,
        'statusCode': statusCode,
        'errorMessage': errorMessage,
        if (responseBody != null) 'responseBody': responseBody,
        'queryParams': queryParams,
      };
}

/// E6: lightweight, in-memory (session-only, not persisted) tracker of TMDB
/// API calls and failures, surfaced in Settings' Debug section so testers
/// can inspect and copy structured failure logs in standard JSON without needing Sentry access.
class ApiCallTracker extends ChangeNotifier {
  ApiCallTracker._();

  static final ApiCallTracker instance = ApiCallTracker._();

  static const int maxFailures = 100;
  final List<ApiFailureRecord> _failureRecords = [];

  int _totalCalls = 0;
  int _failedCalls = 0;

  int get totalCalls => _totalCalls;
  int get failedCalls => _failedCalls;
  List<ApiFailureRecord> get failureRecords => List.unmodifiable(_failureRecords);

  void recordCall() {
    _totalCalls++;
    notifyListeners();
  }

  void recordFailure({
    String? endpoint,
    Uri? uri,
    int? statusCode,
    dynamic error,
    String? responseBody,
    Map<String, dynamic>? queryParams,
  }) {
    _failedCalls++;

    final sanitizedUrl = _sanitizeUrl(uri);
    final sanitizedParams = _sanitizeParams(queryParams ?? uri?.queryParameters);

    final record = ApiFailureRecord(
      timestamp: DateTime.now().toIso8601String(),
      endpoint: endpoint ?? uri?.path ?? 'unknown',
      url: sanitizedUrl,
      statusCode: statusCode,
      errorMessage: error?.toString() ?? (statusCode != null ? 'HTTP $statusCode' : 'Unknown error'),
      responseBody: responseBody != null && responseBody.length > 500
          ? '${responseBody.substring(0, 500)}...'
          : responseBody,
      queryParams: sanitizedParams,
    );

    if (_failureRecords.length >= maxFailures) {
      _failureRecords.removeAt(0);
    }
    _failureRecords.add(record);

    notifyListeners();
  }

  String exportFailuresJsonPretty() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_failureRecords.map((r) => r.toJson()).toList());
  }

  void clearFailures() {
    _failureRecords.clear();
    _failedCalls = 0;
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _totalCalls = 0;
    _failedCalls = 0;
    _failureRecords.clear();
    notifyListeners();
  }

  static String _sanitizeUrl(Uri? uri) {
    if (uri == null) return '';
    final params = Map<String, String>.from(uri.queryParameters);
    if (params.containsKey('api_key')) params['api_key'] = '[REDACTED]';
    return Uri.decodeFull(uri.replace(queryParameters: params.isEmpty ? null : params).toString());
  }

  static Map<String, dynamic> _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null) return {};
    final sanitized = Map<String, dynamic>.from(params);
    if (sanitized.containsKey('api_key')) sanitized['api_key'] = '[REDACTED]';
    if (sanitized.containsKey('Authorization')) sanitized['Authorization'] = '[REDACTED]';
    return sanitized;
  }
}
