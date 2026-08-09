import os

files_to_clean_theme = [
    r"lib\screens\browse_screen.dart",
    r"lib\screens\calendar_screen.dart",
    r"lib\screens\collection_screen.dart",
    r"lib\screens\detail_screen.dart",
    r"lib\screens\discover_screen.dart",
    r"lib\screens\home_screen.dart",
    r"lib\screens\media_list_screen.dart",
    r"lib\screens\your_space_screen.dart",
    r"lib\widgets\media_image.dart",
    r"lib\widgets\pick_for_me_card.dart"
]

for rel_path in files_to_clean_theme:
    full_path = os.path.join(r"c:\Users\myhea\Documents\GitHub\the-lounge", rel_path)
    if os.path.exists(full_path):
        with open(full_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        
        with open(full_path, "w", encoding="utf-8") as f:
            for line in lines:
                if "final theme =" in line or "ThemeData theme =" in line:
                    continue
                if "final isDark =" in line and "media_image.dart" in rel_path:
                    continue
                f.write(line)

test_path = r"c:\Users\myhea\Documents\GitHub\the-lounge\test\settings_screen_test.dart"
if os.path.exists(test_path):
    with open(test_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    with open(test_path, "w", encoding="utf-8") as f:
        for line in lines:
            if "import 'dart:io';" in line:
                continue
            f.write(line)
