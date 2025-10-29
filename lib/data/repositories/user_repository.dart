/// 👤 Advanced User Repository
/// 
/// Professional repository handling user operations, profiles, and social features
/// with caching and real-time updates.

import '../supabase/user_service.dart';

class UserRepository {
  final UserService _userService;
  
  final Map<String, Map<String, dynamic>> _userCache = {};

  UserRepository({required UserService userService}) : _userService = userService;

  /// 👤 Get current user profile
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        _userCache[user['id']] = user;
      }
      return user;
    } catch (e) {
      throw Exception('Failed to fetch current user: $e');
    }
  }

  /// 📊 Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      return await _userService.getUserStats(userId);
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }

  /// ✏️ Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final updatedUser = await _userService.updateProfile(
        userId: userId,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      _userCache[userId] = updatedUser;
      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// 🔍 Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      return await _userService.searchUsers(query);
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// 👥 Get user's followers
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      return await _userService.getFollowers(userId);
    } catch (e) {
      throw Exception('Failed to fetch followers: $e');
    }
  }

  /// 👥 Get user's following
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      return await _userService.getFollowing(userId);
    } catch (e) {
      throw Exception('Failed to fetch following: $e');
    }
  }

  /// ➕ Follow user
  Future<void> followUser(String targetUserId) async {
    try {
      await _userService.followUser(targetUserId);
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// ➖ Unfollow user
  Future<void> unfollowUser(String targetUserId) async {
    try {
      await _userService.unfollowUser(targetUserId);
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// 🧹 Clear user cache
  void clearCache() {
    _userCache.clear();
  }
}