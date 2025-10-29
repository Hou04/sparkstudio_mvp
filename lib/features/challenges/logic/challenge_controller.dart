/// 🎮 Advanced Challenge Controller
/// 
/// Professional state management for challenges with reactive updates,
/// caching, and comprehensive error handling.

import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';
import '../data/challenge_model.dart';
import '../data/challenge_repository.dart';

class ChallengeController with ChangeNotifier {
  final ChallengeRepository _repository;

  // State variables
  List<ChallengeModel> _challenges = [];
  ChallengeModel? _featuredChallenge;
  Map<String, List<ChallengeModel>> _challengesByType = {};
  bool _isLoading = false;
  String? _error;
  ChallengeStatus _status = ChallengeStatus.initial;

  ChallengeController({required ChallengeRepository repository})
      : _repository = repository;

  // Getters
  List<ChallengeModel> get challenges => _challenges;
  ChallengeModel? get featuredChallenge => _featuredChallenge;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ChallengeStatus get status => _status;
  bool get hasError => _error != null;
  bool get hasChallenges => _challenges.isNotEmpty;

  /// 🚀 Initialize controller and load initial data
  Future<void> initialize() async {
    _setLoading(true);
    _setStatus(ChallengeStatus.loading);
    _clearError();

    try {
      await Future.wait([
        _loadFeaturedChallenge(),
        _loadAllChallenges(),
      ]);
      
      _setStatus(ChallengeStatus.loaded);
      Logger.success('✅ Challenge controller initialized', tag: 'ChallengeController');
    } catch (e) {
      _setError('Failed to initialize challenges: $e');
      _setStatus(ChallengeStatus.error);
      Logger.error('❌ Challenge controller initialization failed: $e', tag: 'ChallengeController');
    } finally {
      _setLoading(false);
    }
  }

