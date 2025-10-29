/// 🎯 Advanced Challenge Repository
///
/// Professional repository handling challenge operations with caching,
/// error handling, and business logic separation.

import 'package:flutter/foundation.dart';
import '../../../core/utils/logger.dart';
import 'challenge_model.dart';
import '../../../data/supabase/challenge_service.dart';
import '../../../data/models/creative_models.dart';

class ChallengeRepository {
  final ChallengeService _challengeService;

  // Cache for performance
  final Map<String, ChallengeModel> _challengeCache = {};
  final Map<String, List<ChallengeModel>> _categoryCache = {};

  ChallengeRepository({required ChallengeService challengeService})
    : _challengeService = challengeService;

  /// 📅 Get today's featured challenge
  Future<ChallengeModel?> getTodaysChallenge() async {
    try {
      Logger.info('🎯 Fetching today\'s challenge', tag: 'ChallengeRepo');

      final challenge = await _challengeService.getTodaysChallenge();
      if (challenge != null) {
        final challengeModel = _convertCreativePromptToChallengeModel(
          challenge,
        );
        _challengeCache[challengeModel.id] = challengeModel;
        return challengeModel;
      }

      return null;
    } catch (e) {
      Logger.error(
        '❌ Failed to fetch today\'s challenge: $e',
        tag: 'ChallengeRepo',
      );
      return _getMockChallenge();
    }
  }

  /// 🔥 Get trending challenges
  Future<List<ChallengeModel>> getTrendingChallenges({int limit = 5}) async {
    try {
      final challenges = await _challengeService.getTrendingChallenges(
        limit: limit,
      );
      final challengeModels = challenges
          .map(_convertCreativePromptToChallengeModel)
          .toList();

      // Update cache
      for (final challenge in challengeModels) {
        _challengeCache[challenge.id] = challenge;
      }

      return challengeModels;
    } catch (e) {
      Logger.error(
        '❌ Failed to fetch trending challenges: $e',
        tag: 'ChallengeRepo',
      );
      return _getMockChallenges().where((c) => c.isTrending).toList();
    }
  }

  /// 📚 Get challenges by type
  Future<List<ChallengeModel>> getChallengesByType(ChallengeType type) async {
    final cacheKey = 'type_${type.name}';

    // Check cache first
    if (_categoryCache.containsKey(cacheKey)) {
      return _categoryCache[cacheKey]!;
    }

    try {
      final creativeType = _convertChallengeTypeToCreativeType(type);
      final challenges = await _challengeService.getChallengesByType(
        creativeType,
      );
      final challengeModels = challenges
          .map(_convertCreativePromptToChallengeModel)
          .toList();
      _categoryCache[cacheKey] = challengeModels;

      // Update main cache
      for (final challenge in challengeModels) {
        _challengeCache[challenge.id] = challenge;
      }

      return challengeModels;
    } catch (e) {
      Logger.error(
        '❌ Failed to fetch challenges by type: $e',
        tag: 'ChallengeRepo',
      );
      return _getMockChallenges().where((c) => c.type == type).toList();
    }
  }

  /// 🆕 Get all active challenges
  Future<List<ChallengeModel>> getAllChallenges({int limit = 50}) async {
    try {
      final challenges = await _challengeService.getAllChallenges();
      final challengeModels = challenges
          .map(_convertCreativePromptToChallengeModel)
          .toList();

      // Update cache
      for (final challenge in challengeModels) {
        _challengeCache[challenge.id] = challenge;
      }

      return challengeModels;
    } catch (e) {
      Logger.error(
        '❌ Failed to fetch all challenges: $e',
        tag: 'ChallengeRepo',
      );
      return _getMockChallenges();
    }
  }

  /// 🎯 Get challenge by ID
  Future<ChallengeModel?> getChallengeById(String id) async {
    // Check cache first
    if (_challengeCache.containsKey(id)) {
      return _challengeCache[id];
    }

    try {
      final challenge = await _challengeService.getChallengeById(id);
      if (challenge != null) {
        final challengeModel = _convertCreativePromptToChallengeModel(
          challenge,
        );
        _challengeCache[id] = challengeModel;
        return challengeModel;
      }

      return null;
    } catch (e) {
      Logger.error(
        '❌ Failed to fetch challenge by ID: $e',
        tag: 'ChallengeRepo',
      );
      return _getMockChallenge();
    }
  }

