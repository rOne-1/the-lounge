import re
import os

with open('lib/themes/app_theme.dart', 'r', encoding='utf-8') as f:
    app_theme_content = f.read()

# Extract AmbianceContext and AmbianceColors
ambiance_match = re.search(r'(extension AmbianceContext on BuildContext \{.*?\n\})\s*(class AmbianceColors extends ThemeExtension<AmbianceColors> \{.*?\n\})', app_theme_content, flags=re.DOTALL)

if not ambiance_match:
    print("Could not extract AmbianceContext and AmbianceColors from app_theme.dart")
    # Maybe AmbianceColors is alone?
    ambiance_code_only = re.search(r'(class AmbianceColors extends ThemeExtension<AmbianceColors> \{.*?\n\})', app_theme_content, flags=re.DOTALL)
    if ambiance_code_only:
        ambiance_code = ambiance_code_only.group(1)
        ambiance_context_code = re.search(r'(extension AmbianceContext on BuildContext \{.*?\n\})', app_theme_content, flags=re.DOTALL).group(1)
    else:
        exit(1)
else:
    ambiance_context_code = ambiance_match.group(1)
    ambiance_code = ambiance_match.group(2)

# Remove them from app_theme.dart
app_theme_content = app_theme_content.replace(ambiance_context_code, '')
app_theme_content = app_theme_content.replace(ambiance_code, '')

# Add import 'ambiance_colors.dart'; to app_theme.dart
if "import 'ambiance_colors.dart';" not in app_theme_content:
    app_theme_content = app_theme_content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'ambiance_colors.dart';")

# We can also remove import 'theme_registry.dart' from app_theme.dart because app_theme.dart doesn't need it anymore!
app_theme_content = app_theme_content.replace("import 'theme_registry.dart';", "")

with open('lib/themes/app_theme.dart', 'w', encoding='utf-8') as f:
    f.write(app_theme_content)

# Now create ambiance_colors.dart
ambiance_colors_content = """import 'package:flutter/material.dart';
import '../constants.dart';
import 'theme_registry.dart';

""" + ambiance_context_code + "\n\n" + ambiance_code + "\n"

with open('lib/themes/ambiance_colors.dart', 'w', encoding='utf-8') as f:
    f.write(ambiance_colors_content)

# Also update constants.dart to export it
with open('lib/constants.dart', 'r', encoding='utf-8') as f:
    constants_content = f.read()

if "export 'themes/ambiance_colors.dart';" not in constants_content:
    constants_content = constants_content.replace("export 'themes/app_theme.dart';", "export 'themes/ambiance_colors.dart';\nexport 'themes/app_theme.dart';")

with open('lib/constants.dart', 'w', encoding='utf-8') as f:
    f.write(constants_content)

print("Created ambiance_colors.dart and updated app_theme.dart and constants.dart")
