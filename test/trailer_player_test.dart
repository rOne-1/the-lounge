import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/widgets/trailer_player.dart';

void main() {
  const itemWithTrailer = MediaItem(
    id: '123',
    title: 'Test Movie',
    type: MediaType.movie,
    rating: 8.5,
    overview: 'A great movie test overview',
    genres: ['Action', 'Sci-Fi'],
    hasTrailer: true,
  );

  const itemWithoutTrailer = MediaItem(
    id: '456',
    title: 'No Trailer Movie',
    type: MediaType.movie,
    rating: 7.0,
    overview: 'A movie without a trailer',
    genres: ['Drama'],
    hasTrailer: false,
  );

  group('TrailerPlayer Windows mock tests', () {
    testWidgets('shows playback unavailable widget when hasTrailer is false',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrailerPlayer(item: itemWithoutTrailer),
          ),
        ),
      );

      expect(find.text('No Trailer Movie'), findsOneWidget);
      expect(
        find.text('This title is not available for playback right now.'),
        findsOneWidget,
      );
      expect(find.text('Add to watchlist'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
        'Windows mock player displays controls and shows feedback on button clicks',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrailerPlayer(item: itemWithTrailer),
          ),
        ),
      );

      // Verify Windows simulated player components
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('2:30'), findsOneWidget);

      // Tap center play button
      await tester.tap(find.byIcon(Icons.play_circle_fill));
      await tester.pump();

      expect(
        find.text("Trailer playback isn't available on Windows yet."),
        findsOneWidget,
      );

      // Tap bottom control bar play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(
        find.text("Trailer playback isn't available on Windows yet."),
        findsOneWidget,
      );

      // Tap fullscreen button
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pump();

      expect(
        find.text("Trailer playback isn't available on Windows yet."),
        findsOneWidget,
      );

      // Dismiss snackbars and wait for all animations/timers to complete
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
          .clearSnackBars();
      await tester.pumpAndSettle();

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Slider is interactive and updates position/duration',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrailerPlayer(item: itemWithTrailer),
          ),
        ),
      );

      expect(find.text('0:00'), findsOneWidget);

      // Drag the slider
      final sliderFinder = find.byType(Slider);
      final center = tester.getCenter(sliderFinder);
      await tester.tapAt(center);
      await tester.pump();

      // Time should be updated to around 1:15 (half of 2:30)
      expect(find.text('0:00'), findsNothing);
      expect(find.text('1:15'), findsOneWidget);

      // Feedback should also be shown
      expect(
        find.text("Trailer playback isn't available on Windows yet."),
        findsOneWidget,
      );

      // Dismiss snackbars and wait for all animations/timers to complete
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
          .clearSnackBars();
      await tester.pumpAndSettle();

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
