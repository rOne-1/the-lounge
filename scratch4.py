import re

with open('lib/providers/media_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''      final ambianceStr = decoded['selectedAmbiance'];
      if (ambianceStr is String) {
        final match = AmbianceType.values.firstWhere(
          (e) => e.name == ambianceStr,
          orElse: () => AmbianceType.screeningRoom,
        );
        ref.read(ambianceProvider.notifier).setAmbiance(match);
      }'''

new_code = '''      final ambianceStr = decoded['selectedAmbiance'];
      if (ambianceStr is String) {
        String id = ambianceStr;
        if (id == 'screeningRoom') id = 'screening_room';
        if (id == 'readingRoom') id = 'reading_room';
        if (id == 'violetDusk') id = 'violet_dusk';
        final match = getThemeById(id);
        ref.read(ambianceProvider.notifier).setAmbiance(match);
      }'''

content = content.replace(old_code, new_code)
if "import '../themes/theme_registry.dart';" not in content:
    content = content.replace("import 'ambiance_provider.dart';", "import 'ambiance_provider.dart';\nimport '../themes/theme_registry.dart';")

with open('lib/providers/media_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
