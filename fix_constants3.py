import re

with open('lib/constants.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add exports
if "export 'themes/app_theme.dart';" not in content:
    content = content.replace("export 'constants/app_physics.dart';", "export 'constants/app_physics.dart';\nexport 'themes/app_theme.dart';\nexport 'themes/theme_registry.dart';")

# 2. Remove AmbianceType enum and AmbianceThemeExtension
content = re.sub(r'enum AmbianceType\s*\{[^}]+\}', '', content)
content = re.sub(r'extension AmbianceThemeExtension on BuildContext\s*\{[^}]+\}', '', content)

# 3. Clean up AppThemes class. We want to KEEP safeGeist inside it, but REMOVE everything else.
# Wait, safeGeist is defined as:
#   static TextStyle safeGeist({
# ...
#   }
# And _buildTextTheme is defined as:
#   static TextTheme _buildTextTheme(Color textColor) {
# ...
#   }
# Let's extract safeGeist and _buildTextTheme first.
safe_geist_match = re.search(r'  static TextStyle safeGeist\(\{.*?\n  \}', content, flags=re.DOTALL)
build_text_theme_match = re.search(r'  static TextTheme _buildTextTheme\(Color textColor\) \{.*?\n  \}', content, flags=re.DOTALL)

if safe_geist_match and build_text_theme_match:
    safe_geist_code = safe_geist_match.group(0)
    build_text_theme_code = build_text_theme_match.group(0).replace('  static TextTheme _buildTextTheme', 'TextTheme buildTextTheme')
    # Change safeGeist( to AppThemes.safeGeist( inside buildTextTheme_code
    build_text_theme_code = build_text_theme_code.replace('safeGeist(', 'AppThemes.safeGeist(')

    # Now replace the entire AppThemes class with just safeGeist
    app_themes_match = re.search(r'class AppThemes \{.*?\n\}', content, flags=re.DOTALL)
    if app_themes_match:
        new_app_themes = "class AppThemes {\n" + safe_geist_code + "\n}"
        content = content.replace(app_themes_match.group(0), new_app_themes + "\n\n" + build_text_theme_code)

with open('lib/constants.dart', 'w', encoding='utf-8') as f:
    f.write(content)
