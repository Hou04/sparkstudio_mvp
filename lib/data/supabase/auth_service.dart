/// 🔐 Advanced Authentication Service
///
/// Professional authentication service with email/password, social login,
/// session management, and security features.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService({required SupabaseClient client}) : _client = client;

  /// 👤 Current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// 🔐 Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// 📱 Current session
  Session? get currentSession => _client.auth.currentSession;

  /// 🔄 Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// ✉️ Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
    String? avatarUrl,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': displayName,
          'avatar_url': avatarUrl,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.user != null) {
        await _createUserProfile(response.user!);
        debugPrint('✅ User signed up: ${response.user!.email}');
      }

      return response.user;
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  /// 🔑 Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('✅ User signed in: ${response.user!.email}');
        await _updateLastLogin(response.user!);
      }

      return response.user;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  /// 🔓 Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      debugPrint('✅ User signed out');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  /// 📧 Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      debugPrint('✅ Password reset email sent to: $email');
    } catch (e) {
      debugPrint('❌ Password reset failed: $e');
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }

  /// 🔄 Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      debugPrint('✅ Password updated successfully');
    } catch (e) {
      debugPrint('❌ Password update failed: $e');
      throw AuthException('Password update failed: ${e.toString()}');
    }
  }

  /// 👤 Update user profile
  Future<void> updateProfile({
    required String displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw AuthException('No authenticated user');

      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': displayName,
            'bio': bio,
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      debugPrint('✅ Profile updated for: $displayName');
    } catch (e) {
      debugPrint('❌ Profile update failed: $e');
      throw AuthException('Profile update failed: ${e.toString()}');
    }
  }

  /// 🎯 Get user metadata
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  /// 📊 Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .filter('id', 'eq', user.id)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ Failed to get user profile: $e');
      return null;
    }
  }

  /// 🚀 Social login with provider
  Future<void> signInWithProvider(String provider) async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google, // Can be extended for other providers
        redirectTo: 'sparkstudio://login-callback',
      );
    } catch (e) {
      debugPrint('❌ Social login failed: $e');
      throw AuthException('Social login failed: ${e.toString()}');
    }
  }

  /// 🔍 Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      // This would typically check against your user database
      final response = await _client
          .from('profiles')
          .select('id')
          .filter('email', 'eq', email)
          .maybeSingle();

      return response == null;
    } catch (e) {
      debugPrint('❌ Email availability check failed: $e');
      return true; // Assume available if check fails
    }
  }

  /// 📱 Verify session is still valid
  Future<bool> verifySession() async {
    try {
      final session = currentSession;
      if (session == null) return false;

      // Check if session is expired
      if (session.expiresAt != null &&
          session.expiresAt! < DateTime.now().millisecondsSinceEpoch) {
        await signOut();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Session verification failed: $e');
      return false;
    }
  }

  // 🛠️ PRIVATE HELPER METHODS

  /// Create user profile in database
  Future<void> _createUserProfile(User user) async {
    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? 'Anonymous',
        'avatar_url': user.userMetadata?['avatar_url'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'streak_count': 0,
        'total_submissions': 0,
        'total_cheers_received': 0,
      });
    } catch (e) {
      debugPrint('⚠️ Failed to create user profile: $e');
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(User user) async {
    try {
      await _client
          .from('profiles')
          .update({
            'last_login_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .filter('id', 'eq', user.id);
    } catch (e) {
      debugPrint('⚠️ Failed to update last login: $e');
    }
  }

  /// 🧪 MOCK DATA FOR DEVELOPMENT
  Future<User?> mockSignIn() async {
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('✅ Mock user signed in');
    return null; // In real implementation, return actual user
  }

  Future<void> mockSignUp() async {
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('✅ Mock user signed up');
  }
}

/// 🚨 Authentication Exception
class AuthException implements Exception {
  final String message;
  final DateTime timestamp;

  AuthException(this.message) : timestamp = DateTime.now();

  @override
  String toString() => 'AuthException: $message';
}

/// 🔧 Auth State Extension
extension AuthStateExtensions on AuthState {
  bool get isSignedIn => this.event == AuthChangeEvent.signedIn;
  bool get isSignedOut => this.event == AuthChangeEvent.signedOut;
}
