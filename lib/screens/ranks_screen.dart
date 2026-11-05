import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/stat_card.dart';

class RanksScreen extends StatefulWidget {
  const RanksScreen({super.key});
  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> {
  String _k = 'dist';
  late Future<List<LeaderRow>> _f = Api.leaderboard();

  double _val(LeaderRow r) => _k == 'dist' ? r.totalKm : (_k == 'top' ? r.topSpeedKmh : r.trips.toDouble());
  String _fmt(LeaderRow r) =>
      _k == 'dist' ? '${r.totalKm.toStringAsFixed(1)} km' : (_k == 'top' ? '${r.topSpeedKmh.round()} km/h' : '${r.trips} trips');

  Future<void> _reload() async {
    setState(() => _f = Api.leaderboard());
    await _f;
  }

  void _details(LeaderRow r) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: BColors.card,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (r.avatarUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  r.avatarUrl!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.two_wheeler, size: 80, color: BColors.accent),
                ),
              )
            else
              const Icon(Icons.two_wheeler, size: 80, color: BColors.accent),
            const SizedBox(height: 12),
            Text(r.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(r.bikeLabel, style: const TextStyle(color: BColors.muted)),
            const SizedBox(height: 10),
            Text('${r.totalKm.toStringAsFixed(1)} km  -  ${r.topSpeedKmh.round()} km/h top  -  ${r.trips} trips',
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = Api.user?.id;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'dist', label: Text('Distance')),
              ButtonSegment(value: 'top', label: Text('Top speed')),
              ButtonSegment(value: 'trips', label: Text('Trips')),
            ],
            selected: {_k},
            onSelectionChanged: (s) => setState(() => _k = s.first),
          ),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<LeaderRow>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Could not load the leaderboard.', style: TextStyle(color: BColors.muted)),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ]),
              );
            }
            final rows = [...(snap.data ?? <LeaderRow>[])]..sort((a, b) => _val(b).compareTo(_val(a)));
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('No riders on the board yet. Finish a ride to be first!',
                          textAlign: TextAlign.center, style: TextStyle(color: BColors.muted)),
                    ),
                  for (var i = 0; i < rows.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: BColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: rows[i].userId == me ? Border.all(color: BColors.accent) : null,
                      ),
                      child: ListTile(
                        onTap: () => _details(rows[i]),
                        leading: Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(
                            width: 28,
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: i < 3 ? BColors.amber : BColors.muted)),
                          ),
                          Avatar(url: rows[i].avatarUrl, radius: 22),
                        ]),
                        title: Text(rows[i].username, overflow: TextOverflow.ellipsis),
                        subtitle: Text(rows[i].bikeLabel,
                            overflow: TextOverflow.ellipsis, style: const TextStyle(color: BColors.muted)),
                        trailing: Text(_fmt(rows[i]), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }
}
