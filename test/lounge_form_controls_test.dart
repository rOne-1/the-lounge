import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/constants.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/widgets/lounge_slider.dart';
import 'package:the_lounge/widgets/lounge_dropdown.dart';

void main() {
  Widget wrap(Widget home) {
    return MaterialApp(theme: screeningRoomTheme.themeData, home: Scaffold(body: Center(child: home)));
  }

  group('LoungeSlider (FC-1)', () {
    testWidgets('dragging the slider reports a changed value', (tester) async {
      double? lastValue;
      await tester.pumpWidget(wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 300,
              child: LoungeSlider(
                value: 0.0,
                min: 0.0,
                max: 10.0,
                onChanged: (v) => lastValue = v,
              ),
            );
          },
        ),
      ));

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      final center = tester.getCenter(sliderFinder);
      await tester.tapAt(Offset(center.dx + 80, center.dy));
      await tester.pump();

      expect(lastValue, isNotNull);
      expect(lastValue, greaterThan(0.0));
    });

    testWidgets('uses ambiance.acc for the active track', (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 300,
          child: LoungeSlider(value: 5.0, min: 0.0, max: 10.0, onChanged: (_) {}),
        ),
      ));

      final sliderTheme = tester.widget<SliderTheme>(find.byType(SliderTheme).first);
      expect(sliderTheme.data.activeTrackColor, equals(srAmbianceColors.acc));
      expect(sliderTheme.data.inactiveTrackColor, equals(srAmbianceColors.card2));
    });
  });

  group('LoungeRangeSlider (FC-1)', () {
    testWidgets('renders a RangeSlider with the given values', (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 300,
          child: LoungeRangeSlider(
            values: const RangeValues(0, 240),
            min: 0,
            max: 240,
            onChanged: (_) {},
          ),
        ),
      ));

      expect(find.byType(RangeSlider), findsOneWidget);
      final widget = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(widget.values, equals(const RangeValues(0, 240)));
    });
  });

  group('LoungeDropdown (FC-1)', () {
    const items = [
      LoungeDropdownItem<String>(value: 'popularity.desc', label: 'Most Popular'),
      LoungeDropdownItem<String>(value: 'vote_average.desc', label: 'Highest Rated'),
    ];

    testWidgets('shows the selected item label on the trigger', (tester) async {
      await tester.pumpWidget(wrap(
        LoungeDropdown<String>(
          value: 'vote_average.desc',
          items: items,
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Highest Rated'), findsOneWidget);
    });

    testWidgets('tapping the trigger opens a popover and selecting an item fires onChanged', (tester) async {
      String? selected;
      await tester.pumpWidget(wrap(
        LoungeDropdown<String>(
          value: 'popularity.desc',
          items: items,
          onChanged: (v) => selected = v,
        ),
      ));

      expect(find.text('Highest Rated'), findsNothing);

      await tester.tap(find.text('Most Popular'));
      await tester.pump();
      await tester.pump(AppPhysics.houseSpringDuration);

      // Popover now shows both items; tap the not-yet-selected one.
      expect(find.text('Highest Rated'), findsOneWidget);
      await tester.tap(find.text('Highest Rated'));
      await tester.pump();

      expect(selected, equals('vote_average.desc'));
    });

    testWidgets('dense variant renders without a fill/border container', (tester) async {
      await tester.pumpWidget(wrap(
        LoungeDropdown<String>(
          value: 'popularity.desc',
          items: items,
          onChanged: (_) {},
          dense: true,
        ),
      ));

      expect(find.text('Most Popular'), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });
  });
}
