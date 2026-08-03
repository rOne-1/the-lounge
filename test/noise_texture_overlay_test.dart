import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/widgets/noise_texture_overlay.dart';

void main() {
  group('NoiseTextureOverlay / AppNoiseTexture Tests', () {
    testWidgets('AppNoiseTexture renders correctly within shell stack',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Text('Background Screen Content'),
                Positioned.fill(
                  child: AppNoiseTexture(
                    opacity: 0.04,
                    blendMode: BlendMode.overlay,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Background Screen Content'), findsOneWidget);
      expect(find.byType(AppNoiseTexture), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('AppNoiseTexture wraps painter in IgnorePointer to allow user interaction',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GestureDetector(
                  onTap: () => tapped = true,
                  child: const Text('Interactive Button'),
                ),
                const Positioned.fill(
                  child: AppNoiseTexture(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Interactive Button'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('NoiseTextureOverlay typedef works identically',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoiseTextureOverlay(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NoiseTextureOverlay), findsOneWidget);
    });
  });
}
