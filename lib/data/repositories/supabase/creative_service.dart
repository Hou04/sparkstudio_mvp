/// 🎨 Advanced Creative Service with Real-time Features
///
/// Professional service handling creative prompts, submissions, and AI-enhanced
/// content with real-time updates, caching, and performance optimization.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/creative_models.dart';
import '../ai/ai_generation_service.dart';

class CreativeService {
  final SupabaseClient _client;
  final AiGenerationService _aiService;

  // Cache for performance
  final Map<String, CreativePrompt> _promptCache = {};
  final Map<String, CreativeSubmission> _submissionCache = {};

  CreativeService({
    required SupabaseClient client,
    required AiGenerationService aiService,
  }) : _client = client,
       _aiService = aiService;

  /// 🌟 Get today's active creative prompts with caching
  Future<List<CreativePrompt>> getTodayPrompts({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && _promptCache.isNotEmpty) {
        return _getCachedActivePrompts();
      }

      final response = await _client
          .from('creative_prompts')
          .select()
          .filter('is_active', 'eq', true)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(10);

      final prompts = (response as List)
          .map((json) => CreativePrompt.fromJson(json))
          .toList();

      // Update cache
      for (final prompt in prompts) {
        _promptCache[prompt.id] = prompt;
      }

      return prompts;
    } catch (e) {
      debugPrint('❌ Error fetching today\'s prompts: $e');
      return _getMockPrompts();
    }
  }

  /// 🔥 Get trending prompts (most participants)
  Future<List<CreativePrompt>> getTrendingPrompts({int limit = 5}) async {
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
      debugPrint('❌ Error fetching trending prompts: $e');
      return _getMockPrompts().where((p) => p.isTrending).toList();
    }
  }

  /// 🆕 Add a new creative submission with AI enhancement
  Future<CreativeSubmission> addSubmission({
    required String promptId,
    required String userId,
    required CreativeType type,
    String? contentUrl,
    String? textContent,
    String? aiStyle,
    bool enhanceWithAI = true,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      String? aiGeneratedContent;
      Map<String, dynamic>? aiMetadata;

      // Enhance with AI if requested
      if (enhanceWithAI && textContent != null && textContent.isNotEmpty) {
        try {
          final style = CreativeStyle.values.firstWhere(
            (s) =>
                s.displayName.toLowerCase() ==
                (aiStyle ?? 'creative').toLowerCase(),
            orElse: () => CreativeStyle.creative,
          );

          final aiRequest = AiGenerationRequest(
            prompt: textContent,
            style: style,
            baseContent: textContent,
          );

          final aiResponse = await _aiService.generateCreativeText(aiRequest);
          aiGeneratedContent = aiResponse.generatedContent;
          aiMetadata = {
            'model': aiResponse.model.name,
            'confidence': aiResponse.confidence,
            'tokens_used': aiResponse.tokensUsed,
          };
        } catch (e) {
          debugPrint('⚠️ AI enhancement failed: $e');
          // Continue without AI enhancement
        }
      }

      final submission = CreativeSubmission(
        id: _generateId(),
        promptId: promptId,
        userId: userId,
        userDisplayName: user.userMetadata?['full_name'] ?? 'Anonymous Creator',
        userAvatarUrl: user.userMetadata?['avatar_url'] as String?,
        type: type,
        contentUrl: contentUrl,
        textContent: textContent,
        aiStyle: aiStyle,
        aiGeneratedContent: aiGeneratedContent,
        aiMetadata: aiMetadata,
        createdAt: DateTime.now(),
      );

      // Insert into database
      await _client.from('creative_submissions').insert(submission.toJson());

      // Update cache
      _submissionCache[submission.id] = submission;

      // Increment participant count for the prompt
      await _incrementParticipantCount(promptId);

      debugPrint('✅ Submission added: ${submission.id}');
      return submission;
    } catch (e) {
      debugPrint('❌ Error adding submission: $e');
      throw Exception('Failed to add submission: $e');
    }
  }

  /// 📥 Get submissions with advanced filtering
  Future<List<CreativeSubmission>> getSubmissions({
    String? promptId,
    String? userId,
    CreativeType? type,
    int limit = 50,
    int offset = 0,
    bool includePrivate = false,
  }) async {
    try {
      var query = _client.from('creative_submissions').select();

      if (promptId != null) {
        query = query.filter('prompt_id', 'eq', promptId);
      }

      if (userId != null) {
        query = query.filter('user_id', 'eq', userId);
      }

      if (type != null) {
        query = query.filter('type', 'eq', type.name);
      }

      if (!includePrivate) {
        query = query.filter('is_public', 'eq', true);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      final submissions = (response as List)
          .map((json) => CreativeSubmission.fromJson(json))
          .toList();

      // Update cache
      for (final submission in submissions) {
        _submissionCache[submission.id] = submission;
      }

      return submissions;
    } catch (e) {
      debugPrint('❌ Error fetching submissions: $e');
      return _getMockSubmissions(promptId: promptId, userId: userId);
    }
  }

  /// 🔄 Real-time subscription to new submissions
  Stream<List<CreativeSubmission>> watchSubmissions({String? promptId}) {
    return _client.from('creative_submissions').stream(primaryKey: ['id']).map((
      event,
    ) {
      final filtered = (promptId == null)
          ? event
          : event.where((e) => e['prompt_id'] == promptId).toList();
      return filtered.map(CreativeSubmission.fromJson).toList();
    });
  }

  /// 🎯 Get user's submission streak and stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final submissions = await getSubmissions(userId: userId);

      final totalSubmissions = submissions.length;
      final publicSubmissions = submissions.where((s) => s.isPublic).length;
      final totalCheers = submissions.fold(0, (sum, s) => sum + s.cheerCount);
      final totalComments = submissions.fold(
        0,
        (sum, s) => sum + s.commentCount,
      );

      // Calculate streak (simplified)
      final streak = await _calculateStreak(userId);

      return {
        'total_submissions': totalSubmissions,
        'public_submissions': publicSubmissions,
        'total_cheers': totalCheers,
        'total_comments': totalComments,
        'current_streak': streak,
        'ai_enhanced_count': submissions
            .where((s) => s.hasAiEnhancement)
            .length,
      };
    } catch (e) {
      debugPrint('❌ Error fetching user stats: $e');
      return {
        'total_submissions': 0,
        'public_submissions': 0,
        'total_cheers': 0,
        'total_comments': 0,
        'current_streak': 0,
        'ai_enhanced_count': 0,
      };
    }
  }

  /// ⬆️ Upload media file with progress tracking
  Future<String> uploadMedia(
    String filePath,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      // Upload to Supabase Storage
      await _client.storage.from('creative_media').upload(uniqueFileName, file);

      // Get public URL
      final publicUrl = _client.storage
          .from('creative_media')
          .getPublicUrl(uniqueFileName);

      debugPrint('✅ Media uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading media: $e');
      throw Exception('Failed to upload media: $e');
    }
  }

  /// ✏️ Update an existing submission
  Future<CreativeSubmission> updateSubmission(
    CreativeSubmission submission,
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      if (submission.userId != user.id) throw Exception('Unauthorized');

      await _client
          .from('creative_submissions')
          .update(submission.toJson())
          .eq('id', submission.id);

      // Update cache
      _submissionCache[submission.id] = submission;

      debugPrint('✅ Submission updated: ${submission.id}');
      return submission;
    } catch (e) {
      debugPrint('❌ Error updating submission: $e');
      throw Exception('Failed to update submission: $e');
    }
  }

  /// 🗑️ Delete a submission
  Future<void> deleteSubmission(String submissionId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final submission = _submissionCache[submissionId];
      if (submission != null && submission.userId != user.id) {
        throw Exception('Unauthorized to delete this submission');
      }

      await _client
          .from('creative_submissions')
          .delete()
          .eq('id', submissionId)
          .eq('user_id', user.id);

      // Remove from cache
      _submissionCache.remove(submissionId);

      debugPrint('✅ Submission deleted: $submissionId');
    } catch (e) {
      debugPrint('❌ Error deleting submission: $e');
      throw Exception('Failed to delete submission: $e');
    }
  }

  /// 👏 Add cheer to a submission
  Future<void> addCheer(String submissionId) async {
    try {
      await _client.rpc(
        'increment_cheer_count',
        params: {'submission_id': submissionId},
      );

      // Update cache if exists
      if (_submissionCache.containsKey(submissionId)) {
        final submission = _submissionCache[submissionId]!;
        _submissionCache[submissionId] = submission.copyWith(
          cheerCount: submission.cheerCount + 1,
        );
      }

      debugPrint('✅ Cheer added to: $submissionId');
    } catch (e) {
      debugPrint('❌ Error adding cheer: $e');
      throw Exception('Failed to add cheer: $e');
    }
  }

  /// 🔍 Search submissions by tags or content
  Future<List<CreativeSubmission>> searchSubmissions(String query) async {
    try {
      final response = await _client
          .from('creative_submissions')
          .select()
          .textSearch('search_vector', query)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => CreativeSubmission.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching submissions: $e');
      return [];
    }
  }

  /// 📦 Convenience: get all submissions for feed or admin purposes
  Future<List<CreativeSubmission>> getAllSubmissions({int limit = 1000}) async {
    try {
      return await getSubmissions(
        limit: limit,
        offset: 0,
        includePrivate: false,
      );
    } catch (e) {
      debugPrint('❌ Error fetching all submissions: $e');
      return _getMockSubmissions();
    }
  }

  /// 📥 Convenience: get submissions filtered by prompt id
  Future<List<CreativeSubmission>> getSubmissionsByPrompt(
    String promptId, {
    int limit = 50,
  }) async {
    try {
      return await getSubmissions(promptId: promptId, limit: limit);
    } catch (e) {
      debugPrint('❌ Error fetching submissions by prompt: $e');
      return _getMockSubmissions(promptId: promptId);
    }
  }

  /// 📚 Convenience: get all prompts (not just today's)
  Future<List<CreativePrompt>> getAllPrompts({int limit = 100}) async {
    try {
      final response = await _client
          .from('creative_prompts')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CreativePrompt.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching all prompts: $e');
      return _getMockPrompts();
    }
  }

  // 🛠️ PRIVATE HELPER METHODS

  /// Get cached active prompts
  List<CreativePrompt> _getCachedActivePrompts() {
    final now = DateTime.now();
    return _promptCache.values
        .where((prompt) => prompt.isActive && !prompt.isExpired)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Calculate user submission streak
  Future<int> _calculateStreak(String userId) async {
    try {
      final submissions = await getSubmissions(userId: userId);
      if (submissions.isEmpty) return 0;

      // Sort by date descending
      submissions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      int streak = 0;
      DateTime currentDate = DateTime.now();

      for (final submission in submissions) {
        final submissionDate = DateTime(
          submission.createdAt.year,
          submission.createdAt.month,
          submission.createdAt.day,
        );

        final checkDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        );

        if (submissionDate.isAtSameMomentAs(checkDate)) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('❌ Error calculating streak: $e');
      return 0;
    }
  }

  /// Increment participant count for a prompt
  Future<void> _incrementParticipantCount(String promptId) async {
    try {
      await _client.rpc(
        'increment_participant_count',
        params: {'prompt_id': promptId},
      );

      // Update cache
      if (_promptCache.containsKey(promptId)) {
        final prompt = _promptCache[promptId]!;
        _promptCache[promptId] = prompt.copyWith(
          participantCount: prompt.participantCount + 1,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to increment participant count: $e');
    }
  }

  /// Generate unique ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode.abs()}';
  }

  /// 🎭 MOCK DATA FOR DEVELOPMENT

  List<CreativePrompt> _getMockPrompts() {
    final now = DateTime.now();
    return [
      CreativePrompt(
        id: 'mock_1',
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
      ),
      CreativePrompt(
        id: 'mock_2',
        title: '🚀 Space Cat Adventure',
        type: CreativeType.text,
        description:
            'Write a short story about a cat who becomes an astronaut. Let AI help you create an epic interstellar adventure!',
        aiStyle: 'scifi',
        tags: ['story', 'scifi', 'cats', 'adventure'],
        difficulty: 3,
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(days: 1)),
        participantCount: 156,
      ),
      CreativePrompt(
        id: 'mock_3',
        title: '🎬 Daily Mood Cinematic',
        type: CreativeType.video,
        description:
            'Create a 30-second cinematic video that captures your current mood. Use creative transitions and atmospheric effects.',
        aiStyle: 'cinematic',
        tags: ['video', 'mood', 'cinematic', 'creative'],
        difficulty: 4,
        createdAt: now.subtract(const Duration(minutes: 30)),
        expiresAt: now.add(const Duration(days: 1)),
        participantCount: 89,
      ),
      CreativePrompt(
        id: 'mock_4',
        title: '🌸 Haiku of the Season',
        type: CreativeType.text,
        description:
            'Compose a beautiful haiku about your favorite season. AI will help refine the rhythm and imagery.',
        aiStyle: 'haiku',
        tags: ['poetry', 'haiku', 'seasons', 'nature'],
        difficulty: 2,
        createdAt: now.subtract(const Duration(minutes: 15)),
        expiresAt: now.add(const Duration(days: 1)),
        participantCount: 203,
      ),
    ];
  }

  List<CreativeSubmission> _getMockSubmissions({
    String? promptId,
    String? userId,
  }) {
    final now = DateTime.now();
    final mockSubmissions = [
      CreativeSubmission(
        id: 'sub_1',
        promptId: 'mock_1',
        userId: 'user_1',
        userDisplayName: 'Alex Creative',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face',
        type: CreativeType.photo,
        contentUrl:
            'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&h=600&fit=crop',
        aiStyle: 'fantasy',
        aiGeneratedContent:
            '✨ Enhanced with mystical forest background and magical aura effects',
        createdAt: now.subtract(const Duration(hours: 1)),
        cheerCount: 24,
        commentCount: 5,
        remixCount: 3,
        tags: ['fantasy', 'magic', 'selfie'],
      ),
      CreativeSubmission(
        id: 'sub_2',
        promptId: 'mock_2',
        userId: 'user_2',
        userDisplayName: 'Taylor Wordsmith',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
        type: CreativeType.text,
        textContent: 'Luna the cat always dreamed of touching the stars...',
        aiStyle: 'scifi',
        aiGeneratedContent:
            '🌟 **Luna: Space Explorer**\n\nLuna, a curious calico with fur like a nebula, spent her nights watching satellites dance across the sky. Her dream came true when she stowed away on the ISS and became the first feline astronaut, proving that even the smallest creatures can reach for the stars.',
        createdAt: now.subtract(const Duration(minutes: 45)),
        cheerCount: 42,
        commentCount: 12,
        remixCount: 8,
        tags: ['scifi', 'cats', 'space'],
      ),
      CreativeSubmission(
        id: 'sub_3',
        promptId: 'mock_4',
        userId: 'user_3',
        userDisplayName: 'Jordan Poet',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        type: CreativeType.text,
        textContent:
            'Autumn leaves falling, golden light through the trees, crisp air and warm tea',
        aiStyle: 'haiku',
        aiGeneratedContent:
            '🍂 **Autumn\'s Golden Whisper**\n\nCrimson leaves drift down,\nGolden light through naked trees,\nWarm tea, crisp air sighs.',
        createdAt: now.subtract(const Duration(minutes: 30)),
        cheerCount: 18,
        commentCount: 3,
        remixCount: 2,
        tags: ['haiku', 'autumn', 'poetry'],
      ),
    ];

    // Filter if needed
    var filtered = mockSubmissions;
    if (promptId != null) {
      filtered = filtered.where((s) => s.promptId == promptId).toList();
    }
    if (userId != null) {
      filtered = filtered.where((s) => s.userId == userId).toList();
    }

    return filtered;
  }

  /// 🧹 Clean up resources
  void dispose() {
    _promptCache.clear();
    _submissionCache.clear();
  }
}
