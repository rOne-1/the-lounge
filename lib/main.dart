import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'providers/ambiance_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/repository_provider.dart';
import 'screens/splash_screen.dart';
import 'services/crash_reporting_service.dart';
import 'themes/screening_room_theme.dart';
import 'widgets/fallback_widgets.dart';
import 'widgets/floating_navigation_capsule.dart';

/// Shared with [GlobalCapsuleLayer]/[FloatingNavigationCapsule]: the capsule
/// is drawn in [MyApp]'s `builder` as a Stack sibling of `child` (the actual
/// routed Navigator), not a descendant of it, so `Navigator.of(context)`
/// from inside the capsule has no Navigator ancestor to find. This key gives
/// it a working handle to the real Navigator regardless of tree position.
final rootNavigatorKey = GlobalKey<NavigatorState>();

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
    final routeObserver = ref.watch(loungeRouteObserverProvider);

    return MaterialApp(
      title: 'The Lounge',
      debugShowCheckedModeBanner: false,
      theme: ambiance.themeData,
      navigatorKey: rootNavigatorKey,
      navigatorObservers: [routeObserver],
      builder: (context, child) {
        return AnimatedTheme(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          data: ambiance.themeData,
          child: Stack(
            children: [
              child ?? const SizedBox(),
              GlobalCapsuleLayer(
                enableAnimation: enableAnimation,
              ),
            ],
          ),
        );
      },
      home: shouldShowConfigurationError
          ? const ConfigurationErrorScreen()
          : SplashScreen(enableAnimation: enableAnimation),
    );
  }
}

/// Hosts the single [FloatingNavigationCapsule] instance for the whole app,
/// positioned as a Stack sibling of the routed [Navigator] in [MyApp]'s
/// `builder` so it draws above every pushed screen. Public (not `_`-private)
/// so widget tests can reconstruct the same builder-sibling tree shape that
/// production actually uses -- see floating_navigation_capsule_test.dart.
///
/// Hidden only when truly sitting at the Lounge landing screen with
/// nothing pushed on top (`routeDepth <= 0 && currentTab == lounge`).
/// `routeDepth` alone isn't enough: Lobby/Discover/Search/Calendar are tab
/// switches within ShellScreen's IndexedStack, not Navigator pushes, so they
/// sit at routeDepth 0 too and still need the capsule shown.
class GlobalCapsuleLayer extends ConsumerWidget {
  final bool? enableAnimation;

  const GlobalCapsuleLayer({super.key, this.enableAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeDepth = ref.watch(routeDepthProvider);
    final currentTab = ref.watch(navigationProvider).currentTab;
    final shouldShowConfigurationError =
        ref.watch(shouldShowConfigurationErrorProvider);

    if (shouldShowConfigurationError ||
        (routeDepth <= 0 && currentTab == AppTab.lounge)) {
      return const SizedBox.shrink();
    }

    return FloatingNavigationCapsule(
      enableAnimation: enableAnimation,
      navigatorKey: rootNavigatorKey,
    );
  }
}
