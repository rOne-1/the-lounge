import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/constants.dart';
import 'package:the_lounge/widgets/drag_to_dismiss_sheet.dart';

void main() {
  group('Section 8: Reading Room Contrast & Accent Audit Tests', () {
    test('AppColors.rrSub uses solid accessible dark color Color(0xFF5C4C3D)', () {
      expect(AppColors.rrSub, equals(const Color(0xFF5C4C3D)));
      expect(AppColors.rrSub.a, equals(1.0)); // Solid color, no low-opacity alpha blend
    });

    test('Reading Room primary button decoration uses warm linear gradient', () {
      final decDark = AppColors.primaryButtonDecoration(isDark: true);
      final decLight = AppColors.primaryButtonDecoration(isDark: false);

      expect(decDark.color, equals(AppColors.srAcc));
      expect(decLight.gradient, equals(AppColors.rrPrimaryGradient));
      expect(AppColors.rrAccGradientEnd, equals(const Color(0xFF8F3E1E)));
    });
  });

  group('Section 7: DragToDismissSheet Tests', () {
    testWidgets('Pan down past threshold triggers onDismiss', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DragToDismissSheet(
              isDark: false,
              dismissThreshold: 100.0,
              onDismiss: () {
                dismissed = true;
              },
              child: const SizedBox(
                height: 300,
                width: double.infinity,
                child: Text('Sheet Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sheet Content'), findsOneWidget);

      // Perform a vertical drag down past 100px
      final gesture = await tester.startGesture(tester.getCenter(find.text('Sheet Content')));
      await gesture.moveBy(const Offset(0, 150));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('Pan down below threshold snaps back using houseSpringCurve', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DragToDismissSheet(
              isDark: false,
              dismissThreshold: 100.0,
              onDismiss: () {
                dismissed = true;
              },
              child: const SizedBox(
                height: 300,
                width: double.infinity,
                child: Text('Sheet Content'),
              ),
            ),
          ),
        ),
      );

      // Perform small vertical drag down (40px, below threshold)
      final gesture = await tester.startGesture(tester.getCenter(find.text('Sheet Content')));
      await gesture.moveBy(const Offset(0, 40));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(dismissed, isFalse);
    });
  });
}
