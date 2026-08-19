import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/analytics_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('ANLY-PROVIDER-1 / SP-1: idle state has no result and never auto-generates', () {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    // Reading the provider must not trigger generation on its own.
    final state = container.read(analyticsProvider);
    expect(state.result, isNull);
    expect(state.generatedAt, isNull);
    expect(state.isGenerating, isFalse);
    expect(state.error, isNull);
  });

  test('generate() populates result and generatedAt', () async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    const movie = MediaItem(
      id: 'movie_1',
      title: 'A Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
      runtime: 100,
    );
    container.read(mediaProvider.notifier).addToWatchedList(movie);

    await container.read(analyticsProvider.notifier).generate();

    final state = container.read(analyticsProvider);
    expect(state.result, isNotNull);
    expect(state.result!.timeInvestment.movieMinutes, 100);
    expect(state.generatedAt, isNotNull);
    expect(state.isGenerating, isFalse);
    expect(state.error, isNull);
  });

  test('calling generate() again overwrites the previous result', () async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container.read(analyticsProvider.notifier).generate();
    final firstGeneratedAt = container.read(analyticsProvider).generatedAt;

    const movie = MediaItem(
      id: 'movie_1',
      title: 'A Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
      runtime: 90,
    );
    container.read(mediaProvider.notifier).addToWatchedList(movie);
    await container.read(analyticsProvider.notifier).generate();

    final state = container.read(analyticsProvider);
    expect(state.result!.timeInvestment.movieMinutes, 90);
    expect(state.generatedAt, isNotNull);
    expect(firstGeneratedAt, isNotNull);
  });
}
