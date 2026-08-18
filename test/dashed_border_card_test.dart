import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/widgets/dashed_border_card.dart';

void main() {
  testWidgets('DashedBorderCard renders child and fires onTap callback', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DashedBorderCard(
              onTap: () => tapped = true,
              child: const Text('Dropped Test'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dropped Test'), findsOneWidget);
    await tester.tap(find.text('Dropped Test'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
