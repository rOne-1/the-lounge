import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/constants.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/widgets/media_card.dart';
import 'package:the_lounge/widgets/pressable_scale.dart';
import 'package:the_lounge/widgets/status_pulse_ring.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final ratedItem = MediaItem(
    id: 'movie-101',
    title: 'Inception',
    type: MediaType.movie,
    rating: 8.8,
    overview: 'A thief who steals corporate secrets...',
    genres: const ['Action', 'Sci-Fi'],
    releaseOrAirDate: DateTime(2010),
  );

  final unratedItem = MediaItem(
    id: 'movie-202',
    title: 'Untitled Project',
    type: MediaType.movie,
    rating: 0,
    overview: '',
    genres: const [],
    releaseOrAirDate: DateTime(2024),
  );

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  Widget wrapWatchlisted(Widget child, MediaItem watchlistedItem) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        mediaProvider.overrideWith(() => _WatchlistedMediaNotifier(watchlistedItem)),
      ],
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('MediaCard — canonical card (UC-1)', () {
    testWidgets('wraps its poster in a house-spring PressableScale', (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(item: ratedItem, isDark: true, width: 120, height: 180, onTap: () {}),
      ));

      final pressable = tester.widget<PressableScale>(find.byType(PressableScale));
      expect(pressable.curve, equals(AppPhysics.houseSpringCurve));
      expect(pressable.releaseDuration, equals(AppPhysics.houseSpringDuration));
      expect(pressable.pressDuration, equals(const Duration(milliseconds: 120)));
    });

    testWidgets('custom onTap fires instead of the default open-container navigation', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        MediaCard(item: ratedItem, isDark: true, width: 120, height: 180, onTap: () => tapped = true),
      ));

      await tester.tap(find.byType(MediaCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows the starRating rating badge for a rated item', (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(item: ratedItem, isDark: true, width: 120, height: 180, onTap: () {}),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('8.8'), findsOneWidget);

      final starIcon = tester.widget<Icon>(find.byIcon(Icons.star));
      final context = tester.element(find.byType(MediaCard));
      expect(starIcon.color, equals(context.ambianceColors.starRating));
    });

    testWidgets('hides the rating badge for an unrated item', (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(item: unratedItem, isDark: true, width: 120, height: 180, onTap: () {}),
      ));

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('showRatingBadge: false suppresses the badge even for a rated item', (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(
          item: ratedItem,
          isDark: true,
          width: 120,
          height: 180,
          onTap: () {},
          showRatingBadge: false,
        ),
      ));

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('shows a pulse-ringed status indicator when the item is watchlisted', (tester) async {
      await tester.pumpWidget(wrapWatchlisted(
        MediaCard(item: ratedItem, isDark: true, width: 120, height: 180, onTap: () {}),
        ratedItem,
      ));
      await tester.pump();

      expect(find.byType(StatusPulseRing), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets('no status indicator when the item has no tracked status', (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(item: ratedItem, isDark: true, width: 120, height: 180, onTap: () {}),
      ));

      expect(find.byType(StatusPulseRing), findsNothing);
    });

    testWidgets('showStatusIndicator: false suppresses the indicator even when tracked', (tester) async {
      await tester.pumpWidget(wrapWatchlisted(
        MediaCard(
          item: ratedItem,
          isDark: true,
          width: 120,
          height: 180,
          onTap: () {},
          showStatusIndicator: false,
        ),
        ratedItem,
      ));
      await tester.pump();

      expect(find.byType(StatusPulseRing), findsNothing);
    });

    testWidgets('renders title and subtitle when requested', (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(
          item: ratedItem,
          isDark: true,
          width: 120,
          height: 180,
          onTap: () {},
          showTitle: true,
          showSubtitle: true,
        ),
      ));

      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
    });
  });
}

class _WatchlistedMediaNotifier extends MediaNotifier {
  final MediaItem item;
  _WatchlistedMediaNotifier(this.item);

  @override
  MediaState build() {
    final base = super.build();
    return base.copyWith(watchlist: {item.id: item});
  }
}
