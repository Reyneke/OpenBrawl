import 'package:flutter/material.dart';
import 'package:open_brawl/main_app.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:provider/provider.dart';

class ScreenLogin extends StatefulWidget {
  const ScreenLogin({super.key});

  @override
  State<ScreenLogin> createState() => _ScreenLoginState();
}

class _ScreenLoginState extends State<ScreenLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final providerServer = context.read<ProviderServer>();

    try {
      if (_isSignUp) {
        await providerServer.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim().isEmpty
              ? null
              : _usernameController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign up successful! Please log in.')),
          );
          setState(() {
            _isSignUp = false;
            _usernameController.clear();
          });
        }
      } else {
        await providerServer.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Navigate to AuthGate after successful login so it can validate
        // the user session and route to the appropriate screen.
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AuthGate(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(providerServer.errorMessage ?? 'An error occurred'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Sign Up' : 'Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_martial_arts,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 32),
                Text(
                  _isSignUp ? 'Create Account' : 'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_isSignUp)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username (optional)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                if (_isSignUp) const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Consumer<ProviderServer>(
                  builder: (context, providerServer, child) {
                    return Column(
                      children: [
                        if (providerServer.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              providerServer.errorMessage!,
                              style: TextStyle(color: Colors.red.shade900),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ElevatedButton(
                          onPressed: providerServer.isLoading
                              ? null
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: providerServer.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isSignUp ? 'Sign Up' : 'Login'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Login'
                        : "Don't have an account? Sign Up",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
