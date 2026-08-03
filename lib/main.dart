import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'providers/ambiance_provider.dart';
import 'screens/shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

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
      theme: ambiance == AmbianceType.screeningRoom
          ? AppThemes.screeningRoomTheme
          : AppThemes.readingRoomTheme,
      home: ShellScreen(enableAnimation: enableAnimation),
    );
  }
}
