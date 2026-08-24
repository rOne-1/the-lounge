import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants.dart';

/// D-1: shared frosted-glass "card" shell used by every static dialog/sheet/
/// panel in the app -- `ClipRRect -> BackdropFilter -> Material(transparency)
/// -> decorated Container`, with the same 16-sigma blur and inner-highlight
/// boxShadow across every consumer (LoungeDialog, WhatsNewDialog,
/// LoungeDropdown, LoungeToast). THEME-DEPTH-3: also carries each theme's
/// own `dialogShadow` as an outer elevation layer -- previously this shell
/// had no outer lift shadow at all, just the inner highlight.
///
/// Deliberately does NOT cover FloatingNavigationCapsule: that widget
/// animates its own width/height, draws an outer drop shadow instead of this
/// inner highlight, and gets its actual glass tint from a nested
/// AmbientGlowWidget rather than this layer's own decoration -- forcing it
/// into this same static widget would misrepresent the abstraction rather
/// than genuinely reuse it.
class FrostedGlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;

  const FrostedGlassSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    this.padding,
    this.blurSigma = 16,
  });

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;
    // B4: RepaintBoundary isolates this into its own compositing layer --
    // BackdropFilter composited underneath a page-route/dialog-route's own
    // animated transition can otherwise render fully black and stay that
    // way until something forces a full scene recomposite. This shell is
    // shared by every static dialog/sheet/panel, so fixing it here covers
    // all of them at once.
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderColor),
                boxShadow: [
                  ...ambiance.dialogShadow,
                  BoxShadow(
                    color: ambiance.surfaceHighlight,
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
