import 'package:flutter/material.dart';
import '../constants.dart';

/// A brief outward pulse-ring flash around [child] when [isSelected] flips
/// from false to true — used to punctuate status toggles (watchlist, saved,
/// watched) becoming active.
class StatusPulseRing extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Color accentColor;
  final double borderRadius;

  const StatusPulseRing({
    super.key,
    required this.child,
    required this.isSelected,
    required this.accentColor,
    this.borderRadius = 12,
  });

  @override
  State<StatusPulseRing> createState() => _StatusPulseRingState();
}

class _StatusPulseRingState extends State<StatusPulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppPhysics.houseSpringDuration,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: AppPhysics.houseSpringCurve),
    );
    _pulseOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: AppPhysics.houseSpringCurve),
    );
  }

  @override
  void didUpdateWidget(StatusPulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_pulseController.isAnimating)
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: _pulseScale.value,
                    child: Opacity(
                      opacity: _pulseOpacity.value.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          border: Border.all(color: widget.accentColor, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }
}
