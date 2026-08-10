import re

with open('lib/constants.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

def get_block(start_marker):
    start_idx = -1
    for i, line in enumerate(lines):
        if start_marker in line:
            start_idx = i
            break
    if start_idx == -1: return None
    
    # finding matching brace
    brace_count = 0
    end_idx = -1
    for i in range(start_idx, len(lines)):
        brace_count += lines[i].count('{')
        brace_count -= lines[i].count('}')
        if brace_count == 0 and '{' in ''.join(lines[start_idx:i+1]):
            end_idx = i
            break
            
    if end_idx != -1:
        return "".join(lines[start_idx:end_idx+1])
    return None

safe_geist_code = get_block("static TextStyle safeGeist({")
build_text_code = get_block("static TextTheme _buildTextTheme(Color textColor) {")

app_colors_code = get_block("class AppColors {")

if not safe_geist_code or not build_text_code or not app_colors_code:
    print("Could not find all blocks")
    exit(1)

build_text_code = build_text_code.replace("static TextTheme _buildTextTheme", "TextTheme buildTextTheme")
build_text_code = build_text_code.replace("safeGeist(", "AppThemes.safeGeist(")

new_content = """import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'constants/app_physics.dart';
export 'themes/app_theme.dart';
export 'themes/theme_registry.dart';

""" + app_colors_code + """

class AppThemes {
""" + safe_geist_code + """
}

""" + build_text_code + "\n"

with open('lib/constants.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

