import re

def update_ambiance_provider():
    with open('lib/providers/ambiance_provider.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    content = content.replace('AmbianceType', 'AppTheme')

    build_code = '''  @override
  AppTheme build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final storedValue = prefs.getString(_ambianceKey);

    if (storedValue != null) {
      String id = storedValue;
      if (id == 'screeningRoom') id = 'screening_room';
      if (id == 'readingRoom') id = 'reading_room';
      if (id == 'violetDusk') id = 'violet_dusk';
      return getThemeById(id);
    }

    return allThemes.first;
  }'''
    content = re.sub(r'  @override\n  AppTheme build\(\) \{.*?\n  \}', build_code, content, flags=re.DOTALL)

    toggle_code = '''  Future<void> toggleAmbiance() async {
    final currentIndex = allThemes.indexWhere((t) => t.id == state.id);
    final nextIndex = (currentIndex + 1) % allThemes.length;
    final newAmbiance = allThemes[nextIndex];

    state = newAmbiance;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_ambianceKey, newAmbiance.id);
  }'''
    content = re.sub(r'  Future<void> toggleAmbiance\(\) async \{.*?\n  \}', toggle_code, content, flags=re.DOTALL)

    set_code = '''  Future<void> setAmbiance(AppTheme ambiance) async {
    state = ambiance;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_ambianceKey, ambiance.id);
  }'''
    content = re.sub(r'  Future<void> setAmbiance\(AppTheme ambiance\) async \{.*?\n  \}', set_code, content, flags=re.DOTALL)

    with open('lib/providers/ambiance_provider.dart', 'w', encoding='utf-8') as f:
        f.write(content)

def update_main():
    with open('lib/main.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    new_build = '''  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambiance = ref.watch(ambianceProvider);

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
      home: SplashScreen(enableAnimation: enableAnimation),
    );
  }'''
    content = re.sub(r'  @override\n  Widget build\(BuildContext context, WidgetRef ref\) \{.*?^\s*\}', new_build, content, flags=re.DOTALL | re.MULTILINE)
    
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(content)

def update_media_provider():
    with open('lib/providers/media_provider.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # "6. Update lib/providers/media_provider.dart: Update importBackupJson to map old camelCase string representations (e.g. screeningRoom) to new snake_case IDs dynamically."
    # Let's find importBackupJson in media_provider.dart
    
    match = re.search(r'importBackupJson\([^)]+\)\s*async\s*\{', content)
    if match:
        pass
    else:
        print("importBackupJson not found in media_provider.dart")

update_ambiance_provider()
update_main()
