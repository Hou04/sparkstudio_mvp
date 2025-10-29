/// 🎮 Advanced Authentication Controller
/// 
/// Professional controller handling authentication state management,
/// user sessions, and real-time auth updates.

import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';
import '../data/auth_repository.dart';
import '../data/auth_model.dart';

class AuthController with ChangeNotifier {
  final AuthRepository _repository;

  // State variables
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  AuthStatus _status = AuthStatus.initial;

  AuthController({required AuthRepository repository}) : _repository = repository;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  AuthStatus get status => _status;
  bool get hasError => _error != null;

  /// 🚀 Initialize authentication state
  Future<void> initialize() async {
    _isLoading = true;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // Check if user is already authenticated
      final user = await _repository.getCurrentUser();
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        _status = AuthStatus.authenticated;
        Logger.success('✅ User authenticated: ${user.displayName}', tag: 'Auth');
      } else {
        _status = AuthStatus.unauthenticated;
        Logger.info('👤 No authenticated user found', tag: 'Auth');
      }
    } catch (e) {
      _error = 'Failed to initialize authentication: $e';
      _status = AuthStatus.error;
      Logger.error('❌ Auth initialization failed: $e', tag: 'Auth');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔑 Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final result = await _repository.signInWithEmail(
        email: email,
        password: password,
      );

      if (result.success && result.user != null) {
        _currentUser = result.user;
        _isAuthenticated = true;
        _status = AuthStatus.authenticated;
        Logger.success('✅ Sign in successful: ${result.user!.email}', tag: 'Auth');
      } else {
        _error = result.error ?? 'Sign in failed';
        _status = AuthStatus.error;
      }
    } catch (e) {
      _error = 'Sign in failed: ${e.toString()}';
      _status = AuthStatus.error;
      Logger.error('❌ Sign in failed: $e', tag: 'Auth');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🆕 Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final result = await _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      if (result.success && result.user != null) {
        _currentUser = result.user;
        _isAuthenticated = true;
        _status = AuthStatus.authenticated;
        Logger.success('✅ Sign up successful: ${result.user!.email}', tag: 'Auth');
      } else {
        _error = result.error ?? 'Sign up failed';
        _status = AuthStatus.error;
      }
    } catch (e) {
      _error = 'Sign up failed: ${e.toString()}';
      _status = AuthStatus.error;
      Logger.error('❌ Sign up failed: $e', tag: 'Auth');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🚪 Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.signOut();
      
      _currentUser = null;
      _isAuthenticated = false;
      _status = AuthStatus.unauthenticated;
      _error = null;
      
      Logger.info('🚪 User signed out successfully', tag: 'Auth');
    } catch (e) {
      _error = 'Sign out failed: ${e.toString()}';
      Logger.error('❌ Sign out failed: $e', tag: 'Auth');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 📧 Reset password
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.resetPassword(email);
      Logger.info('📧 Password reset email sent to: $email', tag: 'Auth');
    } catch (e) {
      _error = 'Password reset failed: ${e.toString()}';
      Logger.error('❌ Password reset failed: $e', tag: 'Auth');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Update password
  Future<void> updatePassword(String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updatePassword(newPassword);
      Logger.info('✅ Password updated successfully', tag: 'Auth');
    } catch (e) {
      _error = 'Password update failed: ${e.toString()}';
      Logger.error('❌ Password update failed: $e', tag: 'Auth');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✏️ Update user profile
  Future<void> updateProfile({
    required String displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _repository.updateProfile(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      _currentUser = updatedUser;
      Logger.info('✅ Profile updated: $displayName', tag: 'Auth');
    } catch (e) {
      _error = 'Profile update failed: ${e.toString()}';
      Logger.error('❌ Profile update failed: $e', tag: 'Auth');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🧹 Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 🔄 Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      Logger.error('❌ Failed to refresh user: $e', tag: 'Auth');
    }
  }

  /// 🎯 Get user statistics
  Future<UserStats?> getUserStats() async {
    if (_currentUser == null) return null;

    try {
      return await _repository.getUserStats(_currentUser!.id);
    } catch (e) {
      Logger.error('❌ Failed to get user stats: $e', tag: 'Auth');
      return null;
    }
  }

  /// 🧪 Mock sign in for development
  Future<void> mockSignIn() async {
    _isLoading = true;
    _status = AuthStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    final result = await _repository.mockSignIn();
    
    if (result.success && result.user != null) {
      _currentUser = result.user;
      _isAuthenticated = true;
      _status = AuthStatus.authenticated;
    } else {
      _error = result.error;
      _status = AuthStatus.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 🧪 Mock sign out for development
  Future<void> mockSignOut() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _currentUser = null;
    _isAuthenticated = false;
    _status = AuthStatus.unauthenticated;
    _error = null;

    _isLoading = false;
    notifyListeners();
  }
}

/// 🎯 Authentication Status Enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// 🔧 Auth Status Extensions
extension AuthStatusExtensions on AuthStatus {
  bool get isInitial => this == AuthStatus.initial;
  bool get isLoading => this == AuthStatus.loading;
  bool get isAuthenticated => this == AuthStatus.authenticated;
  bool get isUnauthenticated => this == AuthStatus.unauthenticated;
  bool get isError => this == AuthStatus.error;
}