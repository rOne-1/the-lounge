import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _LogoTestRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;
  _LogoTestRepository(this.items);

  @override
  Future<MediaItem?> getMediaDetails(String id, {String? region}) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const withLogo = MediaItem(
    id: 'movie-logo',
    title: 'Logo Movie',
    type: MediaType.movie,
    rating: 7.5,
    overview: '',
    genres: [],
    logoUrl: 'https://example.com/logo.png',
  );

  const withoutLogo = MediaItem(
    id: 'movie-nologo',
    title: 'No Logo Movie',
    type: MediaType.movie,
    rating: 7.0,
    overview: '',
    genres: [],
  );

  Future<ProviderContainer> pumpDetail(
    WidgetTester tester,
    MediaItem item,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider
            .overrideWithValue(_LogoTestRepository({item.id: item})),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: DetailScreen(id: item.id, initialItem: item)),
      ),
    );
    return container;
  }

  group('CRAFT-LOGO-1: ClearLogo hero title', () {
    testWidgets('a title with logoUrl renders a CachedNetworkImage for it in the hero',
        (tester) async {
      await pumpDetail(tester, withLogo);
      // A single pump (not pumpAndSettle) -- CachedNetworkImage is
      // constructed synchronously with the right URL regardless of
      // whether the (nonexistent, sandboxed) network fetch itself
      // succeeds or fails.
      await tester.pump();

      final logoImages = find.byWidgetPredicate(
        (w) => w is CachedNetworkImage && w.imageUrl == withLogo.logoUrl,
      );
      // 2, not 1: _ClearLogoTitle is shared by both the hero overlay and
      // the (invisible-at-rest, but still built -- Opacity doesn't remove
      // it from the tree) collapsed top-bar title.
      expect(logoImages, findsNWidgets(2));

      // Drain whatever CachedNetworkImage's own error/retry handling
      // scheduled before the test tears down -- otherwise "a Timer is
      // still pending" trips even though it has nothing to do with this
      // test's own assertion above.
      await tester.pumpAndSettle();
    });

    testWidgets('a title without logoUrl falls back to plain styled text, no CachedNetworkImage',
        (tester) async {
      await pumpDetail(tester, withoutLogo);
      await tester.pumpAndSettle();

      expect(find.text(withoutLogo.title), findsAtLeastNWidgets(1));
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    // The errorWidget-triggered fallback (a broken/unreachable logoUrl
    // still ending up as title text, not a blank hero) is not covered
    // here: CachedNetworkImage's real network/cache-retry behavior leaves
    // pending Timers in the test sandbox (no HTTP mocking set up for this
    // suite) regardless of the widget's own logic, making that path
    // reliably testable only with dedicated HTTP-client mocking -- out of
    // scope for this package. The fallback itself is simple, deterministic
    // Dart (setState swapping to _titleText once errorWidget fires),
    // verified by direct code review instead.
  });

  group('CRAFT-LOGO-1: scroll-collapse into the top bar', () {
    testWidgets('the collapsed top-bar title is invisible at rest and fades in on scroll',
        (tester) async {
      await pumpDetail(tester, withoutLogo);
      await tester.pumpAndSettle();

      Opacity findAppBarTitleOpacity() {
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        return appBar.title as Opacity;
      }

      expect(findAppBarTitleOpacity().opacity, 0.0);

      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -300));
      // pumpAndSettle, not a single pump: dragging this far can scroll
      // below-fold sections into view, triggering their own lazily-started
      // fetches -- letting those resolve here avoids leaving a pending
      // Timer when the test tears down.
      await tester.pumpAndSettle();

      expect(findAppBarTitleOpacity().opacity, greaterThan(0.0));
    });
  });
}
