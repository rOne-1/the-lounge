import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized service for capturing uncaught errors, repository exceptions, and crash reports.
/// 
/// Note on Architecture Choice:
/// Sentry Flutter (`sentry_flutter`) was selected for crash reporting and exception visibility.
/// It provides zero-overhead native integration, automatic Flutter framing error capture, and
/// breadcrumbs without requiring complex native Gradle build plugin steps for alpha sideloaded APKs.
class CrashReportingService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Regexp patterns used to identify and redact raw TMDB secrets or Bearer tokens.
  static final List<RegExp> _secretPatterns = [
    RegExp(r'Bearer\s+[A-Za-z0-9\-_=]+\.[A-Za-z0-9\-_=]+\.?[A-Za-z0-9\-_=]*', caseSensitive: false),
    RegExp(r'api_key=[A-Za-z0-9_]+', caseSensitive: false),
    RegExp(r'eyJ[A-Za-z0-9\-_=]+\.[A-Za-z0-9\-_=]+\.?[A-Za-z0-9\-_=]*'),
  ];

  /// Strips and redacts raw secrets, API keys, and Bearer tokens from string data.
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;
    String sanitized = input;

    // Check environment token if initialized
    try {
      if (dotenv.isInitialized) {
        final rawToken = dotenv.env['TMDB_READ_ACCESS_TOKEN'];
        if (rawToken != null &&
            rawToken.trim().isNotEmpty &&
            rawToken != 'your_tmdb_read_access_token_here') {
          sanitized = sanitized.replaceAll(rawToken.trim(), '[REDACTED_SECRET]');
        }
      }
    } catch (_) {}

    // Apply general secret pattern replacements
    for (final pattern in _secretPatterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) => '[REDACTED_SECRET]');
    }

    return sanitized;
  }

  /// Initializes crash reporting, global error hooks (`FlutterError.onError` and `PlatformDispatcher.onError`),
  /// and configures Sentry with strict secret redaction (`beforeSend` callback).
  static Future<void> init({
    String? dsn,
    bool enableSentryInDev = false,
  }) async {
    if (_isInitialized) return;

    final targetDsn = dsn ?? dotenv.env['SENTRY_DSN'];

    // 1. Configure Flutter framework error handling
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final sanitizedMessage = sanitizeString(details.exceptionAsString());
      developer.log(
        'Captured uncaught FlutterError: $sanitizedMessage',
        name: 'CrashReportingService',
        error: details.exception,
        stackTrace: details.stack,
        level: 1000,
      );
      captureException(details.exception, details.stack, details);
      if (originalOnError != null) {
        originalOnError(details);
      }
    };

    // 2. Configure Isolate / PlatformDispatcher uncaught asynchronous error handling
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      final sanitizedMessage = sanitizeString(error.toString());
      developer.log(
        'Captured uncaught Async/Platform error: $sanitizedMessage',
        name: 'CrashReportingService',
        error: error,
        stackTrace: stack,
        level: 1000,
      );
      captureException(error, stack);
      return true; // Error handled
    };

    // 3. Initialize Sentry Flutter SDK if DSN is provided or configured
    if (targetDsn != null && targetDsn.isNotEmpty) {
      try {
        await SentryFlutter.init(
          (options) {
            options.dsn = targetDsn;
            options.tracesSampleRate = 1.0;
            options.sendDefaultPii = false; // Strip PII by default
            options.beforeSend = (SentryEvent event, Hint hint) {
              // Strict redaction of secrets in event values, messages, breadcrumbs, and exceptions
              final sanitizedMessage = event.message != null
                  ? SentryMessage(sanitizeString(event.message!.formatted))
                  : null;

              final sanitizedExceptions = event.exceptions?.map((ex) {
                return SentryException(
                  type: ex.type,
                  value: ex.value != null ? sanitizeString(ex.value!) : null,
                  module: ex.module,
                  threadId: ex.threadId,
                  mechanism: ex.mechanism,
                );
              }).toList();

              final sanitizedBreadcrumbs = event.breadcrumbs?.map((b) {
                return Breadcrumb(
                  message: b.message != null ? sanitizeString(b.message!) : null,
                  category: b.category,
                  data: b.data?.map((k, v) => MapEntry(k, v is String ? sanitizeString(v) : v)),
                  level: b.level,
                  timestamp: b.timestamp,
                  type: b.type,
                );
              }).toList();

              return event.copyWith(
                message: sanitizedMessage,
                exceptions: sanitizedExceptions,
                breadcrumbs: sanitizedBreadcrumbs,
              );
            };
          },
        );
        developer.log('Sentry SDK initialized successfully.', name: 'CrashReportingService');
      } catch (e, st) {
        developer.log(
          'Failed to initialize Sentry SDK: $e',
          name: 'CrashReportingService',
          error: e,
          stackTrace: st,
        );
      }
    } else {
      developer.log(
        'Sentry DSN not provided. CrashReportingService active in local logging mode.',
        name: 'CrashReportingService',
      );
    }

    _isInitialized = true;
  }

  /// Manually capture and report repository exceptions or caught errors.
  /// Automatically redacts sensitive token strings from exception messages and logs.
  static void captureException(
    dynamic exception, [
    StackTrace? stackTrace,
    dynamic hint,
  ]) {
    final sanitizedMessage = sanitizeString(exception.toString());
    developer.log(
      'Reported Exception: $sanitizedMessage',
      name: 'CrashReportingService',
      error: exception,
      stackTrace: stackTrace,
    );

    if (_isInitialized && Sentry.isEnabled) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: hint,
      );
    }
  }
}
