/// 🤖 Advanced AI Generation Service with Llama 3 Integration
/// 
/// Professional AI service supporting multiple models (Llama 3, Llama 2, Mistral)
/// with real-time streaming, error handling, and performance optimization.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/creative_models.dart';

class AiGenerationService {
  static const String _baseUrl = 'https://api.sparkstudio.ai/v1';
  static const Duration _timeout = Duration(seconds: 30);
  
  final http.Client _client;
  final String _apiKey;

  AiGenerationService({required String apiKey, http.Client? client})
      : _apiKey = apiKey,
        _client = client ?? http.Client();

  /// 🎯 Generate creative text with Llama 3
  Future<AiGenerationResponse> generateCreativeText(
    AiGenerationRequest request, {
    bool stream = false,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/generate'),
        headers: _buildHeaders(),
        body: jsonEncode(_buildRequestBody(request, stream: stream)),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return _parseSuccessResponse(response.body, request.style, request.model);
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      throw AiGenerationException(
        'Failed to generate creative text: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  /// 🔄 Stream creative text generation for real-time updates
  Stream<AiGenerationResponse> streamCreativeText(AiGenerationRequest request) {
    final controller = StreamController<AiGenerationResponse>();
    
    // Simulate streaming for now - replace with real SSE implementation
    Future(() async {
      try {
        final response = await generateCreativeText(request);
        controller.add(response);
        controller.close();
      } catch (e) {
        controller.addError(e);
      }
    });

    return controller.stream;
  }

  /// 🎭 Generate multiple creative variations
  Future<List<AiGenerationResponse>> generateVariations(
    AiGenerationRequest request, {
    int count = 3,
  }) async {
    final variations = <AiGenerationResponse>[];
    
    for (int i = 0; i < count; i++) {
      final variationRequest = request.copyWith(
        parameters: {
          ...request.parameters,
          'temperature': 0.9 + (i * 0.1), // Increase creativity for variations
          'seed': DateTime.now().millisecondsSinceEpoch + i,
        },
      );
      
      try {
        final variation = await generateCreativeText(variationRequest);
        variations.add(variation);
        
        // Small delay to avoid rate limiting
        if (i < count - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        // Continue with other variations even if one fails
        continue;
      }
    }
    
    return variations;
  }

  /// ✨ Enhance existing text with AI magic
  Future<AiGenerationResponse> enhanceText(
    String text,
    CreativeStyle style, {
    AiModel model = AiModel.llama3,
  }) async {
    final request = AiGenerationRequest(
      prompt: 'Enhance and improve the following text while maintaining its core meaning: $text',
      style: style,
      baseContent: text,
      model: model,
      parameters: {
        'temperature': 0.7,
        'max_tokens': 300,
        'top_p': 0.85,
      },
    );

    return await generateCreativeText(request);
  }

  /// 🖼️ Generate image prompts for AI art
  Future<String> generateImagePrompt(String idea, CreativeStyle style) async {
    final request = AiGenerationRequest(
      prompt: 'Generate a detailed image generation prompt for: $idea',
      style: style,
      model: AiModel.llama3,
      parameters: {
        'temperature': 0.8,
        'max_tokens': 150,
        'top_p': 0.9,
      },
    );

    final response = await generateCreativeText(request);
    return _formatImagePrompt(response.generatedContent, style);
  }

  /// 🎪 Generate creative challenge ideas
  Future<List<String>> generateChallengeIdeas({
    CreativeType type = CreativeType.mixed,
    int count = 5,
  }) async {
    final request = AiGenerationRequest(
      prompt: 'Generate $count creative challenge ideas for $type. Each should be unique and inspiring.',
      style: CreativeStyle.creative,
      model: AiModel.llama3,
      parameters: {
        'temperature': 0.9,
        'max_tokens': 800,
        'top_p': 0.95,
      },
    );

    final response = await generateCreativeText(request);
    return _parseChallengeIdeas(response.generatedContent, count);
  }

  /// ⚡ Batch generate multiple requests
  Future<List<AiGenerationResponse>> batchGenerate(
    List<AiGenerationRequest> requests,
  ) async {
    final results = <AiGenerationResponse>[];
    
    for (final request in requests) {
      try {
        final result = await generateCreativeText(request);
        results.add(result);
      } catch (e) {
        // Add fallback response for failed requests
        results.add(_createFallbackResponse(request));
      }
      
      // Rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }

  // 🛠️ Private helper methods

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      'X-SparkStudio-Version': '1.0.0',
      'User-Agent': 'SparkStudio/1.0.0',
    };
  }

  Map<String, dynamic> _buildRequestBody(
    AiGenerationRequest request, {
    bool stream = false,
  }) {
    return {
      'model': request.model.id,
      'prompt': _buildPrompt(request),
      'style': request.style.name,
      'parameters': request.parameters,
      'stream': stream,
      'context': request.context,
      'constraints': request.constraints,
    };
  }

  String _buildPrompt(AiGenerationRequest request) {
    final styleInstruction = _getStyleInstruction(request.style);
    final baseContent = request.baseContent != null 
        ? '\n\nOriginal content to enhance:\n${request.baseContent}'
        : '';

    return '''
You are SparkStudio AI, a creative assistant that helps users generate amazing content.

Style: ${request.style.displayName}
$styleInstruction

User's idea: ${request.prompt}
$baseContent

Please generate creative, engaging content that matches the requested style and builds upon the user's idea. Be original, inspiring, and appropriate for all ages.
''';
  }

  String _getStyleInstruction(CreativeStyle style) {
    switch (style) {
      case CreativeStyle.haiku:
        return 'Create a beautiful haiku following the 5-7-5 syllable structure. Focus on nature, emotions, or everyday moments.';
      case CreativeStyle.poem:
        return 'Write an expressive poem with vivid imagery and emotional depth. Use creative metaphors and rhythm.';
      case CreativeStyle.story:
        return 'Craft an engaging short story with characters, conflict, and resolution. Make it compelling and memorable.';
      case CreativeStyle.fantasy:
        return 'Create a magical fantasy piece with mystical elements, heroic characters, and enchanting worlds.';
      case CreativeStyle.scifi:
        return 'Write a science fiction piece with futuristic technology, space exploration, or speculative concepts.';
      case CreativeStyle.caption:
        return 'Generate catchy, engaging social media captions that are shareable and trendy.';
      default:
        return 'Be creative, original, and engaging. Surprise and delight the user with your creativity.';
    }
  }

  AiGenerationResponse _parseSuccessResponse(
    String responseBody,
    CreativeStyle style,
    AiModel model,
  ) {
    try {
      final json = jsonDecode(responseBody);
      final data = json['data'] ?? json;
      
      return AiGenerationResponse(
        generatedContent: data['generated_content'] ?? '',
        style: style,
        model: model,
        tokensUsed: data['tokens_used'] ?? 0,
        confidence: (data['confidence'] ?? 0.9).toDouble(),
        generatedAt: DateTime.now(),
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        variations: List<String>.from(data['variations'] ?? []),
        reasoning: data['reasoning'],
      );
    } catch (e) {
      throw AiGenerationException(
        'Failed to parse AI response: $e',
        errorCode: 'PARSE_ERROR',
      );
    }
  }

  Exception _handleError(int statusCode, String responseBody) {
    final errorCode = _getErrorCode(statusCode);
    final message = _getErrorMessage(statusCode, responseBody);
    
    return AiGenerationException(message, errorCode: errorCode);
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

  String _formatImagePrompt(String content, CreativeStyle style) {
    return 'A stunning ${style.displayName.toLowerCase()} artwork, $content, highly detailed, vibrant colors, cinematic lighting, trending on artstation, 4k resolution, masterpiece';
  }

  List<String> _parseChallengeIdeas(String content, int expectedCount) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
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
      ideas.add('Creative challenge idea ${ideas.length + 1}');
    }
    
    return ideas.take(expectedCount).toList();
  }

  AiGenerationResponse _createFallbackResponse(AiGenerationRequest request) {
    return AiGenerationResponse(
      generatedContent: '✨ **SparkStudio AI Enhancement**\n\n'
          'While our AI is taking a creative break, here\'s some inspiration: '
          '${request.prompt} can become something amazing with your unique perspective! '
          'Try adding your personal touch and see what magic you can create. 🎨',
      style: request.style,
      model: request.model,
      tokensUsed: 0,
      confidence: 0.5,
      generatedAt: DateTime.now(),
      metadata: {'fallback': true},
    );
  }

  /// 🧹 Clean up resources
  void dispose() {
    _client.close();
  }
}

/// 🚨 AI Generation Exception with detailed error information
class AiGenerationException implements Exception {
  final String message;
  final String errorCode;
  final DateTime timestamp;

  AiGenerationException(this.message, {required this.errorCode})
      : timestamp = DateTime.now();

  @override
  String toString() => 'AiGenerationException[$errorCode]: $message';
}

// Extension for request copying
extension AiGenerationRequestCopyWith on AiGenerationRequest {
  AiGenerationRequest copyWith({
    String? prompt,
    CreativeStyle? style,
    String? baseContent,
    AiModel? model,
    Map<String, dynamic>? parameters,
    String? context,
    List<String>? constraints,
  }) {
    return AiGenerationRequest(
      prompt: prompt ?? this.prompt,
      style: style ?? this.style,
      baseContent: baseContent ?? this.baseContent,
      model: model ?? this.model,
      parameters: parameters ?? this.parameters,
      context: context ?? this.context,
      constraints: constraints ?? this.constraints,
    );
  }
}