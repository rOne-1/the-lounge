import 'package:flutter/physics.dart';
import 'package:flutter/animation.dart';

/// Centralized motion physics presets and constants for the app.
class AppPhysics {
  /// Single House Spring Preset description per motion design specification:
  /// mass: 1.0, stiffness: 180.0, damping: 14.0
  static const SpringDescription houseSpringDescription = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 14.0,
  );

  /// Standard duration for house spring transitions (~550ms)
  static const Duration houseSpringDuration = Duration(milliseconds: 550);

  /// Curve representation of the House Spring Preset for duration-based transitions
  /// like container transforms, ambiance morphing, and pulse animations.
  static const Curve houseSpringCurve = HouseSpringCurve();

  /// Helper method to create a [SpringSimulation] using the House Spring Preset
  /// with initial position [start], target [end], and initial velocity [velocity].
  static SpringSimulation createHouseSpringSimulation({
    required double start,
    required double end,
    required double velocity,
  }) {
    return SpringSimulation(
      houseSpringDescription,
      start,
      end,
      velocity,
    );
  }
}

/// A custom [Curve] wrapping a normalized [SpringSimulation] defined by the House Spring Preset.
class HouseSpringCurve extends Curve {
  final double initialVelocity;
  final double targetDurationInSeconds;

  const HouseSpringCurve({
    this.initialVelocity = 0.0,
    this.targetDurationInSeconds = 0.55,
  });

  @override
  double transformInternal(double t) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    final simulation = SpringSimulation(
      AppPhysics.houseSpringDescription,
      0.0,
      1.0,
      initialVelocity,
    );
    return simulation.x(t * targetDurationInSeconds);
  }
}

/// A 2D simulation combining X and Y spring simulations with the House Spring Preset
/// for velocity-retaining drag release settling and fly-offs.
class OffsetSpringSimulation extends Simulation {
  final SpringSimulation simX;
  final SpringSimulation simY;

  OffsetSpringSimulation({
    required double startX,
    required double endX,
    required double velocityX,
    required double startY,
    required double endY,
    required double velocityY,
    SpringDescription spring = AppPhysics.houseSpringDescription,
  })  : simX = SpringSimulation(spring, startX, endX, velocityX),
        simY = SpringSimulation(spring, startY, endY, velocityY);

  Offset dxOffset(double timeInSeconds) {
    return Offset(simX.x(timeInSeconds), simY.x(timeInSeconds));
  }

  @override
  double x(double timeInSeconds) => simX.x(timeInSeconds);

  @override
  double dx(double timeInSeconds) => simX.dx(timeInSeconds);

  @override
  bool isDone(double timeInSeconds) {
    return simX.isDone(timeInSeconds) && simY.isDone(timeInSeconds);
  }
}
