/// 🤖 Advanced AI Service with Multi-Model Support
///
/// Professional AI service supporting Llama 3, GPT-4, and custom models
/// with streaming, error handling, and performance optimization.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/logger.dart';

class AIService {
  static const String _baseUrl = 'https://api.sparkstudio.ai/v1';
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client;
  final String _apiKey;

  AIService({required String apiKey, http.Client? client})
    : _apiKey = apiKey,
      _client = client ?? http.Client();

  /// 🎯 Generate creative content with AI
  Future<AIResponse> generateContent(AIRequest request) async {
    try {
      Logger.info('🤖 AI Generation Request: ${request.prompt}', tag: 'AI');

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/generate'),
            headers: _buildHeaders(),
            body: jsonEncode(_buildRequestBody(request)),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final aiResponse = _parseSuccessResponse(response.body);
        Logger.success(
          '✅ AI Generation Successful: ${aiResponse.content.length} chars',
          tag: 'AI',
        );
        return aiResponse;
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      Logger.error('❌ AI Generation Failed: $e', tag: 'AI');
      throw AIException(
        'Failed to generate content: $e',
        errorCode: 'GENERATION_ERROR',
      );
    }
  }

  /// 🔄 Stream AI responses for real-time updates
  Stream<AIResponse> streamContent(AIRequest request) async* {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/generate/stream'),
            headers: _buildHeaders(),
            body: jsonEncode(_buildRequestBody(request, stream: true)),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              yield AIResponse.fromJson(data);
            } catch (e) {
              // Continue processing other lines
              continue;
            }
          }
        }
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      Logger.error('❌ AI Stream Failed: $e', tag: 'AI');
      throw AIException(
        'Stream generation failed: $e',
        errorCode: 'STREAM_ERROR',
      );
    }
  }

  /// 🎭 Generate multiple creative variations
  Future<List<AIResponse>> generateVariations(
    AIRequest request, {
    int count = 3,
  }) async {
    final variations = <AIResponse>[];

    for (int i = 0; i < count; i++) {
      try {
        final variationRequest = request.copyWith(
          temperature: 0.7 + (i * 0.1), // Increase creativity for variations
        );

        final variation = await generateContent(variationRequest);
        variations.add(variation);

        // Small delay to avoid rate limiting
        if (i < count - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        Logger.warning('⚠️ Variation $i failed: $e', tag: 'AI');
        // Continue with other variations
      }
    }

    return variations;
  }

  /// 🖼️ Generate image from prompt
  Future<String> generateImage(
    String prompt, {
    String style = 'creative',
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/generate/image'),
            headers: _buildHeaders(),
            body: jsonEncode({
              'prompt': prompt,
              'style': style,
              'model': 'dall-e-3',
              'size': '1024x1024',
              'quality': 'standard',
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String;
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      Logger.error('❌ Image generation failed: $e', tag: 'AI');
      throw AIException(
        'Image generation failed: $e',
        errorCode: 'IMAGE_ERROR',
      );
    }
  }

  /// 🎨 Enhance existing text with AI
  Future<AIResponse> enhanceText(
    String text, {
    String style = 'creative',
  }) async {
    final request = AIRequest(
      prompt:
          'Enhance and improve this text while maintaining its core meaning: $text',
      style: style,
      temperature: 0.7,
      maxTokens: 500,
    );

    return await generateContent(request);
  }

  /// 💡 Generate creative ideas based on theme
  Future<List<String>> generateIdeas(String theme, {int count = 5}) async {
    try {
      final request = AIRequest(
        prompt: 'Generate $count creative ideas for: $theme',
        style: 'creative',
        temperature: 0.9,
        maxTokens: 800,
      );

      final response = await generateContent(request);
      return _parseIdeasFromResponse(response.content, count);
    } catch (e) {
      Logger.error('❌ Idea generation failed: $e', tag: 'AI');
      return _getFallbackIdeas(theme, count);
    }
  }

  // 🛠️ PRIVATE HELPER METHODS

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      'X-SparkStudio-Version': '1.0.0',
    };
  }

  Map<String, dynamic> _buildRequestBody(
    AIRequest request, {
    bool stream = false,
  }) {
    return {
      'model': request.model?.value ?? 'llama-3-70b',
      'prompt': request.prompt,
      'style': request.style,
      'temperature': request.temperature,
      'max_tokens': request.maxTokens,
      'stream': stream,
      'parameters': {
        'top_p': request.topP,
        'frequency_penalty': request.frequencyPenalty,
        'presence_penalty': request.presencePenalty,
      },
    };
  }

  AIResponse _parseSuccessResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      final data = json['data'] ?? json;

      return AIResponse(
        content: data['content'] ?? '',
        model: AIModel.fromValue(data['model'] ?? 'llama-3-70b'),
        tokensUsed: data['tokens_used'] ?? 0,
        confidence: (data['confidence'] ?? 0.9).toDouble(),
        generatedAt: DateTime.now(),
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
    } catch (e) {
      throw AIException(
        'Failed to parse AI response: $e',
        errorCode: 'PARSE_ERROR',
      );
    }
  }

  AIException _handleError(int statusCode, String responseBody) {
    final errorCode = _getErrorCode(statusCode);
    final message = _getErrorMessage(statusCode, responseBody);

    return AIException(message, errorCode: errorCode);
  }

  String _getErrorCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'INVALID_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 429:
        return 'RATE_LIMITED';
      case 500:
        return 'SERVER_ERROR';
      case 503:
        return 'SERVICE_UNAVAILABLE';
      default:
        return 'UNKNOWN_ERROR';
    }
  }

  String _getErrorMessage(int statusCode, String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      return json['error']?['message'] ?? 'AI service error: $statusCode';
    } catch (e) {
      return 'AI service error: $statusCode';
    }
  }

  List<String> _parseIdeasFromResponse(String content, int expectedCount) {
    final lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final ideas = <String>[];

    for (final line in lines) {
      if (ideas.length >= expectedCount) break;

      // Extract the idea part (remove numbers, bullets, etc.)
      final cleanLine = line.replaceAll(RegExp(r'^[\d\.\-\*]\s*'), '').trim();
      if (cleanLine.isNotEmpty && cleanLine.length > 10) {
        ideas.add(cleanLine);
      }
    }

    // Fill with fallback ideas if needed
    while (ideas.length < expectedCount) {
      ideas.add('Creative idea ${ideas.length + 1} for theme');
    }

    return ideas.take(expectedCount).toList();
  }

  List<String> _getFallbackIdeas(String theme, int count) {
    return List.generate(count, (index) => 'Creative $theme idea ${index + 1}');
  }

  /// 🧹 Clean up resources
  void dispose() {
    _client.close();
  }
}

