import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../models/trip.dart';
import '../theme.dart';
import '../util.dart';
import 'route_painter.dart';
import 'stat_card.dart';

/// The card riders see after a ride AND the picture that gets shared.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.trip, this.profile});
  final Trip trip;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final stats = trip.statList.skip(1).toList(); // distance is shown big above
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06201F), Color(0xFF000000)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Text('BIYARO',
                style: TextStyle(
                    color: BColors.accent, fontSize: 22, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
            const Spacer(),
            Text(fmtDate(trip.startedAt), style: const TextStyle(color: BColors.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Avatar(url: profile?.avatarUrl, radius: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile?.username ?? 'Rider',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text(profile?.bikeLabel ?? '',
                    style: const TextStyle(color: BColors.muted, fontSize: 13), overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text((trip.distanceM / 1000).toStringAsFixed(1),
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(width: 8),
            const Text('km ridden', style: TextStyle(color: BColors.muted, fontSize: 18)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 170,
              color: const Color(0xFF14141A),
              child: CustomPaint(painter: RoutePainter(trip.route), size: Size.infinite),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 16) / 3;
            return Wrap(spacing: 8, runSpacing: 10, children: [
              for (final s in stats)
                SizedBox(
                  width: w,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: const TextStyle(color: BColors.muted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(s.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]);
          }),
        ],
      ),
    );
  }
}
