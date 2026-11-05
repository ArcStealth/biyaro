import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/stat_card.dart';
import 'summary_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});
  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late Future<List<Trip>> _f = Api.myTrips();

  Future<void> _reload() async {
    setState(() => _f = Api.myTrips());
    await _f;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Trip>>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Could not load your trips.', style: TextStyle(color: BColors.muted)),
              TextButton(onPressed: _reload, child: const Text('Retry')),
            ]),
          );
        }
        final trips = snap.data ?? [];
        final life = Trip.sum(trips);
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Lifetime stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              StatGrid(items: [('Total trips', '${trips.length}'), ...life.statList]),
              const SizedBox(height: 20),
              const Text('Your rides', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (trips.isEmpty)
                const Text('No rides yet. Hit Start ride and go.', style: TextStyle(color: BColors.muted)),
              for (final t in trips)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: BColors.card, borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text('${(t.distanceM / 1000).toStringAsFixed(1)} km - ${fmtDuration(t.durationS)}'),
                    subtitle: Text(fmtDate(t.startedAt), style: const TextStyle(color: BColors.muted)),
                    trailing: Text('${(t.topSpeedMs * 3.6).round()} km/h', style: const TextStyle(color: BColors.accent)),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => SummaryScreen(trip: t))),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
