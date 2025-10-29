// 🎨 Advanced Creative Provider
//
// Professional state management for creative features with reactive updates,
// AI integration, and comprehensive error handling.

import 'package:flutter/foundation.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/creative_models.dart';
import '../../../data/repositories/supabase/creative_service.dart';
import '../../../data/repositories/ai/ai_generation_service.dart';

class CreativeProvider extends ChangeNotifier {
  final CreativeService _creativeService;
  final AiGenerationService _aiService;

  // State variables
  List<CreativePrompt> _todayPrompts = [];
  List<CreativeSubmission> _submissions = [];
  List<CreativeSubmission> _feedSubmissions = [];
  bool _isLoading = false;
  bool _isGeneratingAi = false;
  String? _error;
  CreativeStatus _status = CreativeStatus.initial;
  String? _aiGeneratedContent;

  // Cache for performance
  final Map<String, List<CreativeSubmission>> _submissionsByPrompt = {};
  final Map<String, CreativePrompt> _promptCache = {};

  CreativeProvider({
    required CreativeService creativeService,
    required AiGenerationService aiService,
  })  : _creativeService = creativeService,
        _aiService = aiService;

  // Getters
  List<CreativePrompt> get todayPrompts => List.unmodifiable(_todayPrompts);
  List<CreativeSubmission> get submissions => List.unmodifiable(_submissions);
  List<CreativeSubmission> get feedSubmissions => List.unmodifiable(_feedSubmissions);
  bool get isLoading => _isLoading;
  bool get isGeneratingAi => _isGeneratingAi;
  String? get error => _error;
  CreativeStatus get status => _status;
  String? get aiGeneratedContent => _aiGeneratedContent;
  bool get hasError => _error != null;
  bool get hasPrompts => _todayPrompts.isNotEmpty;
  bool get hasSubmissions => _submissions.isNotEmpty;

  /// 🚀 Initialize the provider with all necessary data
  Future<void> initialize() async {
    _setLoading(true);
    _setStatus(CreativeStatus.loading);
    _clearError();

    try {
      await Future.wait([
        _loadTodayPrompts(),
        _loadFeedSubmissions(),
      ]);

      _setStatus(CreativeStatus.loaded);
      Logger.success('✅ Creative provider initialized', tag: 'CreativeProvider');
    } catch (e, st) {
      _setError('Failed to initialize creative features: $e');
      _setStatus(CreativeStatus.error);
      Logger.error('❌ Creative provider initialization failed: $e\n$st', tag: 'CreativeProvider');
    } finally {
      _setLoading(false);
    }
  }

