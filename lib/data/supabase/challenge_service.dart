/// 🎯 Advanced Challenge Service
///
/// Professional service handling daily creative challenges, themes,
/// participation tracking, and community features.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/creative_models.dart';

class ChallengeService {
  final SupabaseClient _client;

  ChallengeService({required SupabaseClient client}) : _client = client;

  /// 📅 Get today's active challenge
  Future<CreativePrompt?> getTodaysChallenge() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('creative_prompts')
          .select()
          .filter('is_active', 'eq', true)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .maybeSingle();

      if (response != null) {
        return CreativePrompt.fromJson(response);
      }

      // If no challenge for today, get the most recent active one
      return getLatestActiveChallenge();
    } catch (e) {
      debugPrint('❌ Error fetching today\'s challenge: $e');
      return _getMockChallenge();
    }
  }

  /// 🔥 Get trending challenges
  Future<List<CreativePrompt>> getTrendingChallenges({int limit = 5}) async {
    try {
      final response = await _client
          .from('creative_prompts')
          .select()
          .filter('is_active', 'eq', true)
          .order('participant_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CreativePrompt.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching trending challenges: $e');
      return _getMockChallenges().where((c) => c.isTrending).toList();
    }
  }

  /// 📚 Get challenge by ID
  Future<CreativePrompt?> getChallenge(String id) async {
    try {
      final response = await _client
          .from('creative_prompts')
          .select()
          .filter('id', 'eq', id)
          .maybeSingle();

      return response != null ? CreativePrompt.fromJson(response) : null;
    } catch (e) {
      debugPrint('❌ Error fetching challenge: $e');
      return _getMockChallenge();
    }
  }

  /// 🆕 Create a new challenge (admin only)
  Future<CreativePrompt> createChallenge({
    required String title,
    required CreativeType type,
    required String description,
    String? aiStyle,
    List<String> tags = const [],
    int difficulty = 3,
    int durationDays = 1,
  }) async {
    try {
      final challenge = CreativePrompt(
        id: _generateId(),
        title: title,
        type: type,
        description: description,
        aiStyle: aiStyle,
        tags: tags,
        difficulty: difficulty,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: durationDays)),
      );

      await _client.from('creative_prompts').insert(challenge.toJson());
      debugPrint('✅ Challenge created: $title');

      return challenge;
    } catch (e) {
      debugPrint('❌ Error creating challenge: $e');
      throw Exception('Failed to create challenge: $e');
    }
  }

  /// ✏️ Update challenge (admin only)
  Future<CreativePrompt> updateChallenge(CreativePrompt challenge) async {
    try {
      await _client
          .from('creative_prompts')
          .update(challenge.toJson())
          .eq('id', challenge.id);

      debugPrint('✅ Challenge updated: ${challenge.title}');
      return challenge;
    } catch (e) {
      debugPrint('❌ Error updating challenge: $e');
      throw Exception('Failed to update challenge: $e');
    }
  }

  /// 🗑️ Delete challenge (admin only)
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _client.from('creative_prompts').delete().eq('id', challengeId);

      debugPrint('✅ Challenge deleted: $challengeId');
    } catch (e) {
      debugPrint('❌ Error deleting challenge: $e');
      throw Exception('Failed to delete challenge: $e');
    }
  }

  /// 📊 Get challenge statistics
  Future<Map<String, dynamic>> getChallengeStats(String challengeId) async {
    try {
      // Get participant count
      final participantResponse = await _client
          .from('creative_submissions')
          .select('user_id')
          .filter('prompt_id', 'eq', challengeId);

      final participantCount = (participantResponse as List).length;

      // Get submission statistics
      final submissionsResponse = await _client
          .from('creative_submissions')
          .select('type, cheer_count, comment_count')
          .filter('prompt_id', 'eq', challengeId);

      final submissions = submissionsResponse as List;
      final totalCheers = submissions.fold(
        0,
        (sum, s) => sum + (s['cheer_count'] as int),
      );
      final totalComments = submissions.fold(
        0,
        (sum, s) => sum + (s['comment_count'] as int),
      );

      // Get type distribution (be defensive: DB driver may return String or enum)
      final typeDistribution = <String, int>{};
      for (final submission in submissions) {
        final rawType = submission['type'];
        final type = rawType is String
            ? rawType
            : rawType is CreativeType
            ? rawType.name
            : (rawType?.toString() ?? 'unknown');
        typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
      }

      return {
        'participant_count': participantCount,
        'submission_count': submissions.length,
        'total_cheers': totalCheers,
        'total_comments': totalComments,
        'type_distribution': typeDistribution,
        'engagement_rate': participantCount > 0
            ? (submissions.length / participantCount)
            : 0,
      };
    } catch (e) {
      debugPrint('❌ Error fetching challenge stats: $e');
      return {
        'participant_count': 0,
        'submission_count': 0,
        'total_cheers': 0,
        'total_comments': 0,
        'type_distribution': {},
        'engagement_rate': 0,
      };
    }
  }

  /// 🔄 Get user's participation history for challenges
  Future<List<Map<String, dynamic>>> getUserChallengeHistory(
    String userId,
  ) async {
    try {
      final response = await _client
          .from('creative_submissions')
          .select('''
            prompt_id,
            creative_prompts!inner(title, type, description),
            created_at,
            cheer_count,
            comment_count
          ''')
          .filter('user_id', 'eq', userId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching user challenge history: $e');
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
          .filter('prompt_id', 'eq', challengeId)
          .order('cheer_count', ascending: false)
          .limit(10);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching challenge leaderboard: $e');
      return [];
    }
  }

  /// 🔔 Subscribe to new challenges
  Stream<List<CreativePrompt>> watchChallenges() {
    return _client
        .from('creative_prompts')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((event) => event.map(CreativePrompt.fromJson).toList());
  }

  /// 🎪 Get challenges by type
  Future<List<CreativePrompt>> getChallengesByType(CreativeType type) async {
    try {
      final response = await _client
          .from('creative_prompts')
          .select()
          .filter('type', 'eq', type.name)
          .filter('is_active', 'eq', true)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => CreativePrompt.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching challenges by type: $e');
      return _getMockChallenges().where((c) => c.type == type).toList();
    }
  }

  /// 🔍 Search challenges
  Future<List<CreativePrompt>> searchChallenges(String query) async {
    try {
      final response = await _client
          .from('creative_prompts')
          .select()
          .textSearch('search_vector', query)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => CreativePrompt.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching challenges: $e');
      return _getMockChallenges()
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// 📚 Get all challenges
  Future<List<CreativePrompt>> getAllChallenges() async {
    try {
      final response = await _client
          .from('creative_prompts')
          .select()
          .filter('is_active', 'eq', true)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => CreativePrompt.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching all challenges: $e');
      return _getMockChallenges();
    }
  }

  /// 🎯 Get challenge by ID
  Future<CreativePrompt?> getChallengeById(String id) async {
    try {
      final response = await _client
          .from('creative_prompts')
          .select()
          .filter('id', 'eq', id)
          .maybeSingle();

      return response != null ? CreativePrompt.fromJson(response) : null;
    } catch (e) {
      debugPrint('❌ Error fetching challenge by ID: $e');
      return _getMockChallenge();
    }
  }

  // 🛠️ PRIVATE HELPER METHODS

  /// Get latest active challenge
  Future<CreativePrompt?> getLatestActiveChallenge() async {
    try {
      final response = await _client
          .from('creative_prompts')
          .select()
          .filter('is_active', 'eq', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? CreativePrompt.fromJson(response) : null;
    } catch (e) {
      debugPrint('❌ Error fetching latest challenge: $e');
      return _getMockChallenge();
    }
  }

  /// Generate unique ID
  String _generateId() {
    return 'challenge_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode.abs()}';
  }

  // 🎭 MOCK DATA FOR DEVELOPMENT

  CreativePrompt _getMockChallenge() {
    final now = DateTime.now();
    return CreativePrompt(
      id: 'mock_challenge_1',
      title: '🌟 Magic Selfie Transformation',
      type: CreativeType.photo,
      description:
          'Transform your selfie into a fantasy character using AI magic! Add mystical elements, enchanted backgrounds, or superhero vibes.',
      aiStyle: 'fantasy',
      tags: ['selfie', 'fantasy', 'ai', 'transformation'],
      difficulty: 2,
      createdAt: now.subtract(const Duration(hours: 2)),
      expiresAt: now.add(const Duration(days: 1)),
      participantCount: 42,
    );
  }

  List<CreativePrompt> _getMockChallenges() {
    final now = DateTime.now();
    return [
      CreativePrompt(
        id: 'mock_1',
        title: '🌟 Magic Selfie Transformation',
        type: CreativeType.photo,
        description: 'Transform your selfie into a fantasy character!',
        aiStyle: 'fantasy',
        tags: ['selfie', 'fantasy', 'ai'],
        difficulty: 2,
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(days: 1)),
        participantCount: 42,
      ),
      CreativePrompt(
        id: 'mock_2',
        title: '🚀 Space Cat Adventure',
        type: CreativeType.text,
        description: 'Write a story about a cat astronaut!',
        aiStyle: 'scifi',
        tags: ['story', 'scifi', 'cats'],
        difficulty: 3,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(hours: 12)),
        participantCount: 156,
      ),
      CreativePrompt(
        id: 'mock_3',
        title: '🎬 Daily Mood Cinematic',
        type: CreativeType.video,
        description: 'Create a cinematic video of your mood!',
        aiStyle: 'cinematic',
        tags: ['video', 'mood', 'cinematic'],
        difficulty: 4,
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(hours: 6)),
        participantCount: 89,
      ),
    ];
  }
}
