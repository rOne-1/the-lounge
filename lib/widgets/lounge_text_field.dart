import 'package:flutter/material.dart';
import '../constants.dart';

/// A themed single-line text field matching the app's pill/card aesthetic --
/// used anywhere a short piece of user text (a folder name, a rename) needs
/// entering, so it never reads as a stock unthemed Material `TextField`.
class LoungeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final int maxLength;

  const LoungeTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.onSubmitted,
    this.maxLength = 40,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      style: AppThemes.safeGeist(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.ink,
      ),
      cursorColor: colors.acc,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppThemes.safeGeist(fontSize: 14, color: colors.sub),
        filled: true,
        fillColor: colors.pill,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.lineRgba),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.lineRgba),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.acc, width: 1.5),
        ),
      ),
    );
  }
}
