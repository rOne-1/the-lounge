import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/widgets/pick_for_me_card.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/screens/detail_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final movie1 = MediaItem(
    id: 'movie-1',
    title: 'Inception',
    type: MediaType.movie,
    rating: 8.8,
    overview: 'Inception overview',
    tagline: 'Your mind is the scene of the crime',
    genres: const ['Sci-Fi', 'Action'],
  );

  final movie2 = MediaItem(
    id: 'movie-2',
    title: 'Interstellar',
    type: MediaType.movie,
    rating: 8.6,
    overview: 'Interstellar overview',
    tagline: 'Mankind was born on Earth. It was never meant to die here.',
    genres: const ['Sci-Fi', 'Drama'],
  );

  final maybeMovie = MediaItem(
    id: 'movie-3',
    title: 'Oppenheimer',
    type: MediaType.movie,
    rating: 8.9,
    overview: 'Oppenheimer overview',
    tagline: 'The world changes forever',
    genres: const ['Drama', 'History'],
  );

  testWidgets('PickForMeCard displays empty state when watchlist is empty', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PickForMeCard(enableAnimation: false),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PICK FOR ME'), findsOneWidget);
    expect(
      find.text('Decide from your Watchlist — We picked this for you.'),
      findsOneWidget,
    );
    expect(
      find.text('Your movie watchlist is empty. Save titles to enable Pick for me!'),
      findsOneWidget,
    );
    expect(find.text('Discover Movies'), findsOneWidget);

    // Tap Discover Movies button
    await tester.tap(find.text('Discover Movies'));
    await tester.pumpAndSettle();

    expect(container.read(navigationProvider).currentTab, equals(AppTab.discover));
  });

  testWidgets('PickForMeCard picks movie from active watchlist', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mediaProvider.notifier).addToWatchlist(movie1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PickForMeCard(enableAnimation: false),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
    expect(find.text('"Your mind is the scene of the crime"'), findsOneWidget);
    expect(find.text('8.8'), findsOneWidget);
    expect(find.text('Re-roll'), findsOneWidget);
  });

  testWidgets('PickForMeCard falls back to maybeList when watchlist is empty', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mediaProvider.notifier).addToMaybeList(maybeMovie);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PickForMeCard(enableAnimation: false),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Oppenheimer'), findsOneWidget);
    expect(find.text('"The world changes forever"'), findsOneWidget);
  });

  testWidgets('PickForMeCard Re-roll button switches pick when multiple movies exist', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mediaProvider.notifier).addToWatchlist(movie1);
    container.read(mediaProvider.notifier).addToWatchlist(movie2);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PickForMeCard(enableAnimation: false),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final hasInception = find.text('Inception').evaluate().isNotEmpty;
    final initialTitle = hasInception ? 'Inception' : 'Interstellar';
    final otherTitle = hasInception ? 'Interstellar' : 'Inception';

    expect(find.text(initialTitle), findsOneWidget);

    // Tap Re-roll
    await tester.tap(find.text('Re-roll'));
    await tester.pumpAndSettle();

    expect(find.text(otherTitle), findsOneWidget);
  });

  testWidgets('Tapping movie in PickForMeCard opens DetailScreen', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mediaProvider.notifier).addToWatchlist(movie1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PickForMeCard(enableAnimation: false),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Inception'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
  });
}
