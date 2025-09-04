import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../utils/environment_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static bool _isInitialized = false;
  
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseService._();

  static SupabaseClient? get client {
    try {
      return _isInitialized ? Supabase.instance.client : null;
    } catch (e) {
      return null;
    }
  }
  
  static final _config = EnvironmentConfig.instance;
  
  // Check if Supabase is properly initialized
  static bool get isInitialized => _isInitialized;
  
  // Helper method to ensure client is available
  SupabaseClient get _safeClient {
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase is not initialized. Please ensure Supabase.initialize() is called first.');
    }
    return clientInstance;
  }

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      if (_config.isDebugMode) {
        debugPrint('=== SUPABASE INITIALIZATION DEBUG ===');
        debugPrint('Attempting to initialize Supabase...');
        debugPrint('URL: ${_config.supabaseUrl}');
        debugPrint('URL Length: ${_config.supabaseUrl.length}');
        debugPrint('URL starts with https: ${_config.supabaseUrl.startsWith('https://')}');
        debugPrint('Anon Key Length: ${_config.supabaseAnonKey.length}');
        debugPrint('Anon Key starts with ey: ${_config.supabaseAnonKey.startsWith('ey')}');
        debugPrint('Is Configured: ${_config.isSupabaseConfigured}');
        debugPrint('=====================================');
      }
      
      if (!_config.isSupabaseConfigured) {
        final message = 'Supabase configuration incomplete - URL empty: ${_config.supabaseUrl.isEmpty}, Key empty: ${_config.supabaseAnonKey.isEmpty}';
        if (_config.isDebugMode) {
          debugPrint('ERROR: $message');
        }
        throw Exception(message);
      }

      if (_config.isDebugMode) {
        debugPrint('Configuration validated. Calling Supabase.initialize()...');
      }

      await Supabase.initialize(
        url: _config.supabaseUrl,
        anonKey: _config.supabaseAnonKey,
        debug: _config.isDebugMode,
      );
      
      _isInitialized = true;
      
      if (_config.isDebugMode) {
        debugPrint('✓ Supabase initialized successfully');
        debugPrint('Client available: ${client != null}');
      }
    } catch (e, stackTrace) {
      _isInitialized = false;
      if (_config.isDebugMode) {
        debugPrint('✗ Failed to initialize Supabase: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => client?.auth.currentUser != null;

  // Get current user
  User? get currentUser => client?.auth.currentUser;

  // Get current user email
  String? get currentUserEmail => currentUser?.email;

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _safeClient.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      if (_config.isDebugMode) {
        debugPrint('User signed up: ${response.user?.email}');
      }

      return response;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Sign up error: $e');
      }
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _safeClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (_config.isDebugMode) {
        debugPrint('User signed in: ${response.user?.email}');
      }

      return response;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Sign in error: $e');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _safeClient.auth.signOut();
      
      if (_config.isDebugMode) {
        debugPrint('User signed out');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Sign out error: $e');
      }
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _safeClient.auth.resetPasswordForEmail(email);
      
      if (_config.isDebugMode) {
        debugPrint('Password reset email sent to: $email');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Password reset error: $e');
      }
      rethrow;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges {
    try {
      return _safeClient.auth.onAuthStateChange;
    } catch (e) {
      // Return empty stream if client is not available
      return const Stream.empty();
    }
  }

  // Update user profile
  Future<UserResponse> updateProfile({
    String? name,
    Map<String, dynamic>? data,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (name != null) {
        updates['name'] = name;
      }
      
      if (data != null) {
        updates.addAll(data);
      }

      final response = await _safeClient.auth.updateUser(
        UserAttributes(data: updates),
      );

      if (_config.isDebugMode) {
        debugPrint('User profile updated');
      }

      return response;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Update profile error: $e');
      }
      rethrow;
    }
  }

  // Get user metadata
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  // Get user name
  String? get userName {
    try {
      return userMetadata?['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  // Resend confirmation email
  Future<void> resendConfirmationEmail() async {
    if (currentUser?.email == null) {
      throw Exception('No user email found');
    }

    try {
      await _safeClient.auth.resend(
        type: OtpType.signup,
        email: currentUser!.email!,
      );
      
      if (_config.isDebugMode) {
        debugPrint('Confirmation email resent to: ${currentUser!.email}');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Resend confirmation error: $e');
      }
      rethrow;
    }
  }

  // Get configuration status
  Map<String, dynamic> getConfigStatus() {
    return {
      'configured': _config.isSupabaseConfigured,
      'authenticated': isAuthenticated,
      'email_verified': isEmailVerified,
      'user_email': currentUserEmail,
      'user_name': userName,
      'supabase_url': _config.supabaseUrl.isNotEmpty ? 'Configured' : 'Not configured',
      'anon_key': _config.supabaseAnonKey.isNotEmpty ? 'Configured' : 'Not configured',
    };
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  // Get password requirements text
  static String getPasswordRequirements() {
    return 'Password must be at least 8 characters long and contain:\n'
           '• At least one uppercase letter (A-Z)\n'
           '• At least one lowercase letter (a-z)\n'
           '• At least one number (0-9)';
  }
}