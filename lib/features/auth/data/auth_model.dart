/// 🔐 Advanced Authentication Models
/// 
/// Professional models for user authentication, profiles, and sessions
/// with validation and serialization support.

import 'package:equatable/equatable.dart';

/// 👤 User Model with Comprehensive Profile Data
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final int streakCount;
  final int totalSubmissions;
  final int totalCheersReceived;
  final bool isEmailVerified;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.streakCount = 0,
    this.totalSubmissions = 0,
    this.totalCheersReceived = 0,
    this.isEmailVerified = false,
    this.metadata,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      streakCount: (json['streak_count'] as int?) ?? 0,
      totalSubmissions: (json['total_submissions'] as int?) ?? 0,
      totalCheersReceived: (json['total_cheers_received'] as int?) ?? 0,
      isEmailVerified: (json['email_confirmed_at'] != null),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'streak_count': streakCount,
      'total_submissions': totalSubmissions,
      'total_cheers_received': totalCheersReceived,
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    int? streakCount,
    int? totalSubmissions,
    int? totalCheersReceived,
    bool? isEmailVerified,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      streakCount: streakCount ?? this.streakCount,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      totalCheersReceived: totalCheersReceived ?? this.totalCheersReceived,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasProfile => displayName != null && displayName!.isNotEmpty;
  bool get isNewUser => totalSubmissions == 0;
  bool get isActiveCreator => totalSubmissions > 5;
  int get engagementScore => (streakCount * 10) + totalSubmissions + (totalCheersReceived ~/ 10);

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    avatarUrl,
    createdAt,
    streakCount,
    totalSubmissions,
    isEmailVerified,
  ];

  @override
  String toString() => 'UserModel($displayName, $email, $streakCount🔥)';
}

/// 🔑 Authentication Credentials
class AuthCredentials extends Equatable {
  final String email;
  final String password;
  final String? displayName;

  const AuthCredentials({
    required this.email,
    required this.password,
    this.displayName,
  });

  bool get isValidEmail => RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$"
  ).hasMatch(email);

  bool get isValidPassword => password.length >= 6;
  bool get isValidSignUp => isValidEmail && isValidPassword && displayName != null && displayName!.isNotEmpty;
  bool get isValidSignIn => isValidEmail && isValidPassword;

  @override
  List<Object?> get props => [email, password, displayName];
}

/// 🎯 Authentication Result
class AuthResult extends Equatable {
  final UserModel? user;
  final String? error;
  final bool success;
  final DateTime timestamp;

  AuthResult({
    this.user,
    this.error,
    required this.success,
  }) : timestamp = DateTime.now();

  factory AuthResult.success(UserModel user) {
    return AuthResult(user: user, success: true);
  }

  factory AuthResult.error(String error) {
    return AuthResult(error: error, success: false);
  }

  @override
  List<Object?> get props => [user, error, success, timestamp];
}

/// 📱 Session Information
class SessionInfo extends Equatable {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;
  final DateTime createdAt;

  const SessionInfo({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    required this.createdAt,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get willExpireSoon => expiresAt.isBefore(DateTime.now().add(const Duration(minutes: 5)));

  @override
  List<Object?> get props => [accessToken, userId, expiresAt];
}

/// 🚀 User Statistics
class UserStats extends Equatable {
  final int streakCount;
  final int totalSubmissions;
  final int totalCheersReceived;
  final int totalCheersGiven;
  final int totalComments;
  final int totalRemixes;
  final double engagementScore;
  final DateTime? lastSubmissionAt;

  const UserStats({
    required this.streakCount,
    required this.totalSubmissions,
    required this.totalCheersReceived,
    required this.totalCheersGiven,
    required this.totalComments,
    required this.totalRemixes,
    required this.engagementScore,
    this.lastSubmissionAt,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      streakCount: json['streak_count'] as int,
      totalSubmissions: json['total_submissions'] as int,
      totalCheersReceived: json['total_cheers_received'] as int,
      totalCheersGiven: json['total_cheers_given'] as int,
      totalComments: json['total_comments'] as int,
      totalRemixes: json['total_remixes'] as int,
      engagementScore: (json['engagement_score'] as num).toDouble(),
      lastSubmissionAt: json['last_submission_at'] != null
          ? DateTime.parse(json['last_submission_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak_count': streakCount,
      'total_submissions': totalSubmissions,
      'total_cheers_received': totalCheersReceived,
      'total_cheers_given': totalCheersGiven,
      'total_comments': totalComments,
      'total_remixes': totalRemixes,
      'engagement_score': engagementScore,
      'last_submission_at': lastSubmissionAt?.toIso8601String(),
    };
  }

  bool get isActive => streakCount > 0;
  bool get isPopular => totalCheersReceived > 50;
  int get totalEngagement => totalCheersReceived + totalComments + totalRemixes;

  @override
  List<Object?> get props => [
    streakCount,
    totalSubmissions,
    totalCheersReceived,
    engagementScore,
  ];
}