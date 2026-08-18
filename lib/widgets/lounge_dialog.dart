import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'pressable_scale.dart';

enum LoungeDialogActionStyle { neutral, primary, destructive }

class LoungeDialogAction {
  final String label;
  final VoidCallback? onPressed;
  final LoungeDialogActionStyle style;
  final Key? key;

  const LoungeDialogAction({
    required this.label,
    this.onPressed,
    this.style = LoungeDialogActionStyle.neutral,
    this.key,
  });
}

/// The app's bespoke luxury dialog: frosted glass, ambient hairline border,
/// Bodoni Moda header, and house-spring scale+fade entrance -- the single
/// canonical replacement for stock [AlertDialog] everywhere in the app.
class LoungeDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<LoungeDialogAction> actions;

  const LoungeDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
  });

  /// Shows the dialog with a house-spring scale+fade entrance (Flutter's
  /// stock [showDialog] hardcodes a Material fade transition it doesn't
  /// let callers override, so this uses [showGeneralDialog] directly).
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String message,
    required List<LoungeDialogAction> actions,
    bool barrierDismissible = true,
  }) {
    final ambiance = context.ambianceColors;
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: title,
      barrierColor: ambiance.scrim,
      transitionDuration: AppPhysics.houseSpringDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return LoungeDialog(title: title, message: message, actions: actions);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: AppPhysics.houseSpringCurve);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
                decoration: BoxDecoration(
                  color: ambiance.card2.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ambiance.lineRgba),
                  boxShadow: [
                    BoxShadow(
                      color: ambiance.surfaceHighlight,
                      blurRadius: 0,
                      offset: const Offset(0, 1),
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: ambiance.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: AppThemes.safeGeist(
                        fontSize: 14,
                        height: 1.4,
                        color: ambiance.sub,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 8,
                      children: actions.map((action) => _LoungeDialogActionButton(action: action)).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoungeDialogActionButton extends StatelessWidget {
  final LoungeDialogAction action;
  const _LoungeDialogActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;

    switch (action.style) {
      case LoungeDialogActionStyle.neutral:
        return PressableScale(
          key: action.key,
          onTap: action.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              action.label,
              style: AppThemes.safeGeist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ambiance.sub,
              ),
            ),
          ),
        );
      case LoungeDialogActionStyle.primary:
        return PressableScale(
          key: action.key,
          onTap: action.onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: ambiance.primaryButtonDecoration,
            child: Text(
              action.label,
              style: AppThemes.safeGeist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        );
      case LoungeDialogActionStyle.destructive:
        return PressableScale(
          key: action.key,
          onTap: action.onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: ambiance.danger,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              action.label,
              style: AppThemes.safeGeist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
    }
  }
}
