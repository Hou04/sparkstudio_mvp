/// 🎮 Advanced AI Controller with State Management
/// 
/// Professional controller handling AI interactions, state management,
/// and real-time updates for the UI.

import 'package:flutter/material.dart';
import '../data/ai_service.dart';

class AIController with ChangeNotifier {
  final AIService _aiService;
  
  // State variables
  AIResponse? _currentResponse;
  bool _isGenerating = false;
  String? _error;
  List<AIResponse> _history = [];
  List<String> _recentPrompts = [];

  AIController({required AIService aiService}) : _aiService = aiService;

  // Getters
  AIResponse? get currentResponse => _currentResponse;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  List<AIResponse> get history => _history;
  List<String> get recentPrompts => _recentPrompts;
  bool get hasHistory => _history.isNotEmpty;

  /// 🎯 Generate content with AI
  Future<void> generateContent({
    required String prompt,
    String style = 'creative',
    double temperature = 0.8,
    int maxTokens = 500,
    AIModel? model,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final request = AIRequest(
        prompt: prompt,
        style: style,
        temperature: temperature,
        maxTokens: maxTokens,
        model: model,
      );

      final response = await _aiService.generateContent(request);
      
      _currentResponse = response;
      _addToHistory(response);
      _addToRecentPrompts(prompt);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// 🔄 Stream content generation
  Stream<AIResponse> streamContent({
    required String prompt,
    String style = 'creative',
    double temperature = 0.8,
    int maxTokens = 500,
    AIModel? model,
  }) {
    final request = AIRequest(
      prompt: prompt,
      style: style,
      temperature: temperature,
      maxTokens: maxTokens,
      model: model,
    );

    return _aiService.streamContent(request);
  }

  /// 🎭 Generate multiple variations
  Future<List<AIResponse>> generateVariations({
    required String prompt,
    String style = 'creative',
    int count = 3,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final request = AIRequest(
        prompt: prompt,
        style: style,
        temperature: 0.9, // Higher temperature for variations
      );

      final variations = await _aiService.generateVariations(
        request,
        count: count,
      );

      _addToRecentPrompts(prompt);
      notifyListeners();
      
      return variations;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// 🖼️ Generate image from prompt
  Future<String> generateImage({
    required String prompt,
    String style = 'creative',
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final imageUrl = await _aiService.generateImage(prompt, style: style);
      _addToRecentPrompts(prompt);
      return imageUrl;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// ✨ Enhance existing text
  Future<void> enhanceText({
    required String text,
    String style = 'creative',
  }) async {
    return generateContent(
      prompt: text,
      style: style,
    );
  }

  /// 💡 Generate creative ideas
  Future<List<String>> generateIdeas({
    required String theme,
    int count = 5,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final ideas = await _aiService.generateIdeas(theme, count: count);
      _addToRecentPrompts('Ideas for: $theme');
      return ideas;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// 🧹 Clear current response
  void clearResponse() {
    _currentResponse = null;
    _error = null;
    notifyListeners();
  }

  /// 🗑️ Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 📚 Clear history
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// ⏰ Clear recent prompts
  void clearRecentPrompts() {
    _recentPrompts.clear();
    notifyListeners();
  }

  // 🛠️ PRIVATE HELPER METHODS

  void _addToHistory(AIResponse response) {
    _history.insert(0, response);
    // Keep only last 50 items
    if (_history.length > 50) {
      _history = _history.sublist(0, 50);
    }
  }

  void _addToRecentPrompts(String prompt) {
    if (!_recentPrompts.contains(prompt)) {
      _recentPrompts.insert(0, prompt);
      // Keep only last 10 prompts
      if (_recentPrompts.length > 10) {
        _recentPrompts = _recentPrompts.sublist(0, 10);
      }
    }
  }

  /// 🧪 Mock method for development
  Future<void> mockGenerateContent(String prompt) async {
    _isGenerating = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _currentResponse = AIResponse(
      content: '✨ **Enhanced Creative Response**\n\n'
          'Your prompt "$prompt" has been transformed into something magical! '
          'This is a mock response for development purposes. '
          'In production, this would be generated by advanced AI models.\n\n'
          '🌟 *SparkStudio AI is here to amplify your creativity!*',
      model: AIModel.llama3,
      tokensUsed: 150,
      confidence: 0.95,
      generatedAt: DateTime.now(),
    );

    _addToHistory(_currentResponse!);
    _addToRecentPrompts(prompt);

    _isGenerating = false;
    notifyListeners();
  }
}