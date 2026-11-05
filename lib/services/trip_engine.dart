import 'dart:math' as math;
import '../models/trip.dart';

/// One GPS reading. [t] is in seconds.
class GpsFix {
  const GpsFix({
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.accuracy,
    required this.t,
  });
  final double lat;
  final double lng;
  final double? speed; // m/s, null if unknown
  final double? heading; // degrees clockwise from north, null if unknown
  final double accuracy; // metres
  final double t;
}

/// Pure-Dart ride analytics: no Flutter, no plugins, so it can be unit-tested.
/// Feed it GPS fixes and accelerometer readings; it keeps the stats.
class TripEngine {
  TripEngine({DateTime? startedAt}) : startedAt = startedAt ?? DateTime.now();

  final DateTime startedAt;
  final List<RoutePoint> route = [];

  double distanceM = 0, stoppedS = 0, topSpeedMs = 0;
  double maxAccel = 0, maxDecel = 0, peakG = 0;
  int left = 0, right = 0, brakes = 0, lanes = 0;
  double currentSpeedMs = 0;

  // --- tuning knobs (adjust after real rides) ---
  static const maxAccuracyM = 35.0; // ignore fixes worse than this
  static const stoppedBelowMs = 0.8; // under ~3 km/h counts as stopped
  static const headingMinSpeedMs = 3.5; // GPS heading is junk when slow
  static const turnMinDeg = 60.0; // accumulated heading change = a turn
  static const laneMinDeg = 4.0, laneMaxDeg = 30.0; // small swerve = lane change
  static const laneWindowS = 8.0; // swerve there-and-back within this time
  static const brakeDecelMs2 = 2.5; // harder than this = brake event

  GpsFix? _last;
  double _lastSpeed = 0;
  double? _lastHeading;
  bool _braking = false;
  double _segAcc = 0, _segT = 0;
  bool _segOpen = false;
  bool _hasPrev = false;
  double _prevA = 0, _prevT = 0;
  double _sensorG = 0;

  static double haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0, k = math.pi / 180;
    final dLat = (lat2 - lat1) * k, dLng = (lng2 - lng1) * k;
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * k) * math.cos(lat2 * k) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  void onFix(GpsFix f) {
    if (f.accuracy > maxAccuracyM) return;
    final last = _last;
    if (last == null) {
      _last = f;
      route.add(RoutePoint(f.lat, f.lng, 0));
      return;
    }
    final dt = f.t - last.t;
    if (dt <= 0) return;
    final d = haversine(last.lat, last.lng, f.lat, f.lng);

    var sp = f.speed ?? d / dt;
    if (sp < 0.1 && d / dt > 1.5) sp = d / dt; // some phones report 0 wrongly
    if (sp > 100) return; // > 360 km/h is a GPS glitch

    if (sp < stoppedBelowMs) {
      sp = 0;
      stoppedS += dt;
    } else {
      distanceM += d;
    }
    if (sp > topSpeedMs) topSpeedMs = sp;

    // acceleration / braking from speed change
    if (dt <= 3) {
      final a = (sp - _lastSpeed) / dt;
      if (a > maxAccel) maxAccel = math.min(a, 12.0);
      if (-a > maxDecel) maxDecel = math.min(-a, 12.0);
      if (a < -brakeDecelMs2 && !_braking) {
        brakes++;
        _braking = true;
      } else if (a > -1) {
        _braking = false;
      }
      peakG = math.max(peakG, math.min(a.abs() / 9.81, 10.0));
    }

    // turns and lane changes from heading changes
    final hRaw = f.heading;
    final h = (hRaw != null && hRaw >= 0 && sp > headingMinSpeedMs) ? hRaw : null;
    final lh = _lastHeading;
    if (h != null && lh != null) {
      final dh = ((h - lh + 540) % 360) - 180;
      if (dh.abs() >= 2.5) {
        _segAcc += dh;
        _segT = f.t;
        _segOpen = true;
      } else if (_segOpen && f.t - _segT >= 2) {
        _endSegment(f.t);
      }
    } else if (sp <= headingMinSpeedMs && _segOpen) {
      _endSegment(f.t);
    }
    _lastHeading = h;

    if (route.isEmpty || haversine(route.last.lat, route.last.lng, f.lat, f.lng) >= 3) {
      route.add(RoutePoint(f.lat, f.lng, sp));
    }
    _last = f;
    _lastSpeed = sp;
    currentSpeedMs = sp;
  }

  void _endSegment(double t) {
    final a = _segAcc;
    if (a.abs() >= turnMinDeg) {
      if (a < 0) {
        left++;
      } else {
        right++;
      }
      _hasPrev = false;
    } else if (a.abs() >= laneMinDeg) {
      if (_hasPrev &&
          _prevA.sign != a.sign &&
          t - _prevT < laneWindowS &&
          _prevA.abs() < laneMaxDeg &&
          a.abs() < laneMaxDeg) {
        lanes++;
        _hasPrev = false;
      } else {
        _prevA = a;
        _prevT = t;
        _hasPrev = true;
      }
    }
    _segAcc = 0;
    _segOpen = false;
  }

  /// Accelerometer reading in G (gravity already removed). Smoothed so engine
  /// vibration does not fake a huge peak.
  void onSensorG(double g) {
    _sensorG = 0.9 * _sensorG + 0.1 * g;
    if (_sensorG > peakG) peakG = math.min(_sensorG, 10.0);
  }

  /// Live view of the ride so far (does not end the ride).
  Trip snapshot() => Trip(
        startedAt: startedAt,
        durationS: DateTime.now().difference(startedAt).inMilliseconds / 1000.0,
        distanceM: distanceM,
        stoppedS: stoppedS,
        topSpeedMs: topSpeedMs,
        leftTurns: left,
        rightTurns: right,
        brakeEvents: brakes,
        laneChanges: lanes,
        maxDecel: maxDecel,
        maxAccel: maxAccel,
        peakG: peakG,
        route: route,
      );

  /// Ends the ride and returns the final record (route thinned for upload).
  Trip finish({int maxRoutePoints = 600}) {
    if (_segOpen && _last != null) _endSegment(_last!.t);
    final step = math.max(1, (route.length / maxRoutePoints).ceil());
    final thin = <RoutePoint>[];
    for (var i = 0; i < route.length; i += step) {
      thin.add(route[i]);
    }
    if (route.isNotEmpty && thin.last != route.last) thin.add(route.last);
    final s = snapshot();
    return Trip(
      startedAt: s.startedAt,
      durationS: math.max(1.0, s.durationS),
      distanceM: s.distanceM,
      stoppedS: s.stoppedS,
      topSpeedMs: s.topSpeedMs,
      leftTurns: s.leftTurns,
      rightTurns: s.rightTurns,
      brakeEvents: s.brakeEvents,
      laneChanges: s.laneChanges,
      maxDecel: s.maxDecel,
      maxAccel: s.maxAccel,
      peakG: s.peakG,
      route: thin,
    );
  }
}
