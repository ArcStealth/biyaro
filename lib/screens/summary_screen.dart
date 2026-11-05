import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/profile.dart';
import '../models/trip.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/share_card.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.trip, this.saveNow = false});
  final Trip trip;
  final bool saveNow; // true right after a ride, false when opening an old trip

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _cardKey = GlobalKey();
  Profile? _me;
  String _status = '';
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final p = await Api.myProfile();
      if (mounted) setState(() => _me = p);
    } catch (_) {}
    if (!widget.saveNow) return;
    if (mounted) setState(() => _status = 'Saving...');
    final r = await Api.saveTrip(widget.trip);
    if (!mounted) return;
    setState(() {
      _status = r == 'saved'
          ? 'Saved to your account'
          : r == 'queued'
              ? 'No internet - saved on this phone, will upload later'
              : 'Could not save ($r)';
    });
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/biyaro_ride.png');
      await file.writeAsBytes(data!.buffer.asUint8List());
      final km = (widget.trip.distanceM / 1000).toStringAsFixed(1);
      await Share.shareXFiles([XFile(file.path)], text: 'I rode $km km with Biyaro!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.saveNow ? 'Ride complete' : 'Ride details'),
        backgroundColor: BColors.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: RepaintBoundary(key: _cardKey, child: ShareCard(trip: widget.trip, profile: _me)),
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: BColors.muted, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: const Icon(Icons.share),
            label: const Text('Share ride'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder()),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
