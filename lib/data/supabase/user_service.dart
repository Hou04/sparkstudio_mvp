/// 👤 Advanced User Service
///
/// Professional service handling user profiles, social features, statistics,
/// and real-time user updates.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client;

  UserService({required SupabaseClient client}) : _client = client;

  /// 👤 Get current user profile
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .filter('id', 'eq', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Error fetching current user: $e');
      return _getMockUserProfile();
    }
  }

  /// 📊 Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get basic profile
      final profile = await _client
          .from('profiles')
          .select('streak_count, total_submissions, total_cheers_received')
          .filter('id', 'eq', userId)
          .single();

      // Get recent activity
      final submissions = await _client
          .from('creative_submissions')
          .select('id, created_at, cheer_count')
          .filter('user_id', 'eq', userId)
          .order('created_at', ascending: false)
          .limit(10);

      // Calculate additional stats
      final totalCheers = submissions.fold<int>(
        0,
        (sum, s) => sum + (s['cheer_count'] as int),
      );
      final recentActivity = submissions.length;

      return {
        ...profile,
        'total_cheers_given': totalCheers,
        'recent_activity_count': recentActivity,
        'engagement_score': _calculateEngagementScore(profile, recentActivity),
      };
    } catch (e) {
      debugPrint('❌ Error fetching user stats: $e');
      return _getMockUserStats();
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
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updates['full_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      debugPrint('✅ Profile updated for user: $userId');
      return response;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// 🔍 Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, avatar_url, bio, streak_count')
          .textSearch('full_name', query)
          .order('streak_count', ascending: false)
          .limit(20);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return _getMockUsers()
          .where(
            (u) => u['full_name'].toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  /// 👥 Get user's followers
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _client
          .from('followers')
          .select('''
            follower:profiles!follower_id(id, full_name, avatar_url, bio)
          ''')
          .filter('following_id', 'eq', userId);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching followers: $e');
      return _getMockUsers().take(3).toList();
    }
  }

  /// 👥 Get user's following
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _client
          .from('followers')
          .select('''
            following:profiles!following_id(id, full_name, avatar_url, bio)
          ''')
          .filter('follower_id', 'eq', userId);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching following: $e');
      return _getMockUsers().take(5).toList();
    }
  }

  /// ➕ Follow a user
  Future<void> followUser(String targetUserId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client.from('followers').insert({
        'follower_id': user.id,
        'following_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ User $targetUserId followed');
    } catch (e) {
      debugPrint('❌ Error following user: $e');
      throw Exception('Failed to follow user: $e');
    }
  }

  /// ➖ Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client
          .from('followers')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId);

      debugPrint('✅ User $targetUserId unfollowed');
    } catch (e) {
      debugPrint('❌ Error unfollowing user: $e');
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// 🏆 Get top creators
  Future<List<Map<String, dynamic>>> getTopCreators({int limit = 10}) async {
    try {
      final response = await _client
          .from('profiles')
          .select(
            'id, full_name, avatar_url, bio, streak_count, total_submissions',
          )
          .order('total_submissions', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching top creators: $e');
      return _getMockUsers();
    }
  }

  /// 📈 Update user streak
  Future<void> updateUserStreak(String userId) async {
    try {
      await _client.rpc('update_user_streak', params: {'user_id': userId});
      debugPrint('✅ Streak updated for user: $userId');
    } catch (e) {
      debugPrint('❌ Error updating streak: $e');
    }
  }

  /// 🎯 Check if user is following another user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('followers')
          .select('id')
          .filter('follower_id', 'eq', user.id)
          .filter('following_id', 'eq', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking follow status: $e');
      return false;
    }
  }

  /// 🔔 Subscribe to user profile updates
  Stream<Map<String, dynamic>> watchUserProfile(String userId) {
    return _client.from('profiles').stream(primaryKey: ['id']).map((event) {
      final filtered = event.where((e) => e['id'] == userId).toList();
      if (filtered.isNotEmpty) return filtered.first;
      throw Exception('User not found');
    });
  }

  // 🛠️ PRIVATE HELPER METHODS

  /// Calculate engagement score
  double _calculateEngagementScore(
    Map<String, dynamic> profile,
    int recentActivity,
  ) {
    final streak = (profile['streak_count'] as int?) ?? 0;
    final totalSubmissions = (profile['total_submissions'] as int?) ?? 0;
    final totalCheers = (profile['total_cheers_received'] as int?) ?? 0;

    return (streak * 0.3) +
        (totalSubmissions * 0.4) +
        (totalCheers * 0.2) +
        (recentActivity * 0.1);
  }

  // 🧪 MOCK DATA FOR DEVELOPMENT

  Map<String, dynamic> _getMockUserProfile() {
    return {
      'id': 'mock_user_1',
      'email': 'creative@sparkstudio.com',
      'full_name': 'Alex Creative',
      'avatar_url':
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face',
      'bio':
          'Digital artist and storyteller. Creating magic one prompt at a time! ✨',
      'streak_count': 7,
      'total_submissions': 23,
      'total_cheers_received': 156,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getMockUserStats() {
    return {
      'streak_count': 7,
      'total_submissions': 23,
      'total_cheers_received': 156,
      'total_cheers_given': 89,
      'recent_activity_count': 5,
      'engagement_score': 8.7,
    };
  }

  List<Map<String, dynamic>> _getMockUsers() {
    return [
      {
        'id': 'user_1',
        'full_name': 'Alex Creative',
        'avatar_url':
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face',
        'bio': 'Digital artist and AI enthusiast',
        'streak_count': 7,
        'total_submissions': 23,
      },
      {
        'id': 'user_2',
        'full_name': 'Taylor Wordsmith',
        'avatar_url':
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
        'bio': 'Poet and storyteller',
        'streak_count': 14,
        'total_submissions': 42,
      },
      {
        'id': 'user_3',
        'full_name': 'Jordan Visionary',
        'avatar_url':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'bio': 'Visual artist and photographer',
        'streak_count': 3,
        'total_submissions': 12,
      },
      {
        'id': 'user_4',
        'full_name': 'Casey Innovator',
        'avatar_url':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        'bio': 'Mixed media creator',
        'streak_count': 21,
        'total_submissions': 67,
      },
    ];
  }
}
