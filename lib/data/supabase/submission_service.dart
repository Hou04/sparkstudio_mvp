/// 📤 Advanced Submission Service
///
/// Professional service handling creative submissions, media uploads,
/// engagement tracking, and real-time updates.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/creative_models.dart';

class SubmissionService {
  final SupabaseClient _client;

  SubmissionService({required SupabaseClient client}) : _client = client;

  /// 🆕 Add a new creative submission
  Future<void> addSubmission(CreativeSubmission submission) async {
    try {
      await _client.from('creative_submissions').insert(submission.toJson());
      debugPrint('✅ Submission added: ${submission.id}');
    } catch (e) {
      debugPrint('❌ Error adding submission: $e');
      throw Exception('Failed to add submission: $e');
    }
  }

  /// 📥 Fetch submissions with advanced filtering
  Future<List<CreativeSubmission>> fetchSubmissions({
    String? challengeId,
    String? userId,
    CreativeType? type,
    int limit = 50,
    int offset = 0,
    bool includePrivate = false,
  }) async {
    try {
      var query = _client.from('creative_submissions').select('''
            *,
            profiles!inner(full_name, avatar_url),
            creative_prompts!inner(title, type, description)
          ''');

      if (challengeId != null) {
        query = query.filter('prompt_id', 'eq', challengeId);
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

      return (response as List)
          .map((json) => CreativeSubmission.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching submissions: $e');
      return _getMockSubmissions(
        challengeId: challengeId,
        userId: userId,
        type: type,
      );
    }
  }

  /// 🔄 Update an existing submission
  Future<void> updateSubmission(CreativeSubmission submission) async {
    try {
      await _client
          .from('creative_submissions')
          .update(submission.toJson())
          .filter('id', 'eq', submission.id);

      debugPrint('✅ Submission updated: ${submission.id}');
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

      await _client
          .from('creative_submissions')
          .delete()
          .filter('id', 'eq', submissionId)
          .filter('user_id', 'eq', user.id);

      debugPrint('✅ Submission deleted: $submissionId');
    } catch (e) {
      debugPrint('❌ Error deleting submission: $e');
      throw Exception('Failed to delete submission: $e');
    }
  }

  /// ⬆️ Upload media file to Supabase Storage
  Future<String> uploadMedia(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      // Upload file
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

  /// 👏 Add cheer to a submission
  Future<void> addCheer(String submissionId) async {
    try {
      await _client.rpc(
        'increment_cheer_count',
        params: {'submission_id': submissionId},
      );
      debugPrint('✅ Cheer added to: $submissionId');
    } catch (e) {
      debugPrint('❌ Error adding cheer: $e');
      throw Exception('Failed to add cheer: $e');
    }
  }

  /// 💬 Add comment to a submission
  Future<void> addComment({
    required String submissionId,
    required String content,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client.from('comments').insert({
        'submission_id': submissionId,
        'user_id': user.id,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Increment comment count
      await _client.rpc(
        'increment_comment_count',
        params: {'submission_id': submissionId},
      );

      debugPrint('✅ Comment added to: $submissionId');
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  /// 🔄 Get comments for a submission
  Future<List<Map<String, dynamic>>> getComments(String submissionId) async {
    try {
      final response = await _client
          .from('comments')
          .select('''
            *,
            profiles!inner(full_name, avatar_url)
          ''')
          .filter('submission_id', 'eq', submissionId)
          .order('created_at', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching comments: $e');
      return [];
    }
  }

  /// 🎭 Create a remix of a submission
  Future<CreativeSubmission> createRemix({
    required String originalSubmissionId,
    required String promptId,
    required String userId,
    required CreativeType type,
    String? contentUrl,
    String? textContent,
    String? aiStyle,
  }) async {
    try {
      final remix = CreativeSubmission(
        id: _generateId(),
        promptId: promptId,
        userId: userId,
        userDisplayName: 'Current User', // Would come from user service
        type: type,
        contentUrl: contentUrl,
        textContent: textContent,
        aiStyle: aiStyle,
        createdAt: DateTime.now(),
        parentSubmissionId: originalSubmissionId,
      );

      await addSubmission(remix);

      // Increment remix count on original submission
      await _client.rpc(
        'increment_remix_count',
        params: {'submission_id': originalSubmissionId},
      );

      debugPrint('✅ Remix created: ${remix.id}');
      return remix;
    } catch (e) {
      debugPrint('❌ Error creating remix: $e');
      throw Exception('Failed to create remix: $e');
    }
  }

  /// 🔍 Search submissions
  Future<List<CreativeSubmission>> searchSubmissions(String query) async {
    try {
      final response = await _client
          .from('creative_submissions')
          .select('''
            *,
            profiles!inner(full_name, avatar_url)
          ''')
          .textSearch('search_vector', query)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => CreativeSubmission.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching submissions: $e');
      return _getMockSubmissions()
          .where(
            (s) =>
                (s.textContent?.toLowerCase().contains(query.toLowerCase()) ??
                    false) ||
                s.userDisplayName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  /// 📊 Get submission statistics
  Future<Map<String, dynamic>> getSubmissionStats(String submissionId) async {
    try {
      final response = await _client
          .from('creative_submissions')
          .select('cheer_count, comment_count, remix_count')
          .filter('id', 'eq', submissionId)
          .single();

      return response;
    } catch (e) {
      debugPrint('❌ Error fetching submission stats: $e');
      return {'cheer_count': 0, 'comment_count': 0, 'remix_count': 0};
    }
  }

  /// 🔔 Subscribe to submission updates
  Stream<CreativeSubmission> watchSubmission(String submissionId) {
    return _client.from('creative_submissions').stream(primaryKey: ['id']).map((
      event,
    ) {
      final filtered = event.where((e) => e['id'] == submissionId).toList();
      if (filtered.isNotEmpty) {
        return CreativeSubmission.fromJson(filtered.first);
      }
      throw Exception('Submission not found');
    });
  }

  /// 🏆 Get popular submissions
  Future<List<CreativeSubmission>> getPopularSubmissions({
    int limit = 10,
    String? timeframe, // 'day', 'week', 'month'
  }) async {
    try {
      var query = _client.from('creative_submissions').select('''
            *,
            profiles!inner(full_name, avatar_url)
          ''');

      if (timeframe != null) {
        final startDate = _getStartDateForTimeframe(timeframe);
        query = query.gte('created_at', startDate.toIso8601String());
      }

      final response = await query
          .order('cheer_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CreativeSubmission.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching popular submissions: $e');
      return _getMockSubmissions().where((s) => s.isPopular).toList();
    }
  }

  // 🛠️ PRIVATE HELPER METHODS

  /// Generate unique ID
  String _generateId() {
    return 'sub_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode.abs()}';
  }

  /// Get start date for timeframe
  DateTime _getStartDateForTimeframe(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case 'day':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month - 1, now.day);
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  // 🎭 MOCK DATA FOR DEVELOPMENT

  List<CreativeSubmission> _getMockSubmissions({
    String? challengeId,
    String? userId,
    CreativeType? type,
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
            '🌟 **Luna: Space Explorer**\n\nLuna, a curious calico with fur like a nebula, spent her nights watching satellites dance across the sky.',
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

    // Apply filters
    var filtered = mockSubmissions;
    if (challengeId != null) {
      filtered = filtered.where((s) => s.promptId == challengeId).toList();
    }
    if (userId != null) {
      filtered = filtered.where((s) => s.userId == userId).toList();
    }
    if (type != null) {
      filtered = filtered.where((s) => s.type == type).toList();
    }

    return filtered;
  }
}
