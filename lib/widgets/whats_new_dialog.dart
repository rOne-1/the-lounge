import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../constants/whats_new.dart';
import '../providers/ambiance_provider.dart';
import 'frosted_glass_surface.dart';
import 'pressable_scale.dart';

/// One-shot "What's New" changelog dialog, shown after an app update so
/// testers see a plain-language summary of what changed since their last
/// install. Matches LoungeDialog's visual language (frosted glass, ambient
/// hairline border, Bodoni Moda header, house-spring entrance) but adds a
/// scrollable body, since a changelog is longer than a confirmation message.
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  static Future<void> show(BuildContext context) {
    final ambiance = context.ambianceColors;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "What's New",
      barrierColor: ambiance.scrim,
      transitionDuration: AppPhysics.houseSpringDuration,
      pageBuilder: (context, animation, secondaryAnimation) => const WhatsNewDialog(),
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
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 440),
          child: FrostedGlassSurface(
            borderRadius: 22,
            backgroundColor: ambiance.card2.withValues(alpha: 0.9),
            borderColor: ambiance.lineRgba,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What's New",
                        style: AppThemes.display(
                          context,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: ambiance.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Since your last build',
                        style: AppThemes.safeGeist(
                          fontSize: 12.5,
                          color: ambiance.sub,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final section in kWhatsNewSections) ...[
                          Text(
                            section.title,
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: ambiance.acc,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final item in section.items) _WhatsNewItem(text: item),
                          const SizedBox(height: 18),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PressableScale(
                      key: const ValueKey('whats_new_dismiss_button'),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: ambiance.primaryButtonDecoration,
                        child: Text(
                          'Got it',
                          style: AppThemes.safeGeist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhatsNewItem extends StatelessWidget {
  final String text;
  const _WhatsNewItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: ambiance.acc, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppThemes.safeGeist(
                fontSize: 13.5,
                height: 1.4,
                color: ambiance.sub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mounts once inside ShellScreen and checks, after the first frame,
/// whether the What's New dialog needs to show for the current
/// kWhatsNewVersion -- shows it at most once per version, tracked in
/// SharedPreferences. Renders nothing itself.
///
/// [enableAnimation] reuses the same test-suppression convention as
/// PickForMeCard/AmbientGlowWidget elsewhere in this app: ShellScreen is
/// pumped directly in dozens of existing widget tests with
/// `enableAnimation: false`, and this gate popping a modal dialog
/// automatically after first frame in every one of them would break all
/// of that unrelated coverage. Explicitly passing `false` skips the
/// check entirely; real app usage leaves it null/true.
class WhatsNewGate extends ConsumerStatefulWidget {
  final bool? enableAnimation;

  const WhatsNewGate({super.key, this.enableAnimation});

  @override
  ConsumerState<WhatsNewGate> createState() => _WhatsNewGateState();
}

class _WhatsNewGateState extends ConsumerState<WhatsNewGate> {
  static const _prefsKey = 'whats_new_last_shown_version';
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    if (widget.enableAnimation == false) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (!mounted) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final lastShown = prefs.getString(_prefsKey);
    if (lastShown == kWhatsNewVersion) return;

    // Persist before the dialog is actually dismissed, not after -- if the
    // app is killed/backgrounded while it's showing, the version is still
    // recorded, matching "shown at least once" rather than risking it
    // reappearing indefinitely until the user happens to dismiss it in one
    // sitting.
    await prefs.setString(_prefsKey, kWhatsNewVersion);
    if (!mounted) return;
    await WhatsNewDialog.show(context);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
