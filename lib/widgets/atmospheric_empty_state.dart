import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'ambient_glow.dart';
import 'pressable_scale.dart';

/// The app's atmospheric empty-state treatment: a frosted ambient card with
/// an icon watermark and a Bodoni Moda headline, replacing plain
/// `Text('Nothing here yet.')` placeholders everywhere. The CTA is
/// caller-driven (a callback, not a route) so this stays decoupled from
/// navigation/providers -- callers wire it to whatever "go find something"
/// action makes sense in their context (Discover, Browse, clearing a filter).
class AtmosphericEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  /// An escape hatch for states needing more than one action (e.g. Search's
  /// "Clear search" + "Reset All Filters"). Takes priority over [ctaLabel]/
  /// [onCta] when provided.
  final List<Widget>? actions;

  const AtmosphericEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.ctaLabel,
    this.onCta,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: AmbientGlowWidget(
            // Static glow: an empty state is a resting/idle screen, not a
            // moment that should draw the eye with perpetual motion.
            enableAnimation: false,
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: ambiance.sub.withValues(alpha: 0.5)),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bodoniModa(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: ambiance.ink,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: AppThemes.safeGeist(fontSize: 13, height: 1.4, color: ambiance.sub),
                  ),
                ],
                if (ambiance.signatureMotif != null) ...[
                  const SizedBox(height: 16),
                  ambiance.signatureMotif!(context),
                ],
                if (actions != null) ...[
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: actions!,
                  ),
                ] else if (ctaLabel != null && onCta != null) ...[
                  const SizedBox(height: 22),
                  PressableScale(
                    onTap: onCta,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: ambiance.primaryButtonDecoration,
                      child: Text(
                        ctaLabel!,
                        style: AppThemes.safeGeist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
