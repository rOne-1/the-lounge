import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/splash_screen.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SplashScreen renders Screening Room identity and typography',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          enableAnimation: true,
          duration: Duration(seconds: 10),
        ),
      ),
    );

    expect(find.text('THE LOUNGE'), findsOneWidget);
    expect(find.text('CINEMATIC SCREENING ROOM'), findsOneWidget);
    expect(find.byIcon(Icons.local_movies_rounded), findsOneWidget);
  });

  testWidgets('SplashScreen transitions to custom targetScreen after duration',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          enableAnimation: true,
          duration: Duration(milliseconds: 500),
          targetScreen: Scaffold(body: Text('Target Screen')),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Target Screen'), findsOneWidget);
  });

  testWidgets('SplashScreen with enableAnimation: false transitions instantly to ShellScreen',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final mockRepo = MockMovieRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: SplashScreen(enableAnimation: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ShellScreen), findsOneWidget);
  });
}
