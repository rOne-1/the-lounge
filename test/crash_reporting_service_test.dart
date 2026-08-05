import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/services/crash_reporting_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashReportingService Tests', () {
    setUp(() async {
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {}
    });

    test('sanitizeString redacts dotenv TMDB token', () {
      const secret = 'eyJhbGciOiJIUzI1NiJ9.secret_payload_token_12345.signature_here';
      const input = 'API Error occurred with token: $secret';
      final sanitized = CrashReportingService.sanitizeString(input);

      expect(sanitized, isNot(contains(secret)));
      expect(sanitized, contains('[REDACTED_SECRET]'));
    });

    test('sanitizeString redacts Bearer tokens and api_key parameters', () {
      const input = 'Request GET https://api.themoviedb.org/3/movie/popular?api_key=secretkey123 Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.test.sig';
      final sanitized = CrashReportingService.sanitizeString(input);

      expect(sanitized, isNot(contains('secretkey123')));
      expect(sanitized, isNot(contains('eyJhbGciOiJIUzI1NiJ9.test.sig')));
      expect(sanitized, contains('[REDACTED_SECRET]'));
    });

    test('CrashReportingService initializes global error hooks and captures exceptions safely', () async {
      await CrashReportingService.init();
      expect(CrashReportingService.isInitialized, isTrue);

      expect(() {
        CrashReportingService.captureException(
          Exception('Test exception with token eyJhbGciOiJIUzI1NiJ9.secret_payload_token_12345.signature_here'),
          StackTrace.current,
        );
      }, returnsNormally);
    });
  });
}
