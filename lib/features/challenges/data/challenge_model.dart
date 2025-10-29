/// 🎯 Advanced Challenge Model for SparkStudio
/// 
/// Professional model representing creative challenges with AI enhancement,
/// engagement tracking, and rich metadata.

import 'package:equatable/equatable.dart';

class ChallengeModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final String? aiStyle;
  final List<String> tags;
  final int difficulty; // 1-5 scale
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final int participantCount;
  final int submissionCount;
  final double engagementRate;
  final Map<String, dynamic>? aiParameters;
  final String? coverImageUrl;
  final String? exampleContent;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.aiStyle,
    this.tags = const [],
    this.difficulty = 3,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.participantCount = 0,
    this.submissionCount = 0,
    this.engagementRate = 0.0,
    this.aiParameters,
    this.coverImageUrl,
    this.exampleContent,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.text,
      ),
      aiStyle: json['ai_style'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: (json['difficulty'] as int?) ?? 3,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      participantCount: (json['participant_count'] as int?) ?? 0,
      submissionCount: (json['submission_count'] as int?) ?? 0,
      engagementRate: (json['engagement_rate'] as num?)?.toDouble() ?? 0.0,
      aiParameters: json['ai_parameters'] as Map<String, dynamic>?,
      coverImageUrl: json['cover_image_url'] as String?,
      exampleContent: json['example_content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'ai_style': aiStyle,
      'tags': tags,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'participant_count': participantCount,
      'submission_count': submissionCount,
      'engagement_rate': engagementRate,
      'ai_parameters': aiParameters,
      'cover_image_url': coverImageUrl,
      'example_content': exampleContent,
    };
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    String? aiStyle,
    List<String>? tags,
    int? difficulty,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    int? participantCount,
    int? submissionCount,
    double? engagementRate,
    Map<String, dynamic>? aiParameters,
    String? coverImageUrl,
    String? exampleContent,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      aiStyle: aiStyle ?? this.aiStyle,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      participantCount: participantCount ?? this.participantCount,
      submissionCount: submissionCount ?? this.submissionCount,
      engagementRate: engagementRate ?? this.engagementRate,
      aiParameters: aiParameters ?? this.aiParameters,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      exampleContent: exampleContent ?? this.exampleContent,
    );
  }

  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;
  bool get isTrending => participantCount > 100;
  bool get isEasy => difficulty <= 2;
  bool get isHard => difficulty >= 4;
  bool get hasExample => exampleContent != null && exampleContent!.isNotEmpty;
  bool get hasCoverImage => coverImageUrl != null && coverImageUrl!.isNotEmpty;

  String get difficultyLabel {
    switch (difficulty) {
      case 1: return 'Beginner';
      case 2: return 'Easy';
      case 3: return 'Medium';
      case 4: return 'Hard';
      case 5: return 'Expert';
      default: return 'Medium';
    }
  }

  String get emoji {
    switch (type) {
      case ChallengeType.photo: return '📸';
      case ChallengeType.text: return '📝';
      case ChallengeType.video: return '🎬';
      case ChallengeType.audio: return '🎵';
      case ChallengeType.mixed: return '🌈';
    }
  }

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    createdAt,
    isActive,
  ];

  @override
  String toString() => 'ChallengeModel($title, $type, $difficulty⭐)';
}

/// 🎪 Challenge Type Enum
enum ChallengeType {
  photo('Photo Challenge', 'Create visual content'),
  text('Text Challenge', 'Write creative content'),
  video('Video Challenge', 'Produce video content'),
  audio('Audio Challenge', 'Create audio content'),
  mixed('Mixed Media', 'Combine different media types');

  final String displayName;
  final String description;

  const ChallengeType(this.displayName, this.description);
}

/// 🏆 Challenge Statistics
class ChallengeStats {
  final String challengeId;
  final int totalParticipants;
  final int totalSubmissions;
  final double averageRating;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final Map<String, int> typeDistribution;
  final DateTime calculatedAt;

  const ChallengeStats({
    required this.challengeId,
    required this.totalParticipants,
    required this.totalSubmissions,
    required this.averageRating,
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.typeDistribution,
    required this.calculatedAt,
  });

  double get engagementRate => totalParticipants > 0 
      ? totalSubmissions / totalParticipants 
      : 0.0;

  bool get isPopular => totalParticipants > 50;
}