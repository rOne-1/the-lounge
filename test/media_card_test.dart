import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/constants.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/motion_intensity_provider.dart';
import 'package:the_lounge/widgets/media_card.dart';
import 'package:the_lounge/widgets/status_pulse_ring.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart'
    show HouseSpring, PressableScale, Tilt3DCard;

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
        mediaProvider
            .overrideWith(() => _WatchlistedMediaNotifier(watchlistedItem)),
      ],
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  Widget wrapWithMotionIntensity(Widget child, MotionIntensity intensity) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        motionIntensityProvider
            .overrideWith(() => _FixedMotionIntensityNotifier(intensity)),
      ],
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('MediaCard — canonical card (UC-1)', () {
    testWidgets('wraps its poster in a house-spring PressableScale',
        (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(
            item: ratedItem,
            isDark: true,
            width: 120,
            height: 180,
            onTap: () {}),
      ));

      final pressable =
          tester.widget<PressableScale>(find.byType(PressableScale));
      expect(pressable.curve, equals(HouseSpring.curve));
      expect(pressable.releaseDuration, equals(HouseSpring.duration));
      expect(
          pressable.pressDuration, equals(const Duration(milliseconds: 120)));
    });

    testWidgets(
        'custom onTap fires instead of the default open-container navigation',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        MediaCard(
            item: ratedItem,
            isDark: true,
            width: 120,
            height: 180,
            onTap: () => tapped = true),
      ));

      await tester.tap(find.byType(MediaCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows the starRating rating badge for a rated item',
        (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(
            item: ratedItem,
            isDark: true,
            width: 120,
            height: 180,
            onTap: () {}),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('8.8'), findsOneWidget);

      final starIcon = tester.widget<Icon>(find.byIcon(Icons.star));
      final context = tester.element(find.byType(MediaCard));
      expect(starIcon.color, equals(context.ambianceColors.starRating));
    });

    testWidgets('hides the rating badge for an unrated item', (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(
            item: unratedItem,
            isDark: true,
            width: 120,
            height: 180,
            onTap: () {}),
      ));

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets(
        'showRatingBadge: false suppresses the badge even for a rated item',
        (tester) async {
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

    testWidgets(
        'shows a pulse-ringed status indicator when the item is watchlisted',
        (tester) async {
      await tester.pumpWidget(wrapWatchlisted(
        MediaCard(
            item: ratedItem,
            isDark: true,
            width: 120,
            height: 180,
            onTap: () {}),
        ratedItem,
      ));
      await tester.pump();

      expect(find.byType(StatusPulseRing), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets('no status indicator when the item has no tracked status',
        (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(
            item: ratedItem,
            isDark: true,
            width: 120,
            height: 180,
            onTap: () {}),
      ));

      expect(find.byType(StatusPulseRing), findsNothing);
    });

    testWidgets(
        'showStatusIndicator: false suppresses the indicator even when tracked',
        (tester) async {
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

    testWidgets(
        'BETA3-A11Y-2: announces title, year, medium type, rating, and status as one label',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrapWatchlisted(
        MediaCard(
            item: ratedItem,
            isDark: true,
            width: 120,
            height: 180,
            onTap: () {}),
        ratedItem,
      ));
      await tester.pump();

      final semantics =
          tester.getSemantics(find.bySemanticsLabel(RegExp('Inception')));
      expect(semantics.label, contains('Inception'));
      expect(semantics.label, contains('2010'));
      expect(semantics.label, contains('Movie'));
      expect(semantics.label, contains('rated 8.8'));
      expect(semantics.label, contains('Watchlist'));

      handle.dispose();
    });

    testWidgets(
        'item 1: shows a pending/confirming indicator for an unconfirmed Watched TV show',
        (tester) async {
      final tvItem = MediaItem(
        id: 'tv-pending',
        title: 'Pending Show',
        type: MediaType.tv,
        rating: 7.5,
        overview: '',
        genres: const [],
      );
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          mediaProvider
              .overrideWith(() => _PendingWatchedMediaNotifier(tvItem)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: MediaCard(
                  item: tvItem,
                  isDark: true,
                  width: 120,
                  height: 180,
                  onTap: () {}),
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      final semantics =
          tester.getSemantics(find.bySemanticsLabel(RegExp('Pending Show')));
      expect(semantics.label, contains('Watched, confirming'));

      handle.dispose();
    });
  });

  group('CRAFT-TILT-1: MediaCard tilt/glare, gated by MotionIntensity', () {
    testWidgets('wraps its poster in a Tilt3DCard', (tester) async {
      await tester.pumpWidget(wrap(
        MediaCard(item: ratedItem, isDark: true, width: 120, height: 180),
      ));

      expect(find.byType(Tilt3DCard), findsOneWidget);
      // PressableScale must still be nested inside it, not replaced.
      expect(find.byType(PressableScale), findsOneWidget);
    });

    testWidgets('tap still opens/fires through the nested PressableScale',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        MediaCard(
          item: ratedItem,
          isDark: true,
          width: 120,
          height: 180,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(MediaCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('MotionIntensity.full enables tilt and glare at full magnitude',
        (tester) async {
      await tester.pumpWidget(wrapWithMotionIntensity(
        MediaCard(item: ratedItem, isDark: true, width: 120, height: 180),
        MotionIntensity.full,
      ));

      final tilt = tester.widget<Tilt3DCard>(find.byType(Tilt3DCard));
      expect(tilt.enableTilt, isTrue);
      expect(tilt.enableGlare, isTrue);
      expect(tilt.maxTiltAngle, 0.12);
      expect(tilt.glareIntensity, 0.18);
    });

    testWidgets(
        'MotionIntensity.reduced scales tilt/glare down without disabling them',
        (tester) async {
      await tester.pumpWidget(wrapWithMotionIntensity(
        MediaCard(item: ratedItem, isDark: true, width: 120, height: 180),
        MotionIntensity.reduced,
      ));

      final tilt = tester.widget<Tilt3DCard>(find.byType(Tilt3DCard));
      expect(tilt.enableTilt, isTrue);
      expect(tilt.enableGlare, isTrue);
      expect(tilt.maxTiltAngle, lessThan(0.12));
      expect(tilt.maxTiltAngle, greaterThan(0.0));
      expect(tilt.glareIntensity, lessThan(0.18));
      expect(tilt.glareIntensity, greaterThan(0.0));
    });

    testWidgets('MotionIntensity.off disables tilt and glare entirely',
        (tester) async {
      await tester.pumpWidget(wrapWithMotionIntensity(
        MediaCard(item: ratedItem, isDark: true, width: 120, height: 180),
        MotionIntensity.off,
      ));

      final tilt = tester.widget<Tilt3DCard>(find.byType(Tilt3DCard));
      expect(tilt.enableTilt, isFalse);
      expect(tilt.enableGlare, isFalse);
      expect(tilt.maxTiltAngle, 0.0);
      expect(tilt.glareIntensity, 0.0);
    });

    testWidgets('MotionIntensity.off still allows tap through', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWithMotionIntensity(
        MediaCard(
          item: ratedItem,
          isDark: true,
          width: 120,
          height: 180,
          onTap: () => tapped = true,
        ),
        MotionIntensity.off,
      ));

      await tester.tap(find.byType(MediaCard));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}

class _FixedMotionIntensityNotifier extends MotionIntensityNotifier {
  final MotionIntensity fixed;
  _FixedMotionIntensityNotifier(this.fixed);

  @override
  MotionIntensity build() => fixed;
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

class _PendingWatchedMediaNotifier extends MediaNotifier {
  final MediaItem item;
  _PendingWatchedMediaNotifier(this.item);

  @override
  MediaState build() {
    final base = super.build();
    return base.copyWith(
      watchedList: {item.id: item},
      pendingWatchConfirmation: {item.id},
    );
  }
}
