import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleAmount;
  final Duration pressDuration;
  final Duration releaseDuration;
  final Curve curve;
  final bool enabled;
  final bool hapticFeedback;
  final HitTestBehavior behavior;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleAmount = 0.96,
    this.pressDuration = const Duration(milliseconds: 120),
    this.releaseDuration = AppPhysics.houseSpringDuration,
    this.curve = AppPhysics.houseSpringCurve,
    this.enabled = true,
    this.hapticFeedback = false,
    this.behavior = HitTestBehavior.translucent,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    if (widget.hapticFeedback) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // BETA3-A11Y-1: universal tap wrapper used app-wide -- one button:true
    // role here covers nearly every button/icon/action pill in the app,
    // without needing every call site to opt in individually. Descendant
    // Text/Icon semantics still merge in as the announced label; this only
    // adds the button role + enabled state on top.
    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: AnimatedScale(
          scale: _isPressed && widget.enabled ? widget.scaleAmount : 1.0,
          // Immediate on the way down, house-spring snap-back on release —
          // the same damped spring curve, just played over a shorter window
          // while compressing so the tap reads as instant rather than mushy.
          duration: _isPressed ? widget.pressDuration : widget.releaseDuration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
