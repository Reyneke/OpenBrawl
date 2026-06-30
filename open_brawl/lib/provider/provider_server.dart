import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProviderServer extends ChangeNotifier {
  String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  SupabaseClient? _client;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _client!.auth.currentUser;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to initialize Supabase: $e';
      notifyListeners();
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final Map<String, dynamic> userData = {};
      if (username != null && username.isNotEmpty) {
        userData['username'] = username;
        userData['avatar_url'] = "none";
      }

      final AuthResponse response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );

      if (response.user != null) {
        await _client!.from('profiles').insert({
          'id': response.user!.id,
          'username': username ?? '',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      _isLoading = false;
      notifyListeners();

      return response;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign up failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final AuthResponse response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();

      return response;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign in failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _client!.auth.signOut();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign out failed: $e';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? website,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (username != null && username.isNotEmpty) {
        updateData['username'] = username;
      }
      if (fullName != null && fullName.isNotEmpty) {
        updateData['full_name'] = fullName;
      }
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        updateData['avatar_url'] = avatarUrl;
      }
      if (website != null && website.isNotEmpty) {
        updateData['website'] = website;
      }

      await _client!.from('profiles').update(updateData).eq('id', userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
