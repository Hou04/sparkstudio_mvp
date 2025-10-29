/// 🎯 Advanced Challenge Service
///
/// Professional service handling challenge operations with Supabase integration,
/// real-time features, and comprehensive error handling.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';
import 'challenge_model.dart';

class ChallengeService {
  final SupabaseClient _client;

  ChallengeService({required SupabaseClient client}) : _client = client;

  /// 📅 Get today's active challenge
  Future<ChallengeModel?> getTodaysChallenge() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('challenges')
          .select()
          .filter('is_active', 'eq', true)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return ChallengeModel.fromJson(response);
      }

      // If no challenge for today, get the most recent active one
      return getLatestActiveChallenge();
    } catch (e) {
      Logger.error(
        '❌ Error fetching today\'s challenge: $e',
        tag: 'ChallengeService',
      );
      return _getMockChallenge();
    }
  }

  /// 🔥 Get trending challenges
  Future<List<ChallengeModel>> getTrendingChallenges({int limit = 5}) async {
    try {
      final response = await _client
          .from('challenges')
          .select()
          .filter('is_active', 'eq', true)
          .order('participant_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ChallengeModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error(
        '❌ Error fetching trending challenges: $e',
        tag: 'ChallengeService',
      );
      return _getMockChallenges().where((c) => c.isTrending).toList();
    }
  }

  /// 📚 Get challenges by type
  Future<List<ChallengeModel>> getChallengesByType(ChallengeType type) async {
    try {
      final response = await _client
          .from('challenges')
          .select()
          .filter('type', 'eq', type.name)
          .filter('is_active', 'eq', true)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => ChallengeModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error(
        '❌ Error fetching challenges by type: $e',
        tag: 'ChallengeService',
      );
      return _getMockChallenges().where((c) => c.type == type).toList();
    }
  }

  /// 🆕 Get all active challenges
  Future<List<ChallengeModel>> getAllChallenges({int limit = 50}) async {
    try {
      final response = await _client
          .from('challenges')
          .select()
          .filter('is_active', 'eq', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ChallengeModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error(
        '❌ Error fetching all challenges: $e',
        tag: 'ChallengeService',
      );
      return _getMockChallenges();
    }
  }

  /// 🎯 Get challenge by ID
  Future<ChallengeModel?> getChallengeById(String id) async {
    try {
      final response = await _client
          .from('challenges')
          .select()
          .filter('id', 'eq', id)
          .maybeSingle();

      return response != null ? ChallengeModel.fromJson(response) : null;
    } catch (e) {
      Logger.error(
        '❌ Error fetching challenge by ID: $e',
        tag: 'ChallengeService',
      );
      return _getMockChallenge();
    }
  }

  /// 🔍 Search challenges
  Future<List<ChallengeModel>> searchChallenges(String query) async {
    try {
      final response = await _client
          .from('challenges')
          .select()
          .textSearch('search_vector', query)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => ChallengeModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('❌ Error searching challenges: $e', tag: 'ChallengeService');
      return _getMockChallenges()
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// 📊 Get challenge statistics
  Future<Map<String, dynamic>> getChallengeStats(String challengeId) async {
    try {
      // Get participant count
      final participantResponse = await _client
          .from('creative_submissions')
          .select('user_id')
          .eq('prompt_id', challengeId);

      final participantCount = (participantResponse as List).length;

      // Get submission statistics
      final submissionsResponse = await _client
          .from('creative_submissions')
          .select('cheer_count, comment_count')
          .eq('prompt_id', challengeId);

      final submissions = submissionsResponse as List;
      final totalCheers = submissions.fold(
        0,
        (sum, s) => sum + (s['cheer_count'] as int),
      );
      final totalComments = submissions.fold(
        0,
        (sum, s) => sum + (s['comment_count'] as int),
      );

      return {
        'participant_count': participantCount,
        'submission_count': submissions.length,
        'total_cheers': totalCheers,
        'total_comments': totalComments,
        'engagement_rate': participantCount > 0
            ? (submissions.length / participantCount)
            : 0,
      };
    } catch (e) {
      Logger.error(
        '❌ Error fetching challenge stats: $e',
        tag: 'ChallengeService',
      );
      return {
        'participant_count': 0,
        'submission_count': 0,
        'total_cheers': 0,
        'total_comments': 0,
        'engagement_rate': 0.0,
      };
    }
  }

  /// 👤 Get user's challenge participation history
  Future<List<Map<String, dynamic>>> getUserChallengeHistory(
    String userId,
  ) async {
    try {
      final response = await _client
          .from('creative_submissions')
          .select('''
            prompt_id,
            challenges!inner(title, type, description),
            created_at,
            cheer_count,
            comment_count
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.error(
        '❌ Error fetching user challenge history: $e',
        tag: 'ChallengeService',
      );
      return [];
    }
  }

  /// 🏆 Get challenge leaderboard
  Future<List<Map<String, dynamic>>> getChallengeLeaderboard(
    String challengeId,
  ) async {
    try {
      final response = await _client
          .from('creative_submissions')
          .select('''
            user_id,
            profiles!inner(full_name, avatar_url),
            cheer_count,
            comment_count,
            created_at
          ''')
          .eq('prompt_id', challengeId)
          .order('cheer_count', ascending: false)
          .limit(10);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.error(
        '❌ Error fetching challenge leaderboard: $e',
        tag: 'ChallengeService',
      );
      return [];
    }
  }

  /// 🔔 Subscribe to new challenges
  Stream<List<ChallengeModel>> watchChallenges() {
    return _client
        .from('challenges')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((event) => event.map(ChallengeModel.fromJson).toList());
  }

  // 🛠️ PRIVATE HELPER METHODS

  /// Get latest active challenge
  Future<ChallengeModel?> getLatestActiveChallenge() async {
    try {
      final response = await _client
          .from('challenges')
          .select()
          .filter('is_active', 'eq', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? ChallengeModel.fromJson(response) : null;
    } catch (e) {
      Logger.error(
        '❌ Error fetching latest challenge: $e',
        tag: 'ChallengeService',
      );
      return _getMockChallenge();
    }
  }

  // 🧪 MOCK DATA FOR DEVELOPMENT

  ChallengeModel _getMockChallenge() {
    final now = DateTime.now();
    return ChallengeModel(
      id: 'mock_challenge_1',
      title: '🌟 Magic Selfie Transformation',
      description:
          'Transform your selfie into a fantasy character using AI magic! Add mystical elements, enchanted backgrounds, or superhero vibes.',
      type: ChallengeType.photo,
      aiStyle: 'fantasy',
      tags: ['selfie', 'fantasy', 'ai', 'transformation'],
      difficulty: 2,
      createdAt: now.subtract(const Duration(hours: 2)),
      expiresAt: now.add(const Duration(days: 1)),
      participantCount: 42,
      submissionCount: 35,
      engagementRate: 0.83,
    );
  }

  List<ChallengeModel> _getMockChallenges() {
    final now = DateTime.now();
    return [
      ChallengeModel(
        id: 'mock_1',
        title: '🌟 Magic Selfie Transformation',
        description: 'Transform your selfie into a fantasy character!',
        type: ChallengeType.photo,
        aiStyle: 'fantasy',
        tags: ['selfie', 'fantasy', 'ai'],
        difficulty: 2,
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(days: 1)),
        participantCount: 42,
        submissionCount: 35,
        engagementRate: 0.83,
      ),
      ChallengeModel(
        id: 'mock_2',
        title: '🚀 Space Cat Adventure',
        description: 'Write a story about a cat who becomes an astronaut!',
        type: ChallengeType.text,
        aiStyle: 'scifi',
        tags: ['story', 'scifi', 'cats'],
        difficulty: 3,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(hours: 12)),
        participantCount: 156,
        submissionCount: 142,
        engagementRate: 0.91,
      ),
      ChallengeModel(
        id: 'mock_3',
        title: '🎬 Daily Mood Cinematic',
        description:
            'Create a cinematic video that captures your current mood!',
        type: ChallengeType.video,
        aiStyle: 'cinematic',
        tags: ['video', 'mood', 'cinematic'],
        difficulty: 4,
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(hours: 6)),
        participantCount: 89,
        submissionCount: 67,
        engagementRate: 0.75,
      ),
    ];
  }
}
