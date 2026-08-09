import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'providers/ambiance_provider.dart';
import 'screens/splash_screen.dart';
import 'services/crash_reporting_service.dart';

void main() async {
  final stopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF161312),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (stopwatch.isRunning) {
      stopwatch.stop();
      developer.log(
        'First Meaningful Paint rendered in: ${stopwatch.elapsedMilliseconds}ms',
        name: 'main',
      );
      debugPrint(
        '[ColdStart] First Meaningful Paint rendered in ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  });

  final results = await Future.wait([
    dotenv.load(fileName: ".env").catchError((e) {
      developer.log('Dotenv notice: .env file not found or not loaded: $e',
          name: 'main');
    }),
    SharedPreferences.getInstance(),
  ]);

  developer.log('Startup initialization took: ${stopwatch.elapsedMilliseconds}ms',
      name: 'main');

  await CrashReportingService.init();
  final sharedPreferences = results[1] as SharedPreferences;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool? enableAnimation;

  const MyApp({super.key, this.enableAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambiance = ref.watch(ambianceProvider);

    return MaterialApp(
      title: 'The Lounge',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.theme(ambiance),
      home: SplashScreen(enableAnimation: enableAnimation),
    );
  }
}
