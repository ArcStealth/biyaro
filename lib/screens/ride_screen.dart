import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/tracker.dart';
import '../theme.dart';
import '../widgets/route_painter.dart';
import '../widgets/stat_card.dart';
import 'summary_screen.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});
  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  final _t = Tracker.instance;

  @override
  void initState() {
    super.initState();
    _t.addListener(_update);
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _t.removeListener(_update);
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _toggle() async {
    if (!_t.running) {
      final err = await _t.start();
      if (err != null) _snack(err);
      return;
    }
    final trip = _t.stop();
    if (trip == null) return;
    if (trip.distanceM < 50) {
      _snack('Ride too short to save (under 50 m).');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SummaryScreen(trip: trip, saveNow: true)));
  }

  @override
  Widget build(BuildContext context) {
    final e = _t.engine;
    final snap = e?.snapshot() ?? Trip(startedAt: DateTime.now());
    final kmh = ((e?.currentSpeedMs ?? 0) * 3.6).round();
    final running = _t.running;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Row(children: [
          Text('Biyaro', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
          SizedBox(width: 10),
          Text('Free forever. No subscription.', style: TextStyle(color: BColors.muted, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        Center(
          child: Column(children: [
            Text('$kmh', style: const TextStyle(fontSize: 88, fontWeight: FontWeight.w800, height: 1)),
            const Text('km/h', style: TextStyle(color: BColors.muted)),
          ]),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 220,
            color: BColors.card,
            child: CustomPaint(painter: RoutePainter(e?.route ?? const <RoutePoint>[]), size: Size.infinite),
          ),
        ),
        const SizedBox(height: 12),
        StatGrid(items: snap.statList),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _toggle,
          style: FilledButton.styleFrom(
            backgroundColor: running ? BColors.red : BColors.accent,
            foregroundColor: running ? Colors.white : Colors.black,
            minimumSize: const Size.fromHeight(56),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          child: Text(running ? 'Stop ride' : 'Start ride'),
        ),
        const SizedBox(height: 8),
        Text(
          running
              ? 'Tracking continues if you lock the screen. Mount your phone securely.'
              : 'Tip: mount your phone firmly so G-force readings are accurate.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: BColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
