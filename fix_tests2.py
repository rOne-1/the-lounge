import re

with open('test/settings_screen_test.dart', 'r', encoding='utf-8') as f:
    settings_content = f.read()

if "import 'package:the_lounge/themes/screening_room_theme.dart';" not in settings_content:
    settings_content = settings_content.replace(
        "import 'package:the_lounge/themes/app_theme.dart';",
        "import 'package:the_lounge/themes/app_theme.dart';\nimport 'package:the_lounge/themes/screening_room_theme.dart';\nimport 'package:the_lounge/themes/reading_room_theme.dart';"
    )

with open('test/settings_screen_test.dart', 'w', encoding='utf-8') as f:
    f.write(settings_content)


with open('test/motion_pass_sections_6_7_8_test.dart', 'r', encoding='utf-8') as f:
    motion_content = f.read()

motion_content = motion_content.replace("AppThemes.srAmbianceColors", "srAmbianceColors")
motion_content = motion_content.replace("AppThemes.rrAmbianceColors", "rrAmbianceColors")
motion_content = motion_content.replace("AppThemes.vdAmbianceColors", "vdAmbianceColors")

if "import 'package:the_lounge/themes/ambiance_colors.dart';" not in motion_content:
    motion_content = motion_content.replace(
        "import 'package:the_lounge/constants.dart';",
        "import 'package:the_lounge/constants.dart';\nimport 'package:the_lounge/themes/ambiance_colors.dart';\nimport 'package:the_lounge/themes/screening_room_theme.dart';\nimport 'package:the_lounge/themes/reading_room_theme.dart';"
    )

with open('test/motion_pass_sections_6_7_8_test.dart', 'w', encoding='utf-8') as f:
    f.write(motion_content)

print("Fixed the last two tests.")
