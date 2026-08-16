import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/widgets/ambient_glow.dart';
import 'package:the_lounge/widgets/fallback_widgets.dart';
import 'package:the_lounge/widgets/pressable_scale.dart';

void main() {
  Widget wrap(Widget home) {
    return MaterialApp(theme: screeningRoomTheme.themeData, home: Scaffold(body: home));
  }

  group('FullScreenErrorWidget (FS-1)', () {
    testWidgets('shows an ambient glow card with a PressableScale retry button', (tester) async {
      var retried = false;
      await tester.pumpWidget(wrap(
        FullScreenErrorWidget(message: 'Failed to load titles', onRetry: () => retried = true),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AmbientGlowWidget), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Failed to load titles'), findsOneWidget);

      await tester.tap(find.byType(PressableScale).first);
      expect(retried, isTrue);
    });

    testWidgets('routes network-error messages to NoNetworkWidget', (tester) async {
      await tester.pumpWidget(wrap(
        FullScreenErrorWidget(message: 'SocketException: Failed host lookup', onRetry: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(NoNetworkWidget), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);
    });
  });

  group('InlinePartialErrorWidget (FS-1)', () {
    testWidgets('shows an ambient glow strip with a Retry action', (tester) async {
      var retried = false;
      await tester.pumpWidget(wrap(
        InlinePartialErrorWidget(message: 'Failed to load Trending titles', onRetry: () => retried = true),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AmbientGlowWidget), findsOneWidget);
      expect(find.text('Failed to load Trending titles'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('PlaybackUnavailableWidget (FS-1)', () {
    testWidgets('renders Bodoni Moda title and a PressableScale watchlist action', (tester) async {
      var addedToWatchlist = false;
      await tester.pumpWidget(wrap(
        PlaybackUnavailableWidget(
          title: 'Inception',
          onAddWatchlist: () => addedToWatchlist = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('Add to watchlist'), findsOneWidget);

      await tester.tap(find.text('Add to watchlist'));
      expect(addedToWatchlist, isTrue);
    });

    testWidgets('shows a YouTube action when onWatchOnYouTube is provided', (tester) async {
      await tester.pumpWidget(wrap(
        PlaybackUnavailableWidget(
          title: 'Inception',
          onAddWatchlist: () {},
          onWatchOnYouTube: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Watch on YouTube'), findsOneWidget);
    });
  });

  group('No perpetual animation leaks (regression)', () {
    testWidgets('pumpAndSettle resolves for FullScreenErrorWidget without timing out', (tester) async {
      await tester.pumpWidget(wrap(
        FullScreenErrorWidget(message: 'Something broke', onRetry: () {}),
      ));
      // Fails with a pumpAndSettle timeout if AmbientGlowWidget's animation
      // is left running (its default is an infinite repeat).
      await tester.pumpAndSettle();
    });

    testWidgets('pumpAndSettle resolves for InlinePartialErrorWidget without timing out', (tester) async {
      await tester.pumpWidget(wrap(
        InlinePartialErrorWidget(onRetry: () {}),
      ));
      await tester.pumpAndSettle();
    });
  });
}
