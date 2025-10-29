/// 🎨 Advanced Creative Models for SparkStudio's AI-Powered Platform
/// 
/// Comprehensive data models supporting AI-enhanced creative challenges,
/// submissions, and real-time collaboration features.

import 'package:equatable/equatable.dart';

/// 🌟 Creative Prompt - Daily AI-powered challenge
class CreativePrompt extends Equatable {
  final String id;
  final String title;
  final CreativeType type;
  final String description;
  final String? aiStyle;
  final List<String> tags;
  final int difficulty; // 1-5 scale
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final int participantCount;
  final Map<String, dynamic>? aiParameters;

  const CreativePrompt({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    this.aiStyle,
    this.tags = const [],
    this.difficulty = 3,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.participantCount = 0,
    this.aiParameters,
  });

  factory CreativePrompt.fromJson(Map<String, dynamic> json) {
    return CreativePrompt(
      id: json['id'] as String,
      title: json['title'] as String,
      type: CreativeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CreativeType.text,
      ),
      description: json['description'] as String,
      aiStyle: json['ai_style'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: (json['difficulty'] as int?) ?? 3,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      participantCount: (json['participant_count'] as int?) ?? 0,
      aiParameters: json['ai_parameters'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'description': description,
      'ai_style': aiStyle,
      'tags': tags,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'participant_count': participantCount,
      'ai_parameters': aiParameters,
    };
  }

  CreativePrompt copyWith({
    String? id,
    String? title,
    CreativeType? type,
    String? description,
    String? aiStyle,
    List<String>? tags,
    int? difficulty,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    int? participantCount,
    Map<String, dynamic>? aiParameters,
  }) {
    return CreativePrompt(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      aiStyle: aiStyle ?? this.aiStyle,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      participantCount: participantCount ?? this.participantCount,
      aiParameters: aiParameters ?? this.aiParameters,
    );
  }

  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;
  bool get isTrending => participantCount > 100;
  bool get isEasy => difficulty <= 2;
  bool get isHard => difficulty >= 4;

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'CreativePrompt($title, $type, $difficulty⭐)';
}

/// 🎭 Creative Submission - User's AI-enhanced creation
class CreativeSubmission extends Equatable {
  final String id;
  final String promptId;
  final String userId;
  final String userDisplayName;
  final String? userAvatarUrl;
  final CreativeType type;
  final String? contentUrl;
  final String? textContent;
  final String? aiStyle;
  final String? aiGeneratedContent;
  final Map<String, dynamic>? aiMetadata;
  final DateTime createdAt;
  final bool isPublic;
  final int cheerCount;
  final int commentCount;
  final int remixCount;
  final List<String> tags;
  final double? aiConfidence;
  final String? parentSubmissionId; // For remixes

  const CreativeSubmission({
    required this.id,
    required this.promptId,
    required this.userId,
    required this.userDisplayName,
    this.userAvatarUrl,
    required this.type,
    this.contentUrl,
    this.textContent,
    this.aiStyle,
    this.aiGeneratedContent,
    this.aiMetadata,
    required this.createdAt,
    this.isPublic = true,
    this.cheerCount = 0,
    this.commentCount = 0,
    this.remixCount = 0,
    this.tags = const [],
    this.aiConfidence,
    this.parentSubmissionId,
  });

  factory CreativeSubmission.fromJson(Map<String, dynamic> json) {
    return CreativeSubmission(
      id: json['id'] as String,
      promptId: json['prompt_id'] as String,
      userId: json['user_id'] as String,
      userDisplayName: json['user_display_name'] as String,
      userAvatarUrl: json['user_avatar_url'] as String?,
      type: CreativeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CreativeType.text,
      ),
      contentUrl: json['content_url'] as String?,
      textContent: json['text_content'] as String?,
      aiStyle: json['ai_style'] as String?,
      aiGeneratedContent: json['ai_generated_content'] as String?,
      aiMetadata: json['ai_metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPublic: json['is_public'] as bool? ?? true,
      cheerCount: (json['cheer_count'] as int?) ?? 0,
      commentCount: (json['comment_count'] as int?) ?? 0,
      remixCount: (json['remix_count'] as int?) ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      parentSubmissionId: json['parent_submission_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt_id': promptId,
      'user_id': userId,
      'user_display_name': userDisplayName,
      'user_avatar_url': userAvatarUrl,
      'type': type.name,
      'content_url': contentUrl,
      'text_content': textContent,
      'ai_style': aiStyle,
      'ai_generated_content': aiGeneratedContent,
      'ai_metadata': aiMetadata,
      'created_at': createdAt.toIso8601String(),
      'is_public': isPublic,
      'cheer_count': cheerCount,
      'comment_count': commentCount,
      'remix_count': remixCount,
      'tags': tags,
      'ai_confidence': aiConfidence,
      'parent_submission_id': parentSubmissionId,
    };
  }

  CreativeSubmission copyWith({
    String? id,
    String? promptId,
    String? userId,
    String? userDisplayName,
    String? userAvatarUrl,
    CreativeType? type,
    String? contentUrl,
    String? textContent,
    String? aiStyle,
    String? aiGeneratedContent,
    Map<String, dynamic>? aiMetadata,
    DateTime? createdAt,
    bool? isPublic,
    int? cheerCount,
    int? commentCount,
    int? remixCount,
    List<String>? tags,
    double? aiConfidence,
    String? parentSubmissionId,
  }) {
    return CreativeSubmission(
      id: id ?? this.id,
      promptId: promptId ?? this.promptId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      type: type ?? this.type,
      contentUrl: contentUrl ?? this.contentUrl,
      textContent: textContent ?? this.textContent,
      aiStyle: aiStyle ?? this.aiStyle,
      aiGeneratedContent: aiGeneratedContent ?? this.aiGeneratedContent,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      cheerCount: cheerCount ?? this.cheerCount,
      commentCount: commentCount ?? this.commentCount,
      remixCount: remixCount ?? this.remixCount,
      tags: tags ?? this.tags,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      parentSubmissionId: parentSubmissionId ?? this.parentSubmissionId,
    );
  }

  bool get isTextSubmission => textContent != null && textContent!.isNotEmpty;
  bool get isMediaSubmission => contentUrl != null && contentUrl!.isNotEmpty;
  bool get hasAiEnhancement => aiGeneratedContent != null && aiGeneratedContent!.isNotEmpty;
  bool get isRemix => parentSubmissionId != null;
  bool get isPopular => cheerCount > 10;
  int get totalEngagement => cheerCount + commentCount + remixCount;

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'CreativeSubmission($userDisplayName, $type, $cheerCount👍)';
}

/// 🤖 Advanced AI Generation Request with Llama 2/3 support
class AiGenerationRequest extends Equatable {
  final String prompt;
  final CreativeStyle style;
  final String? baseContent;
  final AiModel model;
  final Map<String, dynamic> parameters;
  final String? context; // Additional context for the AI
  final List<String>? constraints; // Content constraints

