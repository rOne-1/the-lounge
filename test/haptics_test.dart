import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/discover_screen.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/utils/app_haptics.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Installs a mock platform channel handler recording every
  /// `HapticFeedback.vibrate` call's type argument, matching the exact
  /// pattern already established in `pressable_scale_test.dart`.
  List<String?> installHapticRecorder() {
    final calls = <String?>[];
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String?);
      }
      return null;
    });
    addTearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized()
          .defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    return calls;
  }

  group('CRAFT-HAPTIC-1: hapticWeightForThemeId', () {
    test('maps each theme id to its documented weight family', () {
      expect(hapticWeightForThemeId('screening_room'), HapticWeight.crispMechanical);
      expect(hapticWeightForThemeId('tuscany'), HapticWeight.crispMechanical);
      expect(hapticWeightForThemeId('midnight_cinema'), HapticWeight.deepVelvet);
      expect(hapticWeightForThemeId('violet_dusk'), HapticWeight.deepVelvet);
      expect(hapticWeightForThemeId('orchid_bloom'), HapticWeight.airySubtle);
    });

    test('falls back to crispMechanical for an unknown id rather than throwing', () {
      expect(hapticWeightForThemeId('not_a_real_theme'), HapticWeight.crispMechanical);
    });
  });

  group('CRAFT-HAPTIC-1: AppHaptics fires distinct primitives per weight', () {
    test('thresholdTick uses selectionClick for crisp/airy, lightImpact for velvet', () async {
      final calls = installHapticRecorder();

      await AppHaptics.thresholdTick(HapticWeight.crispMechanical);
      await AppHaptics.thresholdTick(HapticWeight.deepVelvet);
      await AppHaptics.thresholdTick(HapticWeight.airySubtle);

      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.selectionClick',
      ]);
    });

    test('commitImpact scales weight-appropriately: medium/heavy/light', () async {
      final calls = installHapticRecorder();

      await AppHaptics.commitImpact(HapticWeight.crispMechanical);
      await AppHaptics.commitImpact(HapticWeight.deepVelvet);
      await AppHaptics.commitImpact(HapticWeight.airySubtle);

      expect(calls, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.lightImpact',
      ]);
    });

    test('doublePulse fires exactly two impacts of the same weight-appropriate type', () async {
      final calls = installHapticRecorder();

      await AppHaptics.doublePulse(HapticWeight.airySubtle);

      expect(calls, [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.lightImpact',
      ]);
    });

    test('threshold tick and commit impact are genuinely distinct calls, not the same primitive',
        () async {
      final calls = installHapticRecorder();

      await AppHaptics.thresholdTick(HapticWeight.crispMechanical);
      await AppHaptics.commitImpact(HapticWeight.crispMechanical);

      expect(calls[0], isNot(equals(calls[1])));
    });

    test('a channel error is swallowed, not rethrown (zero crashes on non-haptic platforms)',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized()
          .defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        throw MissingPluginException('no haptics on this platform');
      });
      addTearDown(() {
        TestWidgetsFlutterBinding.ensureInitialized()
            .defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await expectLater(
        AppHaptics.thresholdTick(HapticWeight.crispMechanical),
        completes,
      );
      await expectLater(
        AppHaptics.commitImpact(HapticWeight.crispMechanical),
        completes,
      );
      await expectLater(
        AppHaptics.doublePulse(HapticWeight.crispMechanical),
        completes,
      );
    });
  });

  group('CRAFT-HAPTIC-1: Discover swipe deck fires distinct feedback for threshold vs commit', () {
    testWidgets('crossing the commit threshold ticks once; releasing past it fires a separate commit impact',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      final calls = installHapticRecorder();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: DiscoverScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(100, 100)); // dismiss legend overlay
      await tester.pumpAndSettle();
      calls.clear();

      final center = tester.getCenter(find.byType(DiscoverScreen));
      final gesture = await tester.startGesture(center);
      // Past the 100px commit threshold, but released back below release
      // velocity/distance thresholds afterward -- should tick but not
      // commit-impact.
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(calls, contains('HapticFeedbackType.selectionClick'));
      expect(calls, isNot(contains('HapticFeedbackType.mediumImpact')));
    });

    testWidgets('a full commit swipe fires both the threshold tick and the commit impact',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      final calls = installHapticRecorder();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: DiscoverScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
      calls.clear();

      await tester.fling(find.byType(DiscoverScreen), const Offset(600, 0), 1500);
      await tester.pumpAndSettle();

      expect(calls, contains('HapticFeedbackType.selectionClick'));
      expect(calls, contains('HapticFeedbackType.mediumImpact'));
    });
  });
}
