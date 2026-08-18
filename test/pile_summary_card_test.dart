import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/widgets/pile_summary_card.dart';
import 'package:the_lounge/widgets/watching_hero_card.dart';
import 'package:the_lounge/constants/app_status_colors.dart';

void main() {
  testWidgets('PileSummaryCard renders labels, status numeral, and responds to tap',
      (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PileSummaryCard(
              label: 'Watched',
              subtitle: '47 titles',
              count: 47,
              icon: Icons.check_circle_rounded,
              statusColor: AppStatusColors.watched,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Watched'), findsOneWidget);
    expect(find.text('47 titles'), findsOneWidget);
    expect(find.text('47'), findsOneWidget);

    await tester.tap(find.text('Watched'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('WatchingHeroCard renders title, count, and responds to tap',
      (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WatchingHeroCard(
              count: 3,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Watching'), findsOneWidget);
    expect(find.text('CONTINUE WATCHING'), findsOneWidget);
    expect(find.text('3 titles in progress'), findsOneWidget);

    await tester.tap(find.text('Watching'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
