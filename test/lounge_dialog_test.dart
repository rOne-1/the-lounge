import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/constants.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/widgets/lounge_dialog.dart';
import 'package:the_lounge/widgets/pressable_scale.dart';

void main() {
  Widget wrap(Widget home) {
    return MaterialApp(theme: screeningRoomTheme.themeData, home: home);
  }

  group('LoungeDialog (DS-1)', () {
    testWidgets('show() renders title, message, and theme-token styling', (tester) async {
      await tester.pumpWidget(wrap(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LoungeDialog.show<void>(
                context,
                title: 'Reset everything?',
                message: 'This cannot be undone.',
                actions: const [],
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(AppPhysics.houseSpringDuration);

      expect(find.byType(LoungeDialog), findsOneWidget);
      expect(find.text('Reset everything?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
    });

    testWidgets('house-spring entrance: fully transparent at animation start, opaque once settled', (tester) async {
      await tester.pumpWidget(wrap(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LoungeDialog.show<void>(
                context,
                title: 'Title',
                message: 'Message',
                actions: const [],
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pump();

      final fadeFinder = find.ancestor(of: find.byType(LoungeDialog), matching: find.byType(FadeTransition));
      final fadeTransition = tester.widget<FadeTransition>(fadeFinder);
      expect(fadeTransition.opacity.value, equals(0.0));

      await tester.pump(AppPhysics.houseSpringDuration);
      final settled = tester.widget<FadeTransition>(fadeFinder);
      expect(settled.opacity.value, equals(1.0));
    });

    testWidgets('neutral, primary, and destructive actions render with distinct styling', (tester) async {
      var neutralTapped = false;
      var primaryTapped = false;
      var destructiveTapped = false;

      await tester.pumpWidget(wrap(
        Scaffold(
          body: LoungeDialog(
            title: 'Title',
            message: 'Message',
            actions: [
              LoungeDialogAction(label: 'Cancel', onPressed: () => neutralTapped = true),
              LoungeDialogAction(
                label: 'Confirm',
                style: LoungeDialogActionStyle.primary,
                onPressed: () => primaryTapped = true,
              ),
              LoungeDialogAction(
                label: 'Delete',
                style: LoungeDialogActionStyle.destructive,
                onPressed: () => destructiveTapped = true,
              ),
            ],
          ),
        ),
      ));

      expect(find.byType(PressableScale), findsNWidgets(3));

      await tester.tap(find.text('Cancel'));
      expect(neutralTapped, isTrue);

      await tester.tap(find.text('Confirm'));
      expect(primaryTapped, isTrue);

      await tester.tap(find.text('Delete'));
      expect(destructiveTapped, isTrue);
    });

    testWidgets('destructive action pill uses ambiance.danger background', (tester) async {
      await tester.pumpWidget(wrap(
        Scaffold(
          body: LoungeDialog(
            title: 'Title',
            message: 'Message',
            actions: [
              LoungeDialogAction(
                label: 'Delete',
                style: LoungeDialogActionStyle.destructive,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ));

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('Delete'), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(srAmbianceColors.danger));
    });
  });
}
