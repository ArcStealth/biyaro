import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Config.supabaseUrl, anonKey: Config.supabaseAnonKey);
  runApp(const BiyaroApp());
}

class BiyaroApp extends StatelessWidget {
  const BiyaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biyaro',
      debugShowCheckedModeBanner: false,
      theme: biyaroTheme(),
      home: const AuthGate(),
    );
  }
}

/// Shows the login screen or the app, depending on whether a session exists.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        return auth.currentSession != null ? const HomeShell() : const AuthScreen();
      },
    );
  }
}
