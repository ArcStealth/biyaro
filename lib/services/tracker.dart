import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart' show AndroidSettings, ForegroundNotificationConfig;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/trip.dart';
import 'trip_engine.dart';

/// Owns GPS + accelerometer subscriptions and a [TripEngine].
/// GPS runs inside an Android foreground service, so tracking continues
/// when the screen is off or the app is in the background.
class Tracker extends ChangeNotifier {
  Tracker._();
  static final Tracker instance = Tracker._();

  TripEngine? _engine;
  StreamSubscription<Position>? _pos;
  StreamSubscription<UserAccelerometerEvent>? _acc;
  Timer? _timer;

  bool get running => _engine != null;
  TripEngine? get engine => _engine;

  /// Returns null on success, or a message to show the rider.
  Future<String?> start() async {
    if (running) return null;
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Turn on Location (GPS) first.';
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      return 'Location permission is needed to track rides.';
    }
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return 'Allow Location for Biyaro in Settings, then try again.';
    }
    await ph.Permission.notification.request(); // Android 13+: shows the tracking notification

    _engine = TripEngine();
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 1),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Biyaro - ride in progress',
        notificationText: 'Tracking your ride. Tap to return to the app.',
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
    _pos = Geolocator.getPositionStream(locationSettings: settings).listen(_onPos, onError: (_) {});
    _acc = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((e) {
      _engine?.onSensorG(math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.81);
    }, onError: (_) {});
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    await WakelockPlus.enable();
    notifyListeners();
    return null;
  }

  void _onPos(Position p) {
    final DateTime? ts = p.timestamp;
    _engine?.onFix(GpsFix(
      lat: p.latitude,
      lng: p.longitude,
      speed: p.speed,
      heading: p.heading,
      accuracy: p.accuracy,
      t: (ts ?? DateTime.now()).millisecondsSinceEpoch / 1000.0,
    ));
    notifyListeners();
  }

  /// Stops tracking and returns the finished trip (null if nothing was running).
  Trip? stop() {
    final e = _engine;
    if (e == null) return null;
    _pos?.cancel();
    _acc?.cancel();
    _timer?.cancel();
    WakelockPlus.disable();
    _engine = null;
    notifyListeners();
    return e.finish();
  }
}
