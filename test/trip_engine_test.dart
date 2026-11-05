import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:biyaro/services/trip_engine.dart';

/// Builds one GPS fix per second moving along the given headings (degrees).
TripEngine drive(List<double> headings, {List<double>? speeds, double defaultSpeed = 10}) {
  var lat = 14.5, lng = 121.0;
  final e = TripEngine();
  for (var i = 0; i < headings.length; i++) {
    final v = speeds != null ? speeds[i] : defaultSpeed;
    final h = headings[i] * math.pi / 180;
    lat += math.cos(h) * v / 111320;
    lng += math.sin(h) * v / (111320 * math.cos(lat * math.pi / 180));
    e.onFix(GpsFix(lat: lat, lng: lng, speed: v, heading: headings[i] % 360, accuracy: 5, t: 1000.0 + i));
  }
  return e;
}

void main() {
  test('distance adds up', () {
    final e = drive(List.filled(11, 0.0));
    expect(e.distanceM, closeTo(100, 3));
    expect(e.topSpeedMs, closeTo(10, 0.01));
  });

  test('left turn is counted once', () {
    final hs = <double>[0, 0, 0, 0, for (var i = 1; i <= 6; i++) 360 - 15.0 * i, 270, 270, 270, 270];
    final e = drive(hs);
    expect(e.left, 1);
    expect(e.right, 0);
  });

  test('right turn is counted once', () {
    final hs = <double>[0, 0, 0, 0, for (var i = 1; i <= 6; i++) 15.0 * i, 90, 90, 90, 90];
    final e = drive(hs);
    expect(e.right, 1);
    expect(e.left, 0);
  });

  test('small swerve and back is a lane change, not a turn', () {
    final e = drive([0, 0, 0, 8, 8, 8, 0, 0, 0, 0]);
    expect(e.lanes, 1);
    expect(e.left + e.right, 0);
  });

  test('heading noise on a straight road counts nothing', () {
    final e = drive([0, 1, 359, 1, 0, 2, 358, 0, 1, 0]);
    expect(e.left + e.right + e.lanes, 0);
  });

  test('hard braking is a brake event', () {
    final e = drive(List.filled(8, 0.0), speeds: [10, 10, 10, 4, 4, 4, 4, 4]);
    expect(e.brakes, 1);
    expect(e.maxDecel, closeTo(6, 0.01));
  });

  test('standing still accumulates stopped time, not distance', () {
    final e = drive(List.filled(6, 0.0), speeds: [10, 10, 0, 0, 0, 0]);
    expect(e.stoppedS, greaterThan(3));
  });
}
