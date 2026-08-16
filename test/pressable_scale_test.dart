import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/constants.dart';
import 'package:the_lounge/widgets/pressable_scale.dart';

void main() {
  group('PressableScale — House Spring tactile physics (MC-1)', () {
    testWidgets('uses a quick press-in duration and the house spring release duration/curve', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressableScale(
              onTap: () {},
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final animatedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(animatedScale.scale, equals(1.0));
      // At rest (never pressed), the widget reflects the release branch.
      expect(animatedScale.duration, equals(AppPhysics.houseSpringDuration));
      expect(animatedScale.curve, equals(AppPhysics.houseSpringCurve));

      final gesture = await tester.startGesture(tester.getCenter(find.byType(PressableScale)));
      await tester.pump();

      final pressedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(pressedScale.scale, equals(0.96));
      expect(pressedScale.duration, equals(const Duration(milliseconds: 120)));

      await gesture.up();
      await tester.pump();

      final releasedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(releasedScale.scale, equals(1.0));
      expect(releasedScale.duration, equals(AppPhysics.houseSpringDuration));
      expect(releasedScale.curve, equals(AppPhysics.houseSpringCurve));
    });

    testWidgets('tap cancel (drag off) releases back to resting scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressableScale(
              onTap: () {},
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(PressableScale)));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, equals(0.96));

      // Drag far outside the widget's bounds to trigger a tap cancel.
      await gesture.moveBy(const Offset(2000, 2000));
      await gesture.up();
      await tester.pump();

      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, equals(1.0));
    });

    testWidgets('disabled PressableScale never compresses or fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressableScale(
              enabled: false,
              onTap: () => tapped = true,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PressableScale));
      await tester.pump();

      expect(tapped, isFalse);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, equals(1.0));
    });

    testWidgets('hapticFeedback: true fires selectionClick on press down', (tester) async {
      final calls = <MethodCall>[];
      TestWidgetsFlutterBinding.ensureInitialized()
          .defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() {
        TestWidgetsFlutterBinding.ensureInitialized()
            .defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressableScale(
              hapticFeedback: true,
              onTap: () {},
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      await tester.startGesture(tester.getCenter(find.byType(PressableScale)));
      await tester.pump();

      expect(calls.any((c) => c.method == 'HapticFeedback.vibrate'), isTrue);
    });

    testWidgets('hapticFeedback defaults to false — no haptic call on press', (tester) async {
      final calls = <MethodCall>[];
      TestWidgetsFlutterBinding.ensureInitialized()
          .defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() {
        TestWidgetsFlutterBinding.ensureInitialized()
            .defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressableScale(
              onTap: () {},
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      await tester.startGesture(tester.getCenter(find.byType(PressableScale)));
      await tester.pump();

      expect(calls.any((c) => c.method == 'HapticFeedback.vibrate'), isFalse);
    });
  });
}
