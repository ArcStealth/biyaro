import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/stat_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _bike = TextEditingController();
  Profile? _p;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _bike.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _load() async {
    try {
      final p = await Api.myProfile(refresh: true);
      if (!mounted) return;
      setState(() {
        _p = p;
        _name.text = p?.username ?? '';
        _bike.text = p?.bikeName ?? '';
      });
    } catch (_) {
      _snack('Could not load your profile.');
    }
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (x == null) return;
    setState(() => _busy = true);
    try {
      await Api.uploadAvatar(File(x.path));
      await _load();
      _snack('Photo updated');
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (!usernameRe.hasMatch(name)) {
      _snack('Rider name: 3-20 letters, numbers or underscore.');
      return;
    }
    setState(() => _busy = true);
    try {
      await Api.updateProfile(username: name, bikeName: _bike.text.trim());
      await _load();
      _snack('Profile saved');
    } on PostgrestException catch (e) {
      _snack(e.code == '23505' ? 'That rider name is taken.' : e.message);
    } catch (_) {
      _snack('Could not save. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Your profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _busy ? null : _pickPhoto,
            child: Stack(children: [
              Avatar(url: _p?.avatarUrl, radius: 60),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: BColors.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        const Text('Tap to add a photo of you and your motorcycle',
            textAlign: TextAlign.center, style: TextStyle(color: BColors.muted, fontSize: 12)),
        const SizedBox(height: 20),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Rider name')),
        const SizedBox(height: 12),
        TextField(
          controller: _bike,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Motorcycle (e.g. Motorstar Cafe 150)'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder()),
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save profile'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : Api.signOut,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder()),
          child: const Text('Log out'),
        ),
        const SizedBox(height: 20),
        const Text('Biyaro v0.1.0-alpha',
            textAlign: TextAlign.center, style: TextStyle(color: BColors.muted, fontSize: 12)),
      ],
    );
  }
}
