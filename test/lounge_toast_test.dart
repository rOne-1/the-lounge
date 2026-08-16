import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/widgets/lounge_toast.dart';

void main() {
  Widget wrap(Widget home) {
    return MaterialApp(theme: screeningRoomTheme.themeData, home: home);
  }

  Future<void> settleToast(WidgetTester tester, {Duration duration = const Duration(seconds: 3)}) async {
    await tester.pump(duration + const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  group('LoungeToast (DS-2)', () {
    testWidgets('shows the message and auto-dismisses after duration', (tester) async {
      await tester.pumpWidget(wrap(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LoungeToast.show(context, 'Added to Watchlist', type: ToastType.success),
              child: const Text('Trigger'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.text('Added to Watchlist'), findsOneWidget);

      await settleToast(tester);

      expect(find.text('Added to Watchlist'), findsNothing);
    });

    testWidgets('renders an action button and fires its callback', (tester) async {
      var actionFired = false;
      await tester.pumpWidget(wrap(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LoungeToast.show(
                context,
                "Trailer playback isn't available",
                duration: const Duration(seconds: 4),
                actionLabel: 'WATCH ON YOUTUBE',
                onAction: () => actionFired = true,
              ),
              child: const Text('Trigger'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.text('WATCH ON YOUTUBE'), findsOneWidget);
      await tester.tap(find.text('WATCH ON YOUTUBE'));
      await tester.pump();

      expect(actionFired, isTrue);

      await settleToast(tester, duration: const Duration(seconds: 4));
    });

    testWidgets('multiple toasts can stack without pending-timer leaks', (tester) async {
      await tester.pumpWidget(wrap(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                LoungeToast.show(context, 'First');
                LoungeToast.show(context, 'Second');
              },
              child: const Text('Trigger'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);

      await settleToast(tester);

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsNothing);
    });
  });
}
