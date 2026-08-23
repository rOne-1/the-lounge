import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/hall_space.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/search_screen.dart';
import 'package:the_lounge/widgets/media_image.dart';

class _DynamicFilterRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async {
    if (params.genreId == 28) {
      return [
        const MediaItem(
          id: 'action-movie-1',
          title: 'Action Explosion',
          type: MediaType.movie,
          rating: 8.5,
          overview: 'Fast-paced action',
          genres: ['Action'],
        ),
      ];
    }
    if (params.originalLanguage == 'ja') {
      return [
        const MediaItem(
          id: 'japanese-movie-1',
          title: 'Spirited Away',
          type: MediaType.movie,
          rating: 8.6,
          overview: 'Anime masterpiece',
          genres: ['Animation'],
        ),
      ];
    }
    return [
      const MediaItem(
        id: 'default-movie-1',
        title: 'Default Discovery',
        type: MediaType.movie,
        rating: 7.8,
        overview: 'Default discovery title',
        genres: ['Drama'],
      ),
    ];
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'changing discoverFilterProvider dynamically reloads grid without app restart',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(_DynamicFilterRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    List<String> displayedIds() => tester
        .widgetList<MediaImage>(find.byType(MediaImage))
        .map((w) => w.item!.id)
        .toList();

    // Initial grid state shows default movie
    expect(displayedIds(), ['default-movie-1']);

    // Dynamically update discover filters (e.g. genre filter)
    container
        .read(discoverFilterProvider.notifier)
        .setGenre(genreId: 28, genreName: 'Action');

    await tester.pumpAndSettle();

    // Grid should now dynamically display the action movie instead of default movie
    expect(displayedIds(), ['action-movie-1']);

    // Reset filters
    container.read(discoverFilterProvider.notifier).resetFilters();
    await tester.pumpAndSettle();

    expect(displayedIds(), ['default-movie-1']);
  });

  testWidgets(
      'changing active hall lockedLanguageCode dynamically refreshes discover grid',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(_DynamicFilterRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    List<String> displayedIds() => tester
        .widgetList<MediaImage>(find.byType(MediaImage))
        .map((w) => w.item!.id)
        .toList();

    expect(displayedIds(), ['default-movie-1']);

    // Switch active hall to a hall configured with locked language 'ja'
    final jaHall = HallSpace.defaultMezzanineHall().copyWith(
      id: 'custom_1',
      lockedLanguageCode: 'ja',
      lockedLanguageName: 'Japanese',
    );
    await container.read(hallProvider.notifier).applyImportedHalls([
      HallSpace.defaultGrandHall(),
      jaHall,
      HallSpace.defaultPrivateScreeningHall(),
    ]);
    await container.read(hallProvider.notifier).switchHall('custom_1');

    await tester.pumpAndSettle();

    expect(displayedIds(), ['japanese-movie-1']);
  });
}
