import subprocess
import re

# Get original constants.dart
result = subprocess.run(['git', 'show', 'HEAD:lib/constants.dart'], capture_output=True, text=True)
original_constants = result.stdout

# Extract AmbianceColors
ambiance_match = re.search(r'(class AmbianceColors extends ThemeExtension<AmbianceColors> \{.*?\n\})', original_constants, flags=re.DOTALL)
if not ambiance_match:
    print("Could not find AmbianceColors")
    exit(1)

ambiance_code = ambiance_match.group(1)

# Also extract AmbianceThemeExtension which provides context.ambianceColors
ambiance_extension_match = re.search(r'(extension AmbianceThemeExtension on BuildContext \{.*?\n\})', original_constants, flags=re.DOTALL)
if ambiance_extension_match:
    # We already have an extension in app_theme.dart called AmbianceContext? Let's check app_theme.dart.
    pass

# Read app_theme.dart
with open('lib/themes/app_theme.dart', 'r', encoding='utf-8') as f:
    app_theme_content = f.read()

# Append AmbianceColors to app_theme.dart if not present
if "class AmbianceColors" not in app_theme_content:
    new_app_theme_content = app_theme_content + "\n\n" + ambiance_code + "\n"
    with open('lib/themes/app_theme.dart', 'w', encoding='utf-8') as f:
        f.write(new_app_theme_content)
    print("Added AmbianceColors to app_theme.dart")
else:
    print("AmbianceColors already in app_theme.dart")