  /// 🔄 Refresh all challenge data
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        _loadFeaturedChallenge(),
        _loadAllChallenges(),
      ]);
      
      notifyListeners();
      Logger.info('🔄 Challenges refreshed successfully', tag: 'ChallengeController');
    } catch (e) {
      _setError('Failed to refresh challenges: $e');
      Logger.error('❌ Challenge refresh failed: $e', tag: 'ChallengeController');
    } finally {
      _setLoading(false);
    }
  }

  /// 📅 Load today's featured challenge
  Future<void> loadFeaturedChallenge() async {
    _setLoading(true);
    _clearError();

    try {
      _featuredChallenge = await _repository.getTodaysChallenge();
      notifyListeners();
      Logger.info('🎯 Featured challenge loaded', tag: 'ChallengeController');
    } catch (e) {
      _setError('Failed to load featured challenge: $e');
      Logger.error('❌ Featured challenge load failed: $e', tag: 'ChallengeController');
    } finally {
      _setLoading(false);
    }
  }

  /// 📚 Load all active challenges
  Future<void> loadAllChallenges() async {
    _setLoading(true);
    _clearError();

    try {
      _challenges = await _repository.getAllChallenges();
      notifyListeners();
      Logger.info('📚 All challenges loaded: ${_challenges.length}', tag: 'ChallengeController');
    } catch (e) {
      _setError('Failed to load challenges: $e');
      Logger.error('❌ Challenges load failed: $e', tag: 'ChallengeController');
    } finally {
      _setLoading(false);
    }
  }

  /// 🔥 Load trending challenges
  Future<List<ChallengeModel>> loadTrendingChallenges({int limit = 5}) async {
    _setLoading(true);
    _clearError();

    try {
      final trending = await _repository.getTrendingChallenges(limit: limit);
      Logger.info('🔥 Trending challenges loaded: ${trending.length}', tag: 'ChallengeController');
      return trending;
    } catch (e) {
      _setError('Failed to load trending challenges: $e');
      Logger.error('❌ Trending challenges load failed: $e', tag: 'ChallengeController');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// 🎯 Load challenges by type
  Future<List<ChallengeModel>> loadChallengesByType(ChallengeType type) async {
    final cacheKey = type.name;
    
    // Check cache first
    if (_challengesByType.containsKey(cacheKey)) {
      return _challengesByType[cacheKey]!;
    }

    _setLoading(true);
    _clearError();

    try {
      final challenges = await _repository.getChallengesByType(type);
      _challengesByType[cacheKey] = challenges;
      notifyListeners();
      
      Logger.info('🎯 ${type.name} challenges loaded: ${challenges.length}', tag: 'ChallengeController');
      return challenges;
    } catch (e) {
      _setError('Failed to load ${type.name} challenges: $e');
      Logger.error('❌ ${type.name} challenges load failed: $e', tag: 'ChallengeController');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// 🔍 Search challenges
  Future<List<ChallengeModel>> searchChallenges(String query) async {
    if (query.isEmpty) return _challenges;

    _setLoading(true);
    _clearError();

    try {
      final results = await _repository.searchChallenges(query);
      Logger.info('🔍 Challenge search completed: "${query}" - ${results.length} results', tag: 'ChallengeController');
      return results;
    } catch (e) {
      _setError('Search failed: $e');
      Logger.error('❌ Challenge search failed: $e', tag: 'ChallengeController');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// 🎯 Get challenge by ID
  Future<ChallengeModel?> getChallengeById(String id) async {
    // Check local cache first
    final localChallenge = _challenges.firstWhere(
      (challenge) => challenge.id == id,
      orElse: () => _featuredChallenge?.id == id ? _featuredChallenge! : ChallengeModel(
        id: '',
        title: '',
        description: '',
        type: ChallengeType.text,
        createdAt: DateTime.now(),
      ),
    );

    if (localChallenge.id.isNotEmpty) {
      return localChallenge;
    }

    _setLoading(true);
    _clearError();

    try {
      final challenge = await _repository.getChallengeById(id);
      if (challenge != null) {
        // Add to local cache
        _challenges.add(challenge);
        notifyListeners();
      }
      
      return challenge;
    } catch (e) {
      _setError('Failed to load challenge: $e');
      Logger.error('❌ Challenge load by ID failed: $e', tag: 'ChallengeController');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 📊 Get challenge statistics
  Future<Map<String, dynamic>> getChallengeStats(String challengeId) async {
    _setLoading(true);
    _clearError();

    try {
      final stats = await _repository.getChallengeStats(challengeId);
      Logger.info('📊 Stats loaded for challenge: $challengeId', tag: 'ChallengeController');
      return stats;
    } catch (e) {
      _setError('Failed to load challenge stats: $e');
      Logger.error('❌ Challenge stats load failed: $e', tag: 'ChallengeController');
      return {
        'participant_count': 0,
        'submission_count': 0,
        'total_cheers': 0,
        'total_comments': 0,
        'engagement_rate': 0.0,
      };
    } finally {
      _setLoading(false);
    }
  }

  /// 👤 Get user's challenge history
  Future<List<Map<String, dynamic>>> getUserChallengeHistory(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final history = await _repository.getUserChallengeHistory(userId);
      Logger.info('👤 User challenge history loaded: ${history.length} entries', tag: 'ChallengeController');
      return history;
    } catch (e) {
      _setError('Failed to load user challenge history: $e');
      Logger.error('❌ User challenge history load failed: $e', tag: 'ChallengeController');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// 🏆 Get challenge leaderboard
  Future<List<Map<String, dynamic>>> getChallengeLeaderboard(String challengeId) async {
    _setLoading(true);
    _clearError();

    try {
      final leaderboard = await _repository.getChallengeLeaderboard(challengeId);
      Logger.info('🏆 Leaderboard loaded for challenge: $challengeId', tag: 'ChallengeController');
      return leaderboard;
    } catch (e) {
      _setError('Failed to load leaderboard: $e');
      Logger.error('❌ Leaderboard load failed: $e', tag: 'ChallengeController');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// 🧹 Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 🗑️ Clear cache
  void clearCache() {
    _challenges.clear();
    _featuredChallenge = null;
    _challengesByType.clear();
    _repository.clearCache();
    notifyListeners();
    Logger.info('🧹 Challenge cache cleared', tag: 'ChallengeController');
  }

  // 🛠️ PRIVATE HELPER METHODS

  Future<void> _loadFeaturedChallenge() async {
    _featuredChallenge = await _repository.getTodaysChallenge();
  }

  Future<void> _loadAllChallenges() async {
    _challenges = await _repository.getAllChallenges();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
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

  void _setStatus(ChallengeStatus status) {
    _status = status;
    notifyListeners();
  }

  /// 🧪 Mock methods for development
  Future<void> mockInitialize() async {
    _setLoading(true);
    _setStatus(ChallengeStatus.loading);

    await Future.delayed(const Duration(seconds: 2));

    _challenges = _getMockChallenges();
    _featuredChallenge = _challenges.first;
    _setStatus(ChallengeStatus.loaded);

    _setLoading(false);
    Logger.success('✅ Mock challenges initialized', tag: 'ChallengeController');
  }

  List<ChallengeModel> _getMockChallenges() {
    final now = DateTime.now();
    return [
      ChallengeModel(
        id: 'mock_1',
        title: '🌟 Magic Selfie Transformation',
        description: 'Transform your selfie into a fantasy character using AI magic! Add mystical elements, enchanted backgrounds, or superhero vibes.',
        type: ChallengeType.photo,
        aiStyle: 'fantasy',
        tags: ['selfie', 'fantasy', 'ai', 'transformation'],
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
        description: 'Write a short story about a cat who dreams of exploring space. Let AI help you expand your ideas into an epic tale!',
        type: ChallengeType.text,
        aiStyle: 'scifi',
        tags: ['story', 'scifi', 'cats', 'adventure'],
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
        description: 'Create a 30-second video showing your current mood using creative transitions and effects.',
        type: ChallengeType.video,
        aiStyle: 'cinematic',
        tags: ['video', 'mood', 'cinematic', 'creative'],
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

/// 🎯 Challenge Status Enum
enum ChallengeStatus {
  initial,
  loading,
  loaded,
  error,
}

/// 🔧 Challenge Status Extensions
extension ChallengeStatusExtensions on ChallengeStatus {
  bool get isInitial => this == ChallengeStatus.initial;
  bool get isLoading => this == ChallengeStatus.loading;
  bool get isLoaded => this == ChallengeStatus.loaded;
  bool get isError => this == ChallengeStatus.error;
}