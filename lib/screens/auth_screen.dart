import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api.dart';
import '../theme.dart';
import '../util.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _user = TextEditingController();
  bool _signup = false;
  bool _busy = false;
  String? _msg;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _user.dispose();
    super.dispose();
  }

  void _say(String m) {
    if (mounted) setState(() => _msg = m);
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    final name = _user.text.trim();
    if (!email.contains('@')) {
      _say('Enter a valid email.');
      return;
    }
    if (pass.length < 6) {
      _say('Password must be at least 6 characters.');
      return;
    }
    if (_signup && !usernameRe.hasMatch(name)) {
      _say('Rider name: 3-20 letters, numbers or underscore.');
      return;
    }
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      if (_signup) {
        if (!await Api.usernameAvailable(name)) {
          _say('That rider name is taken.');
          return;
        }
        final r = await Api.signUp(email, pass, name);
        if (r.session == null) {
          if (mounted) setState(() => _signup = false);
          _say('Account created. Confirm your email, then log in.');
        }
      } else {
        await Api.signIn(email, pass);
      }
    } on AuthException catch (e) {
      _say(e.message);
    } catch (_) {
      _say('Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Biyaro',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                const Text('Free forever. No subscription.',
                    textAlign: TextAlign.center, style: TextStyle(color: BColors.muted)),
                const SizedBox(height: 32),
                if (_signup) ...[
                  TextField(
                    controller: _user,
                    decoration: const InputDecoration(labelText: 'Rider name'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSubmitted: (_) => _submit(),
                ),
                if (_msg != null) ...[
                  const SizedBox(height: 12),
                  Text(_msg!, style: const TextStyle(color: BColors.amber)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: const StadiumBorder()),
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_signup ? 'Create account' : 'Log in', style: const TextStyle(fontSize: 17)),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _signup = !_signup;
                            _msg = null;
                          }),
                  child: Text(_signup ? 'I already have an account' : 'New rider? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
