class Profile {
  const Profile({required this.id, required this.username, this.bikeName, this.avatarUrl});
  final String id;
  final String username;
  final String? bikeName;
  final String? avatarUrl;

  String get bikeLabel => (bikeName == null || bikeName!.trim().isEmpty) ? 'No bike listed' : bikeName!;

  factory Profile.fromRow(Map<String, dynamic> r) => Profile(
        id: r['id'] as String,
        username: r['username'] as String,
        bikeName: r['bike_name'] as String?,
        avatarUrl: r['avatar_url'] as String?,
      );
}

class LeaderRow {
  const LeaderRow({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.bikeName,
    required this.totalKm,
    required this.topSpeedKmh,
    required this.trips,
  });
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? bikeName;
  final double totalKm;
  final double topSpeedKmh;
  final int trips;

  String get bikeLabel => (bikeName == null || bikeName!.trim().isEmpty) ? 'No bike listed' : bikeName!;

  factory LeaderRow.fromRow(Map<String, dynamic> r) => LeaderRow(
        userId: r['user_id'] as String,
        username: r['username'] as String,
        avatarUrl: r['avatar_url'] as String?,
        bikeName: r['bike_name'] as String?,
        totalKm: (r['total_km'] as num).toDouble(),
        topSpeedKmh: (r['top_speed_kmh'] as num).toDouble(),
        trips: (r['trip_count'] as num).toInt(),
      );
}
