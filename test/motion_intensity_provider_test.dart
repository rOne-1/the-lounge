import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/motion_intensity_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('MotionIntensity enum', () {
    test('off never animates and scales to 0.0', () {
      expect(MotionIntensity.off.animates, isFalse);
      expect(MotionIntensity.off.scale, 0.0);
    });

    test('reduced animates at a scaled-down magnitude', () {
      expect(MotionIntensity.reduced.animates, isTrue);
      expect(MotionIntensity.reduced.scale, greaterThan(0.0));
      expect(MotionIntensity.reduced.scale, lessThan(1.0));
    });

    test('full animates at scale 1.0', () {
      expect(MotionIntensity.full.animates, isTrue);
      expect(MotionIntensity.full.scale, 1.0);
    });
  });

  group('MotionIntensity.gateAnimation', () {
    test('an explicit false request always stays false, at every tier', () {
      expect(MotionIntensity.full.gateAnimation(false), isFalse);
      expect(MotionIntensity.reduced.gateAnimation(false), isFalse);
      expect(MotionIntensity.off.gateAnimation(false), isFalse);
    });

    test('off forces false regardless of what was requested', () {
      expect(MotionIntensity.off.gateAnimation(true), isFalse);
      expect(MotionIntensity.off.gateAnimation(null), isFalse);
    });

    test('reduced and full pass a null/true request through unchanged', () {
      expect(MotionIntensity.reduced.gateAnimation(true), isTrue);
      expect(MotionIntensity.reduced.gateAnimation(null), isNull);
      expect(MotionIntensity.full.gateAnimation(true), isTrue);
      expect(MotionIntensity.full.gateAnimation(null), isNull);
    });
  });

  group('motionIntensityProvider', () {
    testWidgets('defaults to full when nothing is stored', (tester) async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(motionIntensityProvider), MotionIntensity.full);
    });

    testWidgets('restores a previously-persisted tier', (tester) async {
      SharedPreferences.setMockInitialValues({'motion_intensity': 'reduced'});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(motionIntensityProvider), MotionIntensity.reduced);
    });

    testWidgets('setIntensity updates state and persists', (tester) async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(motionIntensityProvider.notifier)
          .setIntensity(MotionIntensity.off);

      expect(container.read(motionIntensityProvider), MotionIntensity.off);
      expect(prefs.getString('motion_intensity'), 'off');
    });

    testWidgets('an unrecognized stored value falls back to full',
        (tester) async {
      SharedPreferences.setMockInitialValues({'motion_intensity': 'bogus'});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(motionIntensityProvider), MotionIntensity.full);
    });

    testWidgets(
        'falls back to full when sharedPreferencesProvider is not overridden '
        '(matches MediaNotifier\'s own defensive pattern -- widgets that watch '
        'this provider must not force every existing test to add an override '
        'it never needed before)', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(motionIntensityProvider), MotionIntensity.full);
    });
  });
}
