import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_team.dart';
//import 'package:open_brawl/objects/ub_player.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/screens/screen_login.dart';
import 'package:open_brawl/screens/screen_profile_edit.dart';
import 'package:open_brawl/screens/screen_team_select.dart';
import 'package:open_brawl/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isCheckingAuth = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final providerServer = context.read<ProviderServer>();
    await providerServer.initialize();

    if (!mounted) return;

    final user = providerServer.currentUser;
    if (user != null) {
      await _validateUser(user);
    }

    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  Future<void> _validateUser(User user) async {
    final providerServer = context.read<ProviderServer>();
    final profile = await providerServer.getProfile(user.id);

    if (!mounted) return;

    if (profile == null) {
      await providerServer.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not found. Please sign up.')),
        );
      }
      return;
    }

    final isEnabled = profile['isEnabled'] ?? false;
    final username = profile['username'] ?? '';

    if (!isEnabled) {
      await providerServer.signOut();
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Account Not Enabled'),
            content: const Text(
              'Your account has not been enabled yet. Please contact an administrator.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (username.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ScreenProfileEdit(),
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderServer>(
      builder: (context, providerServer, child) {
        if (_isCheckingAuth || providerServer.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = providerServer.currentUser;
        if (user != null && !_isNavigating) {
          _isNavigating = true;
          _validateUser(user);
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (user == null) {
          _isNavigating = false;
        }

        return const ScreenLogin();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Team Select"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<ProviderServer>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const ScreenLogin(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: ScreenTeamSelect(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.read<ProviderTeam>().addTeam(
            ObjectTeam.createTeam("New Team", ""),
          );
        },

        child: const Icon((Icons.add)),
      ),
    );
  }
}