  /// 🔍 Search challenges
  Future<List<ChallengeModel>> searchChallenges(String query) async {
    try {
      final challenges = await _challengeService.searchChallenges(query);
      final challengeModels = challenges
          .map(_convertCreativePromptToChallengeModel)
          .toList();

      // Update cache
      for (final challenge in challengeModels) {
        _challengeCache[challenge.id] = challenge;
      }

      return challengeModels;
    } catch (e) {
      Logger.error('❌ Failed to search challenges: $e', tag: 'ChallengeRepo');
      return _getMockChallenges()
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// 📊 Get challenge statistics
  Future<Map<String, dynamic>> getChallengeStats(String challengeId) async {
    try {
      return await _challengeService.getChallengeStats(challengeId);
    } catch (e) {
      Logger.error(
        '❌ Failed to fetch challenge stats: $e',
        tag: 'ChallengeRepo',
      );
      return {
        'participant_count': 0,
        'submission_count': 0,
        'total_likes': 0,
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
      return await _challengeService.getUserChallengeHistory(userId);
    } catch (e) {
      Logger.error(
        '❌ Failed to fetch user challenge history: $e',
        tag: 'ChallengeRepo',
      );
      return [];
    }
  }

  /// 🏆 Get challenge leaderboard
  Future<List<Map<String, dynamic>>> getChallengeLeaderboard(
    String challengeId,
  ) async {
    try {
      return await _challengeService.getChallengeLeaderboard(challengeId);
    } catch (e) {
      Logger.error(
        '❌ Failed to fetch challenge leaderboard: $e',
        tag: 'ChallengeRepo',
      );
      return [];
    }
  }

  /// 🧹 Clear cache
  void clearCache() {
    _challengeCache.clear();
    _categoryCache.clear();
    Logger.info('🧹 Challenge cache cleared', tag: 'ChallengeRepo');
  }

  // 🧪 MOCK DATA FOR DEVELOPMENT

  ChallengeModel _getMockChallenge() {
    return ChallengeModel(
      id: 'mock_challenge_1',
      title: '🌟 Magic Selfie Transformation',
      description:
          'Transform your selfie into a fantasy character using AI magic! Add mystical elements, enchanted backgrounds, or superhero vibes.',
      type: ChallengeType.photo,
      aiStyle: 'fantasy',
      tags: ['selfie', 'fantasy', 'ai', 'transformation'],
      difficulty: 2,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      participantCount: 42,
      submissionCount: 35,
      engagementRate: 0.83,
      coverImageUrl:
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&h=300&fit=crop',
      exampleContent: 'Check out this amazing fantasy selfie transformation!',
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
      ChallengeModel(
        id: 'mock_4',
        title: '🌸 Haiku of the Season',
        description: 'Compose a beautiful haiku about your favorite season!',
        type: ChallengeType.text,
        aiStyle: 'haiku',
        tags: ['poetry', 'haiku', 'seasons'],
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 3)),
        expiresAt: now.add(const Duration(hours: 18)),
        participantCount: 203,
        submissionCount: 189,
        engagementRate: 0.93,
      ),
    ];
  }

  /// Convert CreativePrompt to ChallengeModel
  ChallengeModel _convertCreativePromptToChallengeModel(CreativePrompt prompt) {
    return ChallengeModel(
      id: prompt.id,
      title: prompt.title,
      description: prompt.description,
      type: _convertCreativeTypeToChallengeType(prompt.type),
      aiStyle: prompt.aiStyle,
      tags: prompt.tags,
      difficulty: prompt.difficulty,
      createdAt: prompt.createdAt,
      expiresAt: prompt.expiresAt,
      isActive: prompt.isActive,
      participantCount: prompt.participantCount,
      submissionCount: 0, // Default value
      engagementRate: 0.0, // Default value
      aiParameters: prompt.aiParameters,
    );
  }

  /// Convert CreativeType to ChallengeType
  ChallengeType _convertCreativeTypeToChallengeType(CreativeType creativeType) {
    switch (creativeType) {
      case CreativeType.text:
        return ChallengeType.text;
      case CreativeType.photo:
        return ChallengeType.photo;
      case CreativeType.video:
        return ChallengeType.video;
      case CreativeType.audio:
        return ChallengeType.audio;
      case CreativeType.mixed:
        return ChallengeType.mixed;
    }
  }

  /// Convert ChallengeType to CreativeType
  CreativeType _convertChallengeTypeToCreativeType(
    ChallengeType challengeType,
  ) {
    switch (challengeType) {
      case ChallengeType.text:
        return CreativeType.text;
      case ChallengeType.photo:
        return CreativeType.photo;
      case ChallengeType.video:
        return CreativeType.video;
      case ChallengeType.audio:
        return CreativeType.audio;
      case ChallengeType.mixed:
        return CreativeType.mixed;
    }
  }
}
