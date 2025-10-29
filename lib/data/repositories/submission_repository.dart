/// 📤 Advanced Submission Repository
///
/// Professional repository handling submission operations with error handling,
/// caching, and business logic separation.

import '../models/creative_models.dart';
import '../supabase/submission_service.dart';
import 'ai/ai_generation_service.dart';

class SubmissionRepository {
  final SubmissionService _submissionService;
  final AiGenerationService _aiService;

  final Map<String, CreativeSubmission> _cache = {};

  SubmissionRepository({
    required SubmissionService submissionService,
    required AiGenerationService aiService,
  }) : _submissionService = submissionService,
       _aiService = aiService;

  /// 🆕 Submit a new creative entry
  Future<CreativeSubmission> submit({
    required String challengeId,
    required String userId,
    required CreativeType type,
    String? textResponse,
    String? imagePath,
    String? aiStyle,
    bool enhanceWithAI = true,
  }) async {
    try {
      String? mediaUrl;

      // Upload media if provided
      if (imagePath != null && imagePath.isNotEmpty) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';
        mediaUrl = await _submissionService.uploadMedia(imagePath, fileName);
      }

      // Create submission object
      final submission = CreativeSubmission(
        id: _generateId(),
        promptId: challengeId,
        userId: userId,
        userDisplayName: 'Current User', // Would come from user service
        type: type,
        contentUrl: mediaUrl,
        textContent: textResponse,
        aiStyle: aiStyle,
        createdAt: DateTime.now(),
      );

      // Enhance with AI if requested and text content exists
      if (enhanceWithAI && textResponse != null && textResponse.isNotEmpty) {
        try {
          final style = CreativeStyle.values.firstWhere(
            (s) =>
                s.displayName.toLowerCase() ==
                (aiStyle ?? 'creative').toLowerCase(),
            orElse: () => CreativeStyle.creative,
          );

          final aiRequest = AiGenerationRequest(
            prompt: textResponse,
            style: style,
            baseContent: textResponse,
          );

          final aiResponse = await _aiService.generateCreativeText(aiRequest);
          final enhancedSubmission = submission.copyWith(
            aiGeneratedContent: aiResponse.generatedContent,
            aiMetadata: {
              'model': aiResponse.model.name,
              'confidence': aiResponse.confidence,
              'tokens_used': aiResponse.tokensUsed,
            },
          );

          // Save to database
          await _submissionService.addSubmission(enhancedSubmission);
          _cache[enhancedSubmission.id] = enhancedSubmission;

          return enhancedSubmission;
        } catch (e) {
          // If AI enhancement fails, save original submission
          print('⚠️ AI enhancement failed: $e');
        }
      }

      // Save original submission
      await _submissionService.addSubmission(submission);
      _cache[submission.id] = submission;

      return submission;
    } catch (e) {
      throw Exception('Failed to submit creation: $e');
    }
  }

  /// 📥 Get submissions with filtering
  Future<List<CreativeSubmission>> getSubmissions({
    String? challengeId,
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final submissions = await _submissionService.fetchSubmissions(
        challengeId: challengeId,
        userId: userId,
        limit: limit,
        offset: offset,
      );

      // Update cache
      for (final submission in submissions) {
        _cache[submission.id] = submission;
      }

      return submissions;
    } catch (e) {
      throw Exception('Failed to fetch submissions: $e');
    }
  }

  /// 🔄 Get user's recent submissions
  Future<List<CreativeSubmission>> getUserSubmissions(String userId) {
    return getSubmissions(userId: userId);
  }

  /// 🎯 Get submission by ID
  Future<CreativeSubmission?> getSubmission(String id) async {
    // Check cache first
    if (_cache.containsKey(id)) {
      return _cache[id];
    }

    try {
      final submissions = await getSubmissions();
      return submissions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// ✏️ Update existing submission
  Future<CreativeSubmission> updateSubmission(
    CreativeSubmission submission,
  ) async {
    try {
      await _submissionService.updateSubmission(submission);
      _cache[submission.id] = submission;
      return submission;
    } catch (e) {
      throw Exception('Failed to update submission: $e');
    }
  }

  /// 🗑️ Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _submissionService.deleteSubmission(submissionId);
      _cache.remove(submissionId);
    } catch (e) {
      throw Exception('Failed to delete submission: $e');
    }
  }

  /// 🔍 Search submissions
  Future<List<CreativeSubmission>> searchSubmissions(String query) async {
    try {
      return await _submissionService.searchSubmissions(query);
    } catch (e) {
      throw Exception('Failed to search submissions: $e');
    }
  }

  /// 🧹 Clear cache
  void clearCache() {
    _cache.clear();
  }

  String _generateId() {
    return 'sub_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
