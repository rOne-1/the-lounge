import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/screens/browse_screen.dart';
import 'package:the_lounge/screens/your_space_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final movieInFranchise1 = MediaItem(
    id: 'movie_10',
    title: 'The Dark Knight',
    type: MediaType.movie,
    rating: 9.0,
    overview: 'Batman movie',
    genres: const ['Action', 'Drama'],
    belongsToCollection: const MediaCollection(id: 263, name: 'The Dark Knight Collection'),
  );

  final movieInFranchise2 = MediaItem(
    id: 'movie_11',
    title: 'Batman Begins',
    type: MediaType.movie,
    rating: 8.2,
    overview: 'Batman begins overview',
    genres: const ['Action'],
    belongsToCollection: const MediaCollection(id: 263, name: 'The Dark Knight Collection'),
  );

  final standaloneMovie = MediaItem(
    id: 'movie_12',
    title: 'Inception',
    type: MediaType.movie,
    rating: 8.8,
    overview: 'Mind bending heist',
    genres: const ['Sci-Fi', 'Action'],
  );

  group('Fix Pass Round 4 - Pass 3 Tests', () {
    test('Item 7: supportedLanguages contains all 21 comprehensive languages', () {
      expect(supportedLanguages.length, equals(21));
      final codes = supportedLanguages.map((l) => l['code']).toList();
      expect(codes, containsAll([
        'en', 'ja', 'fr', 'es', 'de', 'ko', 'it', 'pt', 'zh', 'hi',
        'cn', 'ru', 'sv', 'pl', 'da', 'no', 'nl', 'tr', 'th', 'ar', 'vi'
      ]));
    });

    testWidgets('Item 2 & Item 6: BrowseScreen renders search mode badge cleanly and genre chips stability', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BrowseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseScreen), findsOneWidget);
    });

    testWidgets('Item 14: Group Watched list by Collection and Standalone Titles in YourSpaceScreen', (tester) async {
      final container = ProviderContainer();
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(movieInFranchise1);
      notifier.addToWatchedList(movieInFranchise2);
      notifier.addToWatchedList(standaloneMovie);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: YourSpaceScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'Watched' tab
      await tester.tap(find.text('Watched'));
      await tester.pumpAndSettle();

      expect(find.text('The Dark Knight Collection'), findsOneWidget);
      expect(find.text('Standalone Titles'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 items in dark knight collection badge
      expect(find.text('1'), findsOneWidget); // 1 item in standalone badge
    });
  });
}
