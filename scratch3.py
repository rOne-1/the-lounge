import re

def update_settings():
    with open('lib/screens/settings_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    old_segmented_button = '''                            SegmentedButton<AmbianceType>(
                              segments: const [
                                ButtonSegment(
                                  value: AmbianceType.readingRoom,
                                  label: Text('Reading'),
                                ),
                                ButtonSegment(
                                  value: AmbianceType.screeningRoom,
                                  label: Text('Screening'),
                                ),
                                ButtonSegment(
                                  value: AmbianceType.violetDusk,
                                  label: Text('Violet'),
                                ),
                              ],
                              selected: {ambiance},
                              onSelectionChanged: (Set<AmbianceType> newSelection) {
                                ref.read(ambianceProvider.notifier).setAmbiance(newSelection.first);
                              },'''
    
    new_segmented_button = '''                            SegmentedButton<AppTheme>(
                              segments: allThemes.map((t) => ButtonSegment(
                                value: t,
                                label: Text(t.displayName.split(' ').first),
                              )).toList(),
                              selected: {ambiance},
                              onSelectionChanged: (Set<AppTheme> newSelection) {
                                ref.read(ambianceProvider.notifier).setAmbiance(newSelection.first);
                              },'''
    
    content = content.replace(old_segmented_button, new_segmented_button)
    content = content.replace('ambiance.name', 'ambiance.id')
    if "import '../themes/theme_registry.dart';" not in content:
        content = content.replace("import '../constants.dart';", "import '../constants.dart';\nimport '../themes/theme_registry.dart';\nimport '../themes/app_theme.dart';")
    
    with open('lib/screens/settings_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

def update_shell():
    with open('lib/screens/shell_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('AmbianceType ambiance', 'AppTheme ambiance')
    if "import '../themes/app_theme.dart';" not in content:
        content = content.replace("import '../constants.dart';", "import '../constants.dart';\nimport '../themes/app_theme.dart';")
    content = content.replace('AppThemes.theme(ambiance)', 'ambiance.themeData')
    with open('lib/screens/shell_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

def update_tests():
    with open('test/settings_screen_test.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('SegmentedButton<AmbianceType>', 'SegmentedButton<AppTheme>')
    content = content.replace('AmbianceType.screeningRoom', 'screeningRoomTheme')
    content = content.replace('AmbianceType.readingRoom', 'readingRoomTheme')
    content = content.replace('AmbianceType.violetDusk', 'violetDuskTheme')
    if "import 'package:the_lounge/themes/app_theme.dart';" not in content:
        content = content.replace("import 'package:the_lounge/constants.dart';", "import 'package:the_lounge/constants.dart';\nimport 'package:the_lounge/themes/app_theme.dart';")
    with open('test/settings_screen_test.dart', 'w', encoding='utf-8') as f:
        f.write(content)

update_settings()
update_shell()
update_tests()
