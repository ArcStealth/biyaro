import 'dart:math' as math;
import '../util.dart';

class RoutePoint {
  const RoutePoint(this.lat, this.lng, this.speed);
  final double lat;
  final double lng;
  final double speed; // m/s

  List<double> toJson() => [
        double.parse(lat.toStringAsFixed(5)),
        double.parse(lng.toStringAsFixed(5)),
        double.parse(speed.toStringAsFixed(1)),
      ];

  factory RoutePoint.fromJson(List<dynamic> j) => RoutePoint(
        (j[0] as num).toDouble(),
        (j[1] as num).toDouble(),
        (j[2] as num).toDouble(),
      );
}

class Trip {
  const Trip({
    this.id,
    required this.startedAt,
    this.durationS = 0,
    this.distanceM = 0,
    this.stoppedS = 0,
    this.topSpeedMs = 0,
    this.leftTurns = 0,
    this.rightTurns = 0,
    this.brakeEvents = 0,
    this.laneChanges = 0,
    this.maxDecel = 0,
    this.maxAccel = 0,
    this.peakG = 0,
    this.route = const [],
  });

  final String? id;
  final DateTime startedAt;
  final double durationS, distanceM, stoppedS, topSpeedMs, maxDecel, maxAccel, peakG;
  final int leftTurns, rightTurns, brakeEvents, laneChanges;
  final List<RoutePoint> route;

  double get avgMovingKmh {
    final moving = math.max(1.0, durationS - stoppedS);
    return distanceM / moving * 3.6;
  }

  /// Label/value pairs, in the same order everywhere in the app.
  List<(String, String)> get statList => [
        ('Distance', '${(distanceM / 1000).toStringAsFixed(1)} km'),
        ('Duration', fmtDuration(durationS)),
        ('Stopped time', fmtDuration(stoppedS)),
        ('Top speed', '${(topSpeedMs * 3.6).round()} km/h'),
        ('Avg moving speed', '${avgMovingKmh.round()} km/h'),
        ('Peak G-force', '${peakG.toStringAsFixed(2)} G'),
        ('Left turns', '$leftTurns'),
        ('Right turns', '$rightTurns'),
        ('Brake events', '$brakeEvents'),
        ('Lane changes', '$laneChanges'),
        ('Max deceleration', '${maxDecel.toStringAsFixed(1)} m/s\u00B2'),
        ('Max acceleration', '${maxAccel.toStringAsFixed(1)} m/s\u00B2'),
      ];

  Map<String, dynamic> toInsert(String userId) => {
        'user_id': userId,
        'started_at': startedAt.toUtc().toIso8601String(),
        'duration_s': durationS,
        'distance_m': distanceM,
        'stopped_s': stoppedS,
        'top_speed_ms': math.min(topSpeedMs, 110.0),
        'left_turns': leftTurns,
        'right_turns': rightTurns,
        'brake_events': brakeEvents,
        'lane_changes': laneChanges,
        'max_decel': math.min(maxDecel, 30.0),
        'max_accel': math.min(maxAccel, 30.0),
        'peak_g': math.min(peakG, 25.0),
        'route': route.map((p) => p.toJson()).toList(),
      };

  factory Trip.fromRow(Map<String, dynamic> r) => Trip(
        id: r['id'] as String?,
        startedAt: DateTime.parse(r['started_at'] as String),
        durationS: (r['duration_s'] as num).toDouble(),
        distanceM: (r['distance_m'] as num).toDouble(),
        stoppedS: (r['stopped_s'] as num).toDouble(),
        topSpeedMs: (r['top_speed_ms'] as num).toDouble(),
        leftTurns: (r['left_turns'] as num).toInt(),
        rightTurns: (r['right_turns'] as num).toInt(),
        brakeEvents: (r['brake_events'] as num).toInt(),
        laneChanges: (r['lane_changes'] as num).toInt(),
        maxDecel: (r['max_decel'] as num).toDouble(),
        maxAccel: (r['max_accel'] as num).toDouble(),
        peakG: (r['peak_g'] as num).toDouble(),
        route: ((r['route'] as List<dynamic>?) ?? const [])
            .map((p) => RoutePoint.fromJson(p as List<dynamic>))
            .toList(),
      );

  /// Lifetime totals across many trips (maxima for top speed / decel / accel / G).
  static Trip sum(List<Trip> list) {
    double dist = 0, dur = 0, stop = 0, top = 0, dec = 0, acc = 0, g = 0;
    int l = 0, r = 0, b = 0, ln = 0;
    for (final t in list) {
      dist += t.distanceM;
      dur += t.durationS;
      stop += t.stoppedS;
      top = math.max(top, t.topSpeedMs);
      dec = math.max(dec, t.maxDecel);
      acc = math.max(acc, t.maxAccel);
      g = math.max(g, t.peakG);
      l += t.leftTurns;
      r += t.rightTurns;
      b += t.brakeEvents;
      ln += t.laneChanges;
    }
    return Trip(
      startedAt: DateTime.now(),
      durationS: dur,
      distanceM: dist,
      stoppedS: stop,
      topSpeedMs: top,
      leftTurns: l,
      rightTurns: r,
      brakeEvents: b,
      laneChanges: ln,
      maxDecel: dec,
      maxAccel: acc,
      peakG: g,
    );
  }
}