  /// 🔄 Refresh all data
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        _loadTodayPrompts(),
        _loadFeedSubmissions(),
      ]);

      Logger.info('🔄 Creative data refreshed', tag: 'CreativeProvider');
    } catch (e, st) {
      _setError('Failed to refresh data: $e');
      Logger.error('❌ Creative refresh failed: $e\n$st', tag: 'CreativeProvider');
    } finally {
      _setLoading(false);
    }
  }

  /// 📅 Load today's creative prompts (public)
  Future<void> fetchTodayPrompts() async {
    _setLoading(true);
    _clearError();

    try {
      await _loadTodayPrompts();
      Logger.info('📅 Today\'s prompts loaded: ${_todayPrompts.length}', tag: 'CreativeProvider');
    } catch (e, st) {
      _setError('Failed to load today\'s prompts: $e');
      Logger.error('❌ Today\'s prompts load failed: $e\n$st', tag: 'CreativeProvider');
    } finally {
      _setLoading(false);
    }
  }

  /// 📚 Load all prompts (public)
  Future<void> fetchAllPrompts() async {
    _setLoading(true);
    _clearError();

    try {
      // dynamic call to support multiple service method signatures/return types
      final prompts = await (_creativeService as dynamic).getAllPrompts();
      _todayPrompts = (prompts as List<CreativePrompt>?) ?? [];
      notifyListeners();
      Logger.info('📚 All prompts loaded: ${_todayPrompts.length}', tag: 'CreativeProvider');
    } catch (e, st) {
      _setError('Failed to load prompts: $e');
      Logger.error('❌ Prompts load failed: $e\n$st', tag: 'CreativeProvider');
    } finally {
      _setLoading(false);
    }
  }

  /// 📥 Load submissions for a specific prompt
  Future<void> fetchSubmissionsForPrompt(String promptId) async {
    _setLoading(true);
    _clearError();

    try {
      final dynamic res = await (_creativeService as dynamic).getSubmissionsByPrompt(promptId);
      final submissions = (res as List<CreativeSubmission>?) ?? [];
      _submissionsByPrompt[promptId] = submissions;
      notifyListeners();
      Logger.info('📥 Submissions loaded for prompt $promptId: ${submissions.length}', tag: 'CreativeProvider');
    } catch (e, st) {
      _setError('Failed to load submissions: $e');
      Logger.error('❌ Submissions load failed: $e\n$st', tag: 'CreativeProvider');
    } finally {
      _setLoading(false);
    }
  }

  /// 🌐 Load all submissions for the feed
  Future<void> fetchFeedSubmissions() async {
    _setLoading(true);
    _clearError();

    try {
      await _loadFeedSubmissions();
      Logger.info('🌐 Feed submissions loaded: ${_feedSubmissions.length}', tag: 'CreativeProvider');
    } catch (e, st) {
      _setError('Failed to load feed submissions: $e');
      Logger.error('❌ Feed submissions load failed: $e\n$st', tag: 'CreativeProvider');
    } finally {
      _setLoading(false);
    }
  }

  /// 🆕 Add a new creative submission
  Future<bool> addSubmission(CreativeSubmission submission) async {
    _setLoading(true);
    _clearError();

    try {
      // dynamic call to support various signatures (void, bool, object, etc.)
      await (_creativeService as dynamic).addSubmission(submission);

      // Update local state
      _submissions.insert(0, submission);
      _feedSubmissions.insert(0, submission);

      // Update prompt-specific cache
      final listForPrompt = _submissionsByPrompt[submission.promptId];
      if (listForPrompt != null) {
        listForPrompt.insert(0, submission);
      }

      notifyListeners();
      Logger.success('✅ Submission added: ${submission.id}', tag: 'CreativeProvider');
      return true;
    } catch (e, st) {
      _setError('Failed to add submission: $e');
      Logger.error('❌ Submission add failed: $e\n$st', tag: 'CreativeProvider');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✏️ Update an existing submission
  Future<bool> updateSubmission(CreativeSubmission submission) async {
    _setLoading(true);
    _clearError();

    try {
      await (_creativeService as dynamic).updateSubmission(submission);

      // Update local state
      _updateSubmissionInLists(submission);

      notifyListeners();
      Logger.info('✏️ Submission updated: ${submission.id}', tag: 'CreativeProvider');
      return true;
    } catch (e, st) {
      _setError('Failed to update submission: $e');
      Logger.error('❌ Submission update failed: $e\n$st', tag: 'CreativeProvider');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🗑️ Delete a submission
  Future<bool> deleteSubmission(String submissionId) async {
    _setLoading(true);
    _clearError();

    try {
      await (_creativeService as dynamic).deleteSubmission(submissionId);

      // Remove from local state
      _removeSubmissionFromLists(submissionId);

      notifyListeners();
      Logger.info('🗑️ Submission deleted: $submissionId', tag: 'CreativeProvider');
      return true;
    } catch (e, st) {
      _setError('Failed to delete submission: $e');
      Logger.error('❌ Submission delete failed: $e\n$st', tag: 'CreativeProvider');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🤖 Generate AI content for text enhancement
  Future<String?> generateAiContent(
    String prompt,
    String style, {
    String? baseContent,
  }) async {
    _setAiGenerating(true);
    _clearError();

    try {
      final generatedContent = await (_aiService as dynamic).generateCreativeText(
        prompt,
        style,
        baseContent: baseContent,
      );

      _aiGeneratedContent = generatedContent as String?;
      notifyListeners();

      Logger.success('🤖 AI content generated: ${_aiGeneratedContent?.length ?? 0} chars', tag: 'CreativeProvider');
      return _aiGeneratedContent;
    } catch (e, st) {
      _setError('AI generation failed: $e');
      Logger.error('❌ AI generation failed: $e\n$st', tag: 'CreativeProvider');
      return null;
    } finally {
      _setAiGenerating(false);
    }
  }

  /// 🎭 Generate multiple AI variations
  Future<List<String>?> generateAiVariations(
    String prompt,
    String style, {
    int count = 3,
  }) async {
    _setAiGenerating(true);
    _clearError();

    try {
      final variations = await (_aiService as dynamic).generateVariations(
        prompt,
        style,
        count: count,
      );

      return (variations as List<String>?) ?? <String>[];
    } catch (e, st) {
      _setError('Failed to generate variations: $e');
      Logger.error('❌ AI variations failed: $e\n$st', tag: 'CreativeProvider');
      return null;
    } finally {
      _setAiGenerating(false);
    }
  }

  /// ✨ Enhance existing text with AI
  Future<String?> enhanceText(String text, String style) async {
    _setAiGenerating(true);
    _clearError();

    try {
      final enhancedText = await (_aiService as dynamic).enhanceText(text, style);
      _aiGeneratedContent = enhancedText as String?;
      notifyListeners();

      Logger.info('✨ Text enhanced: ${_aiGeneratedContent?.length ?? 0} chars', tag: 'CreativeProvider');
      return _aiGeneratedContent;
    } catch (e, st) {
      _setError('Text enhancement failed: $e');
      Logger.error('❌ Text enhancement failed: $e\n$st', tag: 'CreativeProvider');
      return null;
    } finally {
      _setAiGenerating(false);
    }
  }

  /// 🖼️ Generate image prompt for AI art
  Future<String?> generateImagePrompt(String idea, String style) async {
    _setAiGenerating(true);
    _clearError();

    try {
      final prompt = await (_aiService as dynamic).generateImagePrompt(idea, style);
      return prompt as String?;
    } catch (e, st) {
      _setError('Image prompt generation failed: $e');
      Logger.error('❌ Image prompt generation failed: $e\n$st', tag: 'CreativeProvider');
      return null;
    } finally {
      _setAiGenerating(false);
    }
  }

  /// ⬆️ Upload media file
  Future<String?> uploadMedia(String filePath, String fileName) async {
    _setLoading(true);
    _clearError();

    try {
      final url = await (_creativeService as dynamic).uploadMedia(filePath, fileName);
      return url as String?;
    } catch (e, st) {
      _setError('Media upload failed: $e');
      Logger.error('❌ Media upload failed: $e\n$st', tag: 'CreativeProvider');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 🎯 Get today's featured prompt
  CreativePrompt? get featuredPrompt {
    if (_todayPrompts.isEmpty) return null;
    try {
      return _todayPrompts.firstWhere(
        (prompt) => (prompt.isActive ?? true) && (prompt.isExpired == false),
        orElse: () => _todayPrompts.first,
      );
    } catch (_) {
      return _todayPrompts.isNotEmpty ? _todayPrompts.first : null;
    }
  }

  /// 📊 Get submissions for a specific prompt
  List<CreativeSubmission> getSubmissionsForPrompt(String promptId) {
    return List.unmodifiable(_submissionsByPrompt[promptId] ?? []);
  }

  /// 🔍 Get prompts by type
  List<CreativePrompt> getPromptsByType(CreativeType type) {
    return _todayPrompts.where((prompt) => prompt.type == type).toList(growable: false);
  }

  /// 👤 Check if user has submitted for a prompt
  bool hasUserSubmittedForPrompt(String promptId, String userId) {
    return _submissions.any(
      (submission) => submission.promptId == promptId && submission.userId == userId,
    );
  }

  /// 📝 Get user's submission for a specific prompt
  CreativeSubmission? getUserSubmissionForPrompt(String promptId, String userId) {
    try {
      return _submissions.firstWhere(
        (submission) => submission.promptId == promptId && submission.userId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  /// 🧹 Clear AI generated content
  void clearAiContent() {
    _aiGeneratedContent = null;
    notifyListeners();
  }

  /// 🧹 Clear error (public)
  void clearError() {
    _clearError();
  }

  /// 🗑️ Clear cache
  void clearCache() {
    _todayPrompts.clear();
    _submissions.clear();
    _feedSubmissions.clear();
    _submissionsByPrompt.clear();
    _promptCache.clear();
    _aiGeneratedContent = null;
    notifyListeners();
    Logger.info('🧹 Creative cache cleared', tag: 'CreativeProvider');
  }

  // 🛠️ PRIVATE HELPER METHODS

  Future<void> _loadTodayPrompts() async {
    try {
      final prompts = await (_creativeService as dynamic).getTodayPrompts();
      _todayPrompts = (prompts as List<CreativePrompt>?) ?? [];
      notifyListeners();
    } catch (e, st) {
      // bubble up so callers can handle/log
      rethrow;
    }
  }

  Future<void> _loadFeedSubmissions() async {
    try {
      final subs = await (_creativeService as dynamic).getAllSubmissions();
      _feedSubmissions = (subs as List<CreativeSubmission>?) ?? [];
      notifyListeners();
    } catch (e, st) {
      rethrow;
    }
  }

  void _updateSubmissionInLists(CreativeSubmission submission) {
    // Update in main submissions list
    final index = _submissions.indexWhere((s) => s.id == submission.id);
    if (index != -1) {
      _submissions[index] = submission;
    }

    // Update in feed submissions list
    final feedIndex = _feedSubmissions.indexWhere((s) => s.id == submission.id);
    if (feedIndex != -1) {
      _feedSubmissions[feedIndex] = submission;
    }

    // Update in prompt-specific cache
    final listForPrompt = _submissionsByPrompt[submission.promptId];
    if (listForPrompt != null) {
      final promptIndex = listForPrompt.indexWhere((s) => s.id == submission.id);
      if (promptIndex != -1) {
        listForPrompt[promptIndex] = submission;
      }
    }

    notifyListeners();
  }

  void _removeSubmissionFromLists(String submissionId) {
    // Remove from main submissions list
    _submissions.removeWhere((s) => s.id == submissionId);

    // Remove from feed submissions list
    _feedSubmissions.removeWhere((s) => s.id == submissionId);

    // Remove from prompt-specific cache
    for (final promptId in _submissionsByPrompt.keys.toList()) {
      _submissionsByPrompt[promptId]!.removeWhere((s) => s.id == submissionId);
    }

    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setAiGenerating(bool generating) {
    _isGeneratingAi = generating;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setStatus(CreativeStatus status) {
    _status = status;
    notifyListeners();
  }

  /// 🧪 Mock methods for development
  Future<void> mockInitialize() async {
    _setLoading(true);
    _setStatus(CreativeStatus.loading);

    await Future.delayed(const Duration(seconds: 2));

    _todayPrompts = _getMockPrompts();
    _feedSubmissions = _getMockSubmissions();
    _setStatus(CreativeStatus.loaded);

    _setLoading(false);
    Logger.success('✅ Mock creative provider initialized', tag: 'CreativeProvider');
  }

  Future<void> mockAddSubmission() async {
    _setLoading(true);

    await Future.delayed(const Duration(seconds: 1));

    if (_todayPrompts.isEmpty) {
      // Ensure there's at least one prompt to attach to
      _todayPrompts = _getMockPrompts();
    }

    final submission = CreativeSubmission(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      promptId: _todayPrompts.first.id,
      userId: 'mock_user',
      userDisplayName: 'Mock User',
      type: CreativeType.text,
      textContent: 'This is a mock submission created for testing! 🎨',
      createdAt: DateTime.now(),
    );

    _submissions.insert(0, submission);
    _feedSubmissions.insert(0, submission);

    _setLoading(false);
    notifyListeners();
  }

  List<CreativePrompt> _getMockPrompts() {
    final now = DateTime.now();
    return [
      CreativePrompt(
        id: 'mock_1',
        title: '🌟 Magic Selfie Transformation',
        type: CreativeType.photo,
        description: 'Transform your selfie into a fantasy character using AI magic! Add mystical elements, enchanted backgrounds, or superhero vibes.',
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
        description: 'Write a short story about a cat who dreams of exploring space. Let AI help you expand your ideas into an epic tale!',
        aiStyle: 'scifi',
        tags: ['story', 'scifi', 'cats', 'adventure'],
        difficulty: 3,
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(days: 1)),
        participantCount: 156,
      ),
    ];
  }

  List<CreativeSubmission> _getMockSubmissions() {
    final now = DateTime.now();
    return [
      CreativeSubmission(
        id: 'sub_1',
        promptId: 'mock_1',
        userId: 'user_1',
        userDisplayName: 'Creative Explorer',
        type: CreativeType.photo,
        contentUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&h=600&fit=crop',
        aiStyle: 'fantasy',
        aiGeneratedContent: '✨ Enhanced with mystical forest background and magical aura effects',
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
        userDisplayName: 'Story Weaver',
        type: CreativeType.text,
        textContent: 'Luna the cat always dreamed of touching the stars...',
        aiStyle: 'scifi',
        aiGeneratedContent: '🌟 **Luna: Space Explorer**\n\nLuna, a curious calico with fur like a nebula, spent her nights watching satellites dance across the sky. Her dream came true when she stowed away on the ISS and became the first feline astronaut.',
        createdAt: now.subtract(const Duration(minutes: 45)),
        cheerCount: 42,
        commentCount: 12,
        remixCount: 8,
        tags: ['scifi', 'cats', 'space'],
      ),
    ];
  }

  @override
  void dispose() {
    Logger.info('🧹 Creative provider disposed', tag: 'CreativeProvider');
    super.dispose();
  }
}

/// 🎯 Creative Status Enum
enum CreativeStatus {
  initial,
  loading,
  loaded,
  error,
}

/// 🔧 Creative Status Extensions
extension CreativeStatusExtensions on CreativeStatus {
  bool get isInitial => this == CreativeStatus.initial;
  bool get isLoading => this == CreativeStatus.loading;
  bool get isLoaded => this == CreativeStatus.loaded;
  bool get isError => this == CreativeStatus.error;
}
