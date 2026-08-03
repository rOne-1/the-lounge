import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/constants/app_physics.dart';

void main() {
  group('AppPhysics - House Spring Preset Tests', () {
    test('House Spring Preset has correct mass, stiffness, and damping', () {
      expect(AppPhysics.houseSpringDescription.mass, equals(1.0));
      expect(AppPhysics.houseSpringDescription.stiffness, equals(180.0));
      expect(AppPhysics.houseSpringDescription.damping, equals(14.0));
    });

    test('HouseSpringCurve boundary and underdamped behavior', () {
      const curve = AppPhysics.houseSpringCurve;
      expect(curve.transform(0.0), equals(0.0));
      expect(curve.transform(1.0), equals(1.0));

      // At t=0.5 (midpoint of transition), spring evaluation returns smooth interpolation
      final midVal = curve.transform(0.5);
      expect(midVal, greaterThan(0.0));
      expect(midVal, lessThan(1.5));
    });

    test('createHouseSpringSimulation creates valid SpringSimulation with velocity', () {
      final sim = AppPhysics.createHouseSpringSimulation(
        start: 0.0,
        end: 100.0,
        velocity: 500.0,
      );

      expect(sim.x(0.0), equals(0.0));
      expect(sim.dx(0.0), equals(500.0));
      expect(sim.isDone(0.0), isFalse);
      // At t=1.5s, spring position is near end target (100.0)
      expect((sim.x(1.5) - 100.0).abs(), lessThan(2.0));
    });

    test('OffsetSpringSimulation integrates 2D X and Y spring physics with velocity', () {
      final offsetSim = OffsetSpringSimulation(
        startX: 50.0,
        endX: 0.0,
        velocityX: 200.0,
        startY: -30.0,
        endY: 0.0,
        velocityY: -100.0,
      );

      final initialOffset = offsetSim.dxOffset(0.0);
      expect(initialOffset.dx, equals(50.0));
      expect(initialOffset.dy, equals(-30.0));

      // After settling time (~1.2s), simulation settles near target (0.0, 0.0)
      final settledOffset = offsetSim.dxOffset(1.2);
      expect(settledOffset.dx.abs(), lessThan(1.0));
      expect(settledOffset.dy.abs(), lessThan(1.0));
    });
  });
}
