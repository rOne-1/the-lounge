import re

with open('lib/constants.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("export 'constants/app_physics.dart';", "export 'constants/app_physics.dart';\nexport 'themes/app_theme.dart';\nexport 'themes/theme_registry.dart';")
content = re.sub(r'enum AmbianceType\s*\{[^}]+\}', '', content)
content = re.sub(r'extension AmbianceThemeExtension on BuildContext\s*\{[^}]+\}', '', content)

for name in ['screeningRoomBackground', 'readingRoomBackground', 'violetDuskBackground']:
    content = re.sub(r'  static BoxDecoration ' + name + r'\(\) \{.*?\n  \}', '', content, flags=re.DOTALL)

for name in ['srAmbianceColors', 'rrAmbianceColors', 'vdAmbianceColors']:
    content = re.sub(r'  static final AmbianceColors ' + name + r' = AmbianceColors\([^;]+;', '', content, flags=re.DOTALL)

for name in ['screeningRoomTheme', 'readingRoomTheme', 'violetDuskTheme']:
    content = re.sub(r'  static ThemeData get ' + name + r' \{.*?\n  \}', '', content, flags=re.DOTALL)

content = re.sub(r'  static ThemeData theme\(AmbianceType type\) \{.*?\n  \}', '', content, flags=re.DOTALL)

match_btt = re.search(r'  static TextTheme _buildTextTheme\(Color textColor\) \{.*?\n  \}', content, flags=re.DOTALL)
if match_btt:
    btt_code = match_btt.group(0).replace('  static TextTheme _buildTextTheme', 'TextTheme buildTextTheme')
    content = content.replace(match_btt.group(0), '')
    content += '\n' + btt_code

# Also fix the safeGeist calls in buildTextTheme (they used to just call safeGeist, but now safeGeist is in AppThemes and we moved buildTextTheme outside)
# Wait, if buildTextTheme is outside, it should call AppThemes.safeGeist instead of safeGeist.
content = content.replace('safeGeist(', 'AppThemes.safeGeist(')

with open('lib/constants.dart', 'w', encoding='utf-8') as f:
    f.write(content)
