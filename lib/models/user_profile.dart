import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? name;
  final bool isEmailVerified;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime? lastSignIn;
  final Map<String, dynamic>? metadata;

  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    required this.isEmailVerified,
    this.isPremium = false,
    required this.createdAt,
    this.lastSignIn,
    this.metadata,
  });

  factory UserProfile.fromSupabaseUser(dynamic user) {
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
      isEmailVerified: user.emailConfirmedAt != null,
      isPremium: user.userMetadata?['is_premium'] == true,
      createdAt: DateTime.parse(user.createdAt),
      lastSignIn: user.lastSignInAt != null 
          ? DateTime.parse(user.lastSignInAt) 
          : null,
      metadata: user.userMetadata as Map<String, dynamic>?,
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    bool? isEmailVerified,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? lastSignIn,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'is_email_verified': isEmailVerified,
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in': lastSignIn?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      isEmailVerified: json['is_email_verified'] ?? false,
      isPremium: json['is_premium'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      lastSignIn: json['last_sign_in'] != null 
          ? DateTime.parse(json['last_sign_in']) 
          : null,
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        isEmailVerified,
        isPremium,
        createdAt,
        lastSignIn,
        metadata,
      ];

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, name: $name, '
           'isEmailVerified: $isEmailVerified, isPremium: $isPremium)';
  }
}