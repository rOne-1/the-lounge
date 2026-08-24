// Regression coverage for COLL-REG-1: getCollectionDetails swallows any
// failure into a null return, and a plain (non-autoDispose)
// FutureProvider.family never re-fetches a cached null on its own -- so
// without a retry action, one transient failure permanently "Collection not
// found"s that id for the rest of the app session.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/models/media_collection_detail.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/collection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FlakyOnceRepository extends MockMovieRepository {
  int calls = 0;

  @override
  Future<MediaCollectionDetail?> getCollectionDetails(int collectionId) async {
    calls++;
    if (calls == 1) return null; // simulates the one transient failure
    return MediaCollectionDetail(
      id: collectionId,
      name: 'Recovered Collection',
      overview: 'Loaded on retry.',
      posterUrl: null,
      backdropUrl: null,
      parts: const [],
    );
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'a failed load shows Collection not found with a Retry action that recovers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _FlakyOnceRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CollectionScreen(collectionId: 7)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collection not found.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Collection not found.'), findsNothing);
    expect(find.text('Recovered Collection'), findsOneWidget);
    expect(repo.calls, 2);
  });
}
