import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/reading_room_theme.dart';
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

    test('readingRoomBackground gradient transitions to rrAmbianceColors.base', () {
      final decoration = readingRoomBackground();
      expect(decoration.color, equals(rrAmbianceColors.base));
      expect(decoration.gradient, isA<RadialGradient>());

      final gradient = decoration.gradient as RadialGradient;
      expect(gradient.colors[0], equals(const Color(0xFFE8DCC8)));
      expect(gradient.colors[1], equals(rrAmbianceColors.base));
      expect(gradient.colors.contains(Colors.transparent), isFalse);
    });

    testWidgets('ThemeData scaffoldBackgroundColor matches base colors', (WidgetTester tester) async {
      final theme = screeningRoomTheme.themeData;
      final rrTheme = readingRoomTheme.themeData;
      expect(theme.scaffoldBackgroundColor, equals(srAmbianceColors.base));
      expect(rrTheme.scaffoldBackgroundColor, equals(rrAmbianceColors.base));
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
}
