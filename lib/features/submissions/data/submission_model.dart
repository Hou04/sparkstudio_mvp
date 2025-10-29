class SubmissionModel {
  final String id;
  final String challengeId;
  final String? userId;
  final String? textResponse;
  final String? mediaUrl;
  final DateTime createdAt;

  SubmissionModel({
    required this.id,
    required this.challengeId,
    this.userId,
    this.textResponse,
    this.mediaUrl,
    required this.createdAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String?,
      textResponse: json['text_response'] as String?,
      mediaUrl: json['media_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challenge_id': challengeId,
      'user_id': userId,
      'text_response': textResponse,
      'media_url': mediaUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
