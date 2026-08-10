import re

with open('lib/constants.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add exports
content = content.replace("export 'constants/app_physics.dart';", "export 'constants/app_physics.dart';\nexport 'themes/app_theme.dart';\nexport 'themes/theme_registry.dart';")

# Remove AmbianceType enum
content = re.sub(r'enum AmbianceType\s*\{[^}]+\}', '', content)

# Remove AmbianceThemeExtension
content = re.sub(r'extension AmbianceThemeExtension on BuildContext\s*\{[^}]+\}', '', content)

# The goal is to remove the AppThemes class but keep the buildTextTheme function.
# The AppThemes class is at the end of the file.
buildTextTheme_match = re.search(r'static TextTheme _buildTextTheme\(Color textColor\) \{.*?\n  \}', content, re.DOTALL)
if buildTextTheme_match:
    btt = buildTextTheme_match.group(0).replace('static TextTheme _buildTextTheme', 'TextTheme buildTextTheme')
    # replace the entire AppThemes class with just the buildTextTheme function
    content = re.sub(r'class AppThemes \{.*^\}', btt, content, flags=re.DOTALL | re.MULTILINE)

with open('lib/constants.dart', 'w', encoding='utf-8') as f:
    f.write(content)
