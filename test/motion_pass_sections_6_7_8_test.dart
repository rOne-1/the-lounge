import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/themes/ambiance_colors.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/reading_room_theme.dart';
import 'package:the_lounge/themes/theme_registry.dart';
import 'package:the_lounge/themes/app_theme.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/reading_room_theme.dart';
import 'package:the_lounge/themes/violet_dusk_theme.dart';
import 'package:the_lounge/themes/midnight_cinema_theme.dart';
import 'package:the_lounge/widgets/drag_to_dismiss_sheet.dart';

void main() {
  group('Section 8: Reading Room Contrast & Accent Audit Tests', () {
    test('rrAmbianceColors.sub uses solid accessible dark color Color(0xFF5C4C3D)', () {
      expect(rrAmbianceColors.sub, equals(const Color(0xFF5C4C3D)));
      expect(rrAmbianceColors.sub.a, equals(1.0)); // Solid color, no low-opacity alpha blend
    });

    test('Reading Room primary button decoration uses warm linear gradient', () {
      final decDark = srAmbianceColors.primaryButtonDecoration;
      final decLight = rrAmbianceColors.primaryButtonDecoration;

      expect(decDark.color, equals(srAmbianceColors.acc));
      expect(decLight.gradient, isNotNull);
      final gradient = decLight.gradient as LinearGradient;
      expect(gradient.colors.last, equals(const Color(0xFF8F3E1E)));
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
