import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/constants.dart';
import 'package:the_lounge/themes/theme_registry.dart';
import 'package:the_lounge/themes/app_theme.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/reading_room_theme.dart';
import 'package:the_lounge/themes/violet_dusk_theme.dart';
import 'package:the_lounge/themes/midnight_cinema_theme.dart';
import 'package:the_lounge/widgets/ambient_glow.dart';

void main() {
  group('AmbientGlowWidget Tests', () {
    testWidgets('renders child content in dark theme (Screening Room)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: screeningRoomTheme.themeData,
          home: const Scaffold(
            body: AmbientGlowWidget(
              enableAnimation: false,
              child: Text('Test Child Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Child Content'), findsOneWidget);
      expect(find.byType(AmbientGlowWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders child content in light theme (Reading Room)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: readingRoomTheme.themeData,
          home: const Scaffold(
            body: AmbientGlowWidget(
              enableAnimation: false,
              child: Text('Reading Room Glow'),
            ),
          ),
        ),
      );

      expect(find.text('Reading Room Glow'), findsOneWidget);
      expect(find.byType(AmbientGlowWidget), findsOneWidget);
    });

    testWidgets('animates glow cycle continuously when enableAnimation is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: screeningRoomTheme.themeData,
          home: const Scaffold(
            body: AmbientGlowWidget(
              enableAnimation: true,
              child: SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );

      // Initial frame
      await tester.pump(Duration.zero);

      // Advance by 7.5 seconds (half cycle of 15.0s)
      await tester.pump(const Duration(milliseconds: 7500));

      // Advance by another 7.5 seconds (full cycle of 15.0s)
      await tester.pump(const Duration(milliseconds: 7500));

      expect(find.byType(AmbientGlowWidget), findsOneWidget);
    });

    testWidgets('defaults to animation enabled when enableAnimation is omitted (null)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: screeningRoomTheme.themeData,
          home: const Scaffold(
            body: AmbientGlowWidget(
              child: SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );

      // Initial frame
      await tester.pump(Duration.zero);

      // Advance by 1 second without timing out or throwing
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byType(AmbientGlowWidget), findsOneWidget);
    });

    testWidgets('can be pumped with pumpAndSettle when enableAnimation is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: screeningRoomTheme.themeData,
          home: const Scaffold(
            body: AmbientGlowWidget(
              enableAnimation: false,
              child: Text('Static Ambiance'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Static Ambiance'), findsOneWidget);
    });

    testWidgets('accepts custom color overrides', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: screeningRoomTheme.themeData,
          home: const Scaffold(
            body: AmbientGlowWidget(
              enableAnimation: false,
              color1: Colors.red,
              color2: Colors.blue,
              baseColor: Colors.black,
              child: Text('Custom Glow Colors'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Glow Colors'), findsOneWidget);
    });
  });
}