  const AiGenerationRequest({
    required this.prompt,
    required this.style,
    this.baseContent,
    this.model = AiModel.llama3,
    this.parameters = const {
      'temperature': 0.8,
      'max_tokens': 500,
      'top_p': 0.9,
    },
    this.context,
    this.constraints,
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'style': style.name,
      'base_content': baseContent,
      'model': model.name,
      'parameters': parameters,
      'context': context,
      'constraints': constraints,
    };
  }

  @override
  List<Object?> get props => [prompt, style, model, parameters];
}

/// 🎯 AI Generation Response with enhanced metadata
class AiGenerationResponse extends Equatable {
  final String generatedContent;
  final CreativeStyle style;
  final AiModel model;
  final int tokensUsed;
  final double confidence;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;
  final List<String> variations;
  final String? reasoning;

  const AiGenerationResponse({
    required this.generatedContent,
    required this.style,
    required this.model,
    required this.tokensUsed,
    required this.confidence,
    required this.generatedAt,
    this.metadata = const {},
    this.variations = const [],
    this.reasoning,
  });

  factory AiGenerationResponse.fromJson(Map<String, dynamic> json) {
    return AiGenerationResponse(
      generatedContent: json['generated_content'] as String,
      style: CreativeStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => CreativeStyle.creative,
      ),
      model: AiModel.values.firstWhere(
        (e) => e.name == json['model'],
        orElse: () => AiModel.llama3,
      ),
      tokensUsed: json['tokens_used'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      variations: List<String>.from(json['variations'] ?? []),
      reasoning: json['reasoning'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_content': generatedContent,
      'style': style.name,
      'model': model.name,
      'tokens_used': tokensUsed,
      'confidence': confidence,
      'generated_at': generatedAt.toIso8601String(),
      'metadata': metadata,
      'variations': variations,
      'reasoning': reasoning,
    };
  }

  bool get isHighConfidence => confidence > 0.8;
  bool get hasVariations => variations.isNotEmpty;

  @override
  List<Object?> get props => [generatedContent, style, model, generatedAt];
}

/// 🎪 Creative Type Enum
enum CreativeType {
  photo('📸', 'Photo Challenge'),
  video('🎬', 'Video Challenge'),
  text('📝', 'Text Challenge'),
  audio('🎵', 'Audio Challenge'),
  mixed('🌈', 'Mixed Media');

  final String emoji;
  final String displayName;

  const CreativeType(this.emoji, this.displayName);
}

/// 🎨 Creative Style Enum for AI Enhancement
enum CreativeStyle {
  fantasy('🧙‍♀️', 'Fantasy'),
  scifi('🚀', 'Sci-Fi'),
  romance('💕', 'Romance'),
  comedy('😂', 'Comedy'),
  horror('👻', 'Horror'),
  mystery('🕵️', 'Mystery'),
  haiku('🎑', 'Haiku'),
  story('📚', 'Story'),
  poem('✍️', 'Poem'),
  caption('💬', 'Caption'),
  cinematic('🎥', 'Cinematic'),
  anime('🎌', 'Anime'),
  pixelArt('👾', 'Pixel Art'),
  surreal('🌌', 'Surreal'),
  creative('✨', 'Creative');

  final String emoji;
  final String displayName;

  const CreativeStyle(this.emoji, this.displayName);
}

/// 🤖 AI Model Enum
enum AiModel {
  llama3('llama3', 'Meta Llama 3', 'Most capable'),
  llama2('llama2', 'Meta Llama 2', 'Balanced'),
  mistral('mistral', 'Mistral 7B', 'Fast & efficient'),
  gemma('gemma', 'Google Gemma', 'Lightweight'),
  custom('custom', 'Custom Model', 'Specialized');

  final String id;
  final String displayName;
  final String description;

  const AiModel(this.id, this.displayName, this.description);
}

/// ⚡ Real-time Collaboration Session
class CollaborationSession extends Equatable {
  final String id;
  final String promptId;
  final List<String> participantIds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Map<String, dynamic> sharedState;
  final bool isActive;

  const CollaborationSession({
    required this.id,
    required this.promptId,
    required this.participantIds,
    required this.startedAt,
    this.endedAt,
    this.sharedState = const {},
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, promptId, participantIds];
}