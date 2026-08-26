import 'package:flutter/material.dart';
import '../constants.dart';

/// A reusable physics-driven bottom sheet wrapper supporting swipe-down drag to dismiss
/// with a visible drag handle and spring snap-back using [AppPhysics.houseSpringCurve].
class DragToDismissSheet extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;
  final bool isDark;
  final double dismissThreshold;
  final double velocityThreshold;

  const DragToDismissSheet({
    super.key,
    required this.child,
    required this.onDismiss,
    required this.isDark,
    this.dismissThreshold = 100.0,
    this.velocityThreshold = 500.0,
  });

  @override
  State<DragToDismissSheet> createState() => _DragToDismissSheetState();
}

class _DragToDismissSheetState extends State<DragToDismissSheet>
    with SingleTickerProviderStateMixin {
  double _dragY = 0.0;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: AppPhysics.houseSpringDuration,
    );
    _snapController.addListener(() {
      setState(() {
        _dragY = _snapAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _snapBack() {
    _snapAnimation = Tween<double>(begin: _dragY, end: 0.0).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: AppPhysics.houseSpringCurve,
      ),
    );
    _snapController.forward(from: 0.0);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_snapController.isAnimating) {
      _snapController.stop();
    }
    setState(() {
      _dragY = (_dragY + details.delta.dy).clamp(0.0, 1000.0);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocityY = details.velocity.pixelsPerSecond.dy;
    if (_dragY > widget.dismissThreshold ||
        velocityY > widget.velocityThreshold) {
      // BUGFIX-4: onDismiss() pops the route, which starts the modal's own
      // slide-down closing transition. Snapping _dragY back to 0 right
      // here used to fight that transition -- the sheet visually jumped
      // back to its undragged position for a frame before the route's own
      // animation took over, reading as a jitter/jerk right at release
      // (dev-reported, 2026-08-26 feedback doc item 9). This widget is
      // about to be disposed as the route pops, so there's nothing to
      // reset _dragY for -- leaving it lets the route's closing animation
      // continue smoothly from wherever the user's finger actually let go.
      widget.onDismiss();
    } else {
      _snapBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final handleColor = context.ambianceColors.sub.withValues(alpha: 0.25);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Transform.translate(
        offset: Offset(0, _dragY),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
