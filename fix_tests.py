import glob
import re

for filepath in glob.glob('test/*.dart'):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # Imports to add
    if "AppThemes" in content or "AmbianceType" in content:
        if "package:the_lounge/themes/theme_registry.dart" not in content:
            content = content.replace("import 'package:the_lounge/constants.dart';", "import 'package:the_lounge/constants.dart';\nimport 'package:the_lounge/themes/theme_registry.dart';\nimport 'package:the_lounge/themes/app_theme.dart';\nimport 'package:the_lounge/themes/screening_room_theme.dart';\nimport 'package:the_lounge/themes/reading_room_theme.dart';\nimport 'package:the_lounge/themes/violet_dusk_theme.dart';\nimport 'package:the_lounge/themes/midnight_cinema_theme.dart';")

    # Replacements
    content = content.replace('AppThemes.screeningRoomBackground()', 'screeningRoomBackground()')
    content = content.replace('AppThemes.readingRoomBackground()', 'readingRoomBackground()')
    
    content = content.replace('AppThemes.screeningRoomTheme', 'screeningRoomTheme.themeData')
    content = content.replace('AppThemes.readingRoomTheme', 'readingRoomTheme.themeData')
    content = content.replace('AppThemes.violetDuskTheme', 'violetDuskTheme.themeData')
    
    content = content.replace('AmbianceType.screeningRoom', "getThemeById('screening_room')!")
    content = content.replace('AmbianceType.readingRoom', "getThemeById('reading_room')!")
    content = content.replace('AmbianceType.violetDusk', "getThemeById('violet_dusk')!")

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")
