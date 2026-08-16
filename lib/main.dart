import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'providers/ambiance_provider.dart';
import 'providers/repository_provider.dart';
import 'screens/splash_screen.dart';
import 'services/crash_reporting_service.dart';
import 'themes/screening_room_theme.dart';
import 'widgets/fallback_widgets.dart';

void main() async {
  final stopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  // Best-effort default before the persisted ambiance resolves (post-runApp);
  // SplashScreen re-applies the real resolved ambiance's color immediately after.
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: srAmbianceColors.base,
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
    final shouldShowConfigurationError =
        ref.watch(shouldShowConfigurationErrorProvider);

    return MaterialApp(
      title: 'The Lounge',
      debugShowCheckedModeBanner: false,
      theme: ambiance.themeData,
      builder: (context, child) {
        return AnimatedTheme(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          data: ambiance.themeData,
          child: child ?? const SizedBox(),
        );
      },
      home: shouldShowConfigurationError
          ? const ConfigurationErrorScreen()
          : SplashScreen(enableAnimation: enableAnimation),
    );
  }
}
