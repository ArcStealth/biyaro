import 'package:flutter/material.dart';
import '../services/api.dart';
import 'profile_screen.dart';
import 'ranks_screen.dart';
import 'ride_screen.dart';
import 'trips_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    Api.flushPending(); // upload rides recorded while offline
  }

  Widget _page() {
    switch (_i) {
      case 1:
        return const TripsScreen();
      case 2:
        return const RanksScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const RideScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _page()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.speed), label: 'Ride'),
          NavigationDestination(icon: Icon(Icons.route), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Ranks'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
