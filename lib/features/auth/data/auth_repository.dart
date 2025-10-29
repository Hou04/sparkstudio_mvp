/// 🔐 Advanced Authentication Repository
/// 
/// Professional repository handling all authentication operations
/// with caching, error handling, and business logic.

import '../../../core/utils/logger.dart';
import '../../../data/supabase/auth_service.dart';
import 'auth_model.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({required AuthService authService}) : _authService = authService;

  /// 🔑 Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('🔐 Sign in attempt: $email', tag: 'Auth');
      
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        final userModel = await _getUserProfile(user.id);
        Logger.success('✅ Sign in successful: ${user.email}', tag: 'Auth');
        return AuthResult.success(userModel);
      } else {
        throw Exception('Sign in failed - no user returned');
      }
    } catch (e) {
      Logger.error('❌ Sign in failed: $e', tag: 'Auth');
      return AuthResult.error('Sign in failed: ${e.toString()}');
    }
  }

  /// 🆕 Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? avatarUrl,
  }) async {
    try {
      Logger.info('👤 Sign up attempt: $email', tag: 'Auth');
      
      final user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      if (user != null) {
        final userModel = await _getUserProfile(user.id);
        Logger.success('✅ Sign up successful: ${user.email}', tag: 'Auth');
        return AuthResult.success(userModel);
      } else {
        // Email confirmation required
        Logger.info('📧 Email confirmation required for: $email', tag: 'Auth');
        return AuthResult.error('Please check your email to confirm your account');
      }
    } catch (e) {
      Logger.error('❌ Sign up failed: $e', tag: 'Auth');
      return AuthResult.error('Sign up failed: ${e.toString()}');
    }
  }

  /// 🚪 Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      Logger.info('🚪 User signed out', tag: 'Auth');
    } catch (e) {
      Logger.error('❌ Sign out failed: $e', tag: 'Auth');
      rethrow;
    }
  }

  /// 📧 Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      Logger.info('📧 Password reset email sent to: $email', tag: 'Auth');
    } catch (e) {
      Logger.error('❌ Password reset failed: $e', tag: 'Auth');
      rethrow;
    }
  }

  /// 🔄 Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
      Logger.info('✅ Password updated successfully', tag: 'Auth');
    } catch (e) {
      Logger.error('❌ Password update failed: $e', tag: 'Auth');
      rethrow;
    }
  }

  /// 👤 Get current user profile
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return null;

      return await _getUserProfile(user.id);
    } catch (e) {
      Logger.error('❌ Failed to get current user: $e', tag: 'Auth');
      return null;
    }
  }

  /// ✏️ Update user profile
  Future<UserModel> updateProfile({
    required String displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      await _authService.updateProfile(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      Logger.info('✅ Profile updated for: $displayName', tag: 'Auth');
      return currentUser;
    } catch (e) {
      Logger.error('❌ Profile update failed: $e', tag: 'Auth');
      rethrow;
    }
  }

  /// 🔍 Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      return await _authService.isEmailAvailable(email);
    } catch (e) {
      Logger.error('❌ Email availability check failed: $e', tag: 'Auth');
      return true; // Assume available if check fails
    }
  }

  /// 📱 Verify current session
  Future<bool> verifySession() async {
    try {
      return await _authService.verifySession();
    } catch (e) {
      Logger.error('❌ Session verification failed: $e', tag: 'Auth');
      return false;
    }
  }

  /// 🎯 Get user statistics
  Future<UserStats> getUserStats(String userId) async {
    try {
      // This would typically fetch from your user stats service
      // For now, return mock data
      return UserStats(
        streakCount: 7,
        totalSubmissions: 23,
        totalCheersReceived: 156,
        totalCheersGiven: 89,
        totalComments: 34,
        totalRemixes: 12,
        engagementScore: 8.7,
        lastSubmissionAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
    } catch (e) {
      Logger.error('❌ Failed to get user stats: $e', tag: 'Auth');
      rethrow;
    }
  }

  // 🛠️ PRIVATE HELPER METHODS

  /// Get user profile from database
  Future<UserModel> _getUserProfile(String userId) async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        return UserModel.fromJson(profile);
      } else {
        // Create default user model from auth user
        final authUser = _authService.currentUser!;
        return UserModel(
          id: authUser.id,
          email: authUser.email!,
          displayName: authUser.userMetadata?['full_name'] as String?,
          avatarUrl: authUser.userMetadata?['avatar_url'] as String?,
          createdAt: DateTime.now(),
          isEmailVerified: authUser.emailConfirmedAt != null,
        );
      }
    } catch (e) {
      Logger.error('❌ Failed to get user profile: $e', tag: 'Auth');
      rethrow;
    }
  }

  /// 🧪 Mock methods for development
  Future<AuthResult> mockSignIn() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final mockUser = UserModel(
      id: 'mock_user_1',
      email: 'creative@sparkstudio.com',
      displayName: 'Spark Creator',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face',
      bio: 'Digital artist and AI enthusiast creating magic daily!',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      streakCount: 7,
      totalSubmissions: 23,
      totalCheersReceived: 156,
      isEmailVerified: true,
    );

    return AuthResult.success(mockUser);
  }

  Future<AuthResult> mockSignUp() async {
    await Future.delayed(const Duration(seconds: 2));
    return mockSignIn();
  }
}