/// 🎯 AI Request Model
class AIRequest {
  final String prompt;
  final String style;
  final double temperature;
  final int maxTokens;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final AIModel? model;

  const AIRequest({
    required this.prompt,
    this.style = 'creative',
    this.temperature = 0.8,
    this.maxTokens = 500,
    this.topP = 0.9,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.model,
  });

  AIRequest copyWith({
    String? prompt,
    String? style,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    AIModel? model,
  }) {
    return AIRequest(
      prompt: prompt ?? this.prompt,
      style: style ?? this.style,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      model: model ?? this.model,
    );
  }
}

/// 🎨 AI Response Model
class AIResponse {
  final String content;
  final AIModel model;
  final int tokensUsed;
  final double confidence;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  const AIResponse({
    required this.content,
    required this.model,
    required this.tokensUsed,
    required this.confidence,
    required this.generatedAt,
    this.metadata = const {},
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      content: json['content'] as String,
      model: AIModel.fromValue(json['model'] as String? ?? 'llama-3-70b'),
      tokensUsed: json['tokens_used'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  bool get isHighConfidence => confidence > 0.8;
}

/// 🤖 AI Model Enum
enum AIModel {
  llama3('llama-3-70b', 'Meta Llama 3', 'Most capable model'),
  llama2('llama-2-70b', 'Meta Llama 2', 'Balanced performance'),
  gpt4('gpt-4', 'GPT-4', 'Advanced reasoning'),
  gpt35('gpt-3.5-turbo', 'GPT-3.5', 'Fast and efficient'),
  custom('custom', 'Custom Model', 'Specialized model');

  final String value;
  final String displayName;
  final String description;

  const AIModel(this.value, this.displayName, this.description);

  static AIModel fromValue(String value) {
    return AIModel.values.firstWhere(
      (model) => model.value == value,
      orElse: () => AIModel.llama3,
    );
  }
}

/// 🚨 AI Exception
class AIException implements Exception {
  final String message;
  final String errorCode;
  final DateTime timestamp;

  AIException(this.message, {required this.errorCode})
    : timestamp = DateTime.now();

  @override
  String toString() => 'AIException[$errorCode]: $message';
}
