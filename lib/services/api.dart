import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/trip.dart';

/// Every call to the backend lives here.
class Api {
  static SupabaseClient get sb => Supabase.instance.client;
  static User? get user => sb.auth.currentUser;
  static Profile? _me;

  // ---------- auth ----------
  static Future<bool> usernameAvailable(String username) async {
    final r = await sb.rpc('username_available', params: {'p_username': username});
    return r == true;
  }

  static Future<AuthResponse> signUp(String email, String password, String username) =>
      sb.auth.signUp(email: email, password: password, data: {'username': username});

  static Future<AuthResponse> signIn(String email, String password) =>
      sb.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() async {
    _me = null;
    await sb.auth.signOut();
  }

  // ---------- profile ----------
  static Future<Profile?> myProfile({bool refresh = false}) async {
    if (_me != null && !refresh) return _me;
    final uid = user?.id;
    if (uid == null) return null;
    final row = await sb.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    _me = Profile.fromRow(row);
    return _me;
  }

  static Future<void> updateProfile({required String username, required String bikeName}) async {
    await sb.from('profiles').update({'username': username, 'bike_name': bikeName}).eq('id', user!.id);
    await myProfile(refresh: true);
  }

  static Future<void> uploadAvatar(File file) async {
    final uid = user!.id;
    final path = '$uid/avatar.jpg';
    final bucket = sb.storage.from('avatars');
    await bucket.upload(path, file, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    final url = '${bucket.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
    await sb.from('profiles').update({'avatar_url': url}).eq('id', uid);
    await myProfile(refresh: true);
  }

  // ---------- trips ----------
  static const _pendingKey = 'pending_trips';

  /// Returns 'saved', 'queued' (no internet - will retry) or 'error: ...'.
  static Future<String> saveTrip(Trip t) async {
    final row = t.toInsert(user!.id);
    try {
      await sb.from('trips').insert(row);
      return 'saved';
    } on PostgrestException catch (e) {
      return 'error: ${e.message}';
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingKey) ?? [];
      list.add(jsonEncode(row));
      await prefs.setStringList(_pendingKey, list);
      return 'queued';
    }
  }

  /// Retries rides that were recorded offline.
  static Future<void> flushPending() async {
    final uid = user?.id;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_pendingKey) ?? [];
    if (list.isEmpty) return;
    final keep = <String>[];
    for (final s in list) {
      try {
        final row = jsonDecode(s) as Map<String, dynamic>;
        if (row['user_id'] != uid) {
          keep.add(s);
          continue;
        }
        await sb.from('trips').insert(row);
      } on PostgrestException {
        // permanently rejected by the database: drop it
      } catch (_) {
        keep.add(s); // still offline: keep for next time
      }
    }
    await prefs.setStringList(_pendingKey, keep);
  }

  static Future<List<Trip>> myTrips() async {
    final uid = user!.id;
    final rows = await sb.from('trips').select().eq('user_id', uid).order('started_at', ascending: false).limit(100);
    return rows.map<Trip>((r) => Trip.fromRow(r)).toList();
  }

  // ---------- leaderboard ----------
  static Future<List<LeaderRow>> leaderboard() async {
    final rows = await sb.rpc('get_leaderboard') as List<dynamic>;
    return rows.map((r) => LeaderRow.fromRow(r as Map<String, dynamic>)).toList();
  }
}
