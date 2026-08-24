import 'package:flutter/material.dart';
import '../themes/ambiance_colors.dart';

/// THEME-DEPTH-4: A reusable widget that renders the active theme's bespoke
/// signature motif (e.g. Screening Room gold diamond rule, Midnight Cinema
/// marquee bulbs, Orchid Bloom botanical flourish, Violet Dusk art-deco
/// chevron, Tuscany wrought-iron sunburst).
///
/// Returns [SizedBox.shrink] if the active theme does not specify a motif.
class SignatureMotif extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final double? height;

  const SignatureMotif({
    super.key,
    this.margin,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final motifBuilder = context.ambianceColors.signatureMotif;
    if (motifBuilder == null) return const SizedBox.shrink();

    Widget child = motifBuilder(context);
    if (height != null) {
      child = SizedBox(height: height, child: child);
    }
    if (margin != null) {
      child = Padding(padding: margin!, child: child);
    }
    return child;
  }
}
