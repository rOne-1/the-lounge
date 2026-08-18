import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/widgets/lounge_doorway_emblem.dart';

void main() {
  testWidgets('LoungeDoorwayEmblem renders without layout overflow across various sizes',
      (tester) async {
    for (final size in [60.0, 100.0, 140.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LoungeDoorwayEmblem(size: size),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoungeDoorwayEmblem), findsOneWidget);
      final renderBox = tester.renderObject<RenderBox>(find.byType(LoungeDoorwayEmblem));
      expect(renderBox.size.width, size);
      expect(renderBox.size.height, size);
    }
  });
}
