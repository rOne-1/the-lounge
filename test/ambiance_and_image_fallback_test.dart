import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/orchid_bloom_theme.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/widgets/fallback_widgets.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Task 1: Ambiance Background Gradient Tests', () {
    test('screeningRoomBackground gradient transitions to srAmbianceColors.base', () {
      final decoration = screeningRoomBackground();
      expect(decoration.color, equals(srAmbianceColors.base));
      expect(decoration.gradient, isA<RadialGradient>());

      final gradient = decoration.gradient as RadialGradient;
      expect(gradient.colors[0], equals(const Color(0xFF241812)));
      expect(gradient.colors[1], equals(srAmbianceColors.base));
      expect(gradient.colors.contains(Colors.transparent), isFalse);
    });

    test('orchidBloomBackground gradient transitions to obAmbianceColors.base', () {
      final decoration = orchidBloomBackground();
      expect(decoration.color, equals(obAmbianceColors.base));
      expect(decoration.gradient, isA<RadialGradient>());

      final gradient = decoration.gradient as RadialGradient;
      expect(gradient.colors[0], equals(const Color(0xFFE6D9F0)));
      expect(gradient.colors[1], equals(obAmbianceColors.base));
      expect(gradient.colors.contains(Colors.transparent), isFalse);
    });

    testWidgets('ThemeData scaffoldBackgroundColor matches base colors', (WidgetTester tester) async {
      final theme = screeningRoomTheme.themeData;
      final obTheme = orchidBloomTheme.themeData;
      expect(theme.scaffoldBackgroundColor, equals(srAmbianceColors.base));
      expect(obTheme.scaffoldBackgroundColor, equals(obAmbianceColors.base));
    });
  });

  group('Task 2: Robust Media Fallback and Image Rendering Tests', () {
    testWidgets('MediaPosterFallback renders title and movie icon for movies', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 180,
              child: MediaPosterFallback(
                title: 'Test Movie Title',
                type: MediaType.movie,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Movie Title'), findsOneWidget);
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });

    testWidgets('MediaPosterFallback renders title and TV icon for TV shows', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 180,
              child: MediaPosterFallback(
                title: 'Test TV Series',
                type: MediaType.tv,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test TV Series'), findsOneWidget);
      expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
    });

    testWidgets('MediaImage displays fallback widget when posterUrl is null', (WidgetTester tester) async {
      const item = MediaItem(
        id: 'no-poster-1',
        title: 'Movie Without Poster',
        type: MediaType.movie,
        rating: 7.5,
        overview: 'No poster available',
        genres: ['Drama'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 150,
              child: MediaImage(item: item),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MediaPosterFallback), findsOneWidget);
      expect(find.text('Movie Without Poster'), findsOneWidget);
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });

    testWidgets('MediaImage displays fallback widget when imageLoadWillFail is true', (WidgetTester tester) async {
      const item = MediaItem(
        id: 'broken-1',
        title: 'Broken Image Title',
        type: MediaType.movie,
        rating: 6.0,
        overview: 'Broken url',
        genres: ['Comedy'],
        posterUrl: 'https://example.com/broken.jpg',
        imageLoadWillFail: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 150,
              child: MediaImage(item: item),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MediaPosterFallback), findsOneWidget);
      expect(find.text('Broken Image Title'), findsOneWidget);
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });
  });

  group('B4/B11: MediaImage decodes at real on-screen physical size', () {
    const item = MediaItem(
      id: 'sized-1',
      title: 'Sized Poster',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
      posterUrl: 'https://example.com/poster.jpg',
    );

    testWidgets(
        'memCacheWidth scales with bounded constraints x devicePixelRatio, memCacheHeight stays null (IMAGE-1)',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 110,
              height: 155,
              child: MediaImage(item: item),
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.memCacheWidth, equals(220)); // 110 * 2.0
      // IMAGE-1: passing both memCacheWidth and memCacheHeight forces the
      // decoder to resample into that exact box regardless of the source
      // image's real aspect ratio (this is exactly what distorted cast
      // avatars into a square). Only the bounded-width dimension is
      // auto-derived; height is left null so the decoder preserves the
      // source aspect ratio.
      expect(image.memCacheHeight, isNull);
    });

    testWidgets(
        'a square container (e.g. a circular cast avatar) still only derives width, never both (IMAGE-1)',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 60,
              height: 60,
              child: MediaImage(item: item),
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.memCacheWidth, equals(180)); // 60 * 3.0
      expect(image.memCacheHeight, isNull);
    });

    testWidgets('explicit memCacheWidth/Height overrides the auto-computed size',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 110,
              height: 155,
              child: MediaImage(
                item: item,
                memCacheWidth: 800,
                memCacheHeight: 450,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.memCacheWidth, equals(800));
      expect(image.memCacheHeight, equals(450));
    });
  });
}
