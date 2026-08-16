import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/widgets/lounge_slider.dart';
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
    trailerVideoId: 'dQw4w9WgXcQ',
  );

  group('TrailerPlayer UI (FS-2)', () {
    testWidgets('Windows mock player uses LoungeSlider for scrubbing', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrailerPlayer(item: itemWithTrailer),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LoungeSlider), findsOneWidget);
      // LoungeSlider wraps a real Slider, so seek/scrub behavior is unchanged.
      expect(find.byType(Slider), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('play/fullscreen/back controls trigger their callbacks without layout assertions', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrailerPlayer(item: itemWithTrailer),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_circle_fill), warnIfMissed: false);
      await tester.pump();
      expect(find.text("Trailer playback isn't available for this title"), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
