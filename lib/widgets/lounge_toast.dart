import 'package:flutter/material.dart';
import '../constants.dart';
import 'frosted_glass_surface.dart';

enum ToastType { info, success, danger }

/// The app's floating ambient-glass toast -- the single canonical
/// replacement for stock [ScaffoldMessenger]/[SnackBar] everywhere.
class LoungeToast {
  LoungeToast._();

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    final key = GlobalKey<_LoungeToastWidgetState>();

    entry = OverlayEntry(
      builder: (context) => _LoungeToastWidget(
        key: key,
        message: message,
        type: type,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _LoungeToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _LoungeToastWidget({
    super.key,
    required this.message,
    required this.type,
    required this.duration,
    required this.actionLabel,
    required this.onAction,
    required this.onDismissed,
  });

  @override
  State<_LoungeToastWidget> createState() => _LoungeToastWidgetState();
}

class _LoungeToastWidgetState extends State<_LoungeToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppPhysics.houseSpringDuration);
    _curved = CurvedAnimation(parent: _controller, curve: AppPhysics.houseSpringCurve);
    _controller.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _accentFor(AmbianceColors ambiance) {
    switch (widget.type) {
      case ToastType.success:
        return ambiance.success;
      case ToastType.danger:
        return ambiance.danger;
      case ToastType.info:
        return ambiance.acc;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;
    final accent = _accentFor(ambiance);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomInset + 24,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_curved),
        child: FadeTransition(
          opacity: _curved,
          child: Material(
            color: Colors.transparent,
            child: FrostedGlassSurface(
              borderRadius: 999,
              backgroundColor: ambiance.card2.withValues(alpha: 0.9),
              borderColor: accent.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ambiance.ink,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        widget.onAction?.call();
                        _dismiss();
                      },
                      child: Text(
                        widget.actionLabel!,
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
