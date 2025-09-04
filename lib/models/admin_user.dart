import 'package:equatable/equatable.dart';

enum UserStatus {
  active,
  suspended,
  deleted,
}

enum AccountType {
  guest,
  registered,
  premium,
  superadmin,
}

class AdminUser extends Equatable {
  final String id;
  final String email;
  final String? name;
  final AccountType accountType;
  final UserStatus status;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastSignIn;
  final DateTime? premiumExpiresAt;
  final int totalQuestions;
  final int dailyQuestions;
  final DateTime? lastQuestionAt;
  final Map<String, dynamic>? metadata;

  const AdminUser({
    required this.id,
    required this.email,
    this.name,
    required this.accountType,
    this.status = UserStatus.active,
    required this.isEmailVerified,
    required this.createdAt,
    this.lastSignIn,
    this.premiumExpiresAt,
    this.totalQuestions = 0,
    this.dailyQuestions = 0,
    this.lastQuestionAt,
    this.metadata,
  });

  factory AdminUser.fromSupabaseUser(Map<String, dynamic> data) {
    return AdminUser(
      id: data['id'],
      email: data['email'] ?? '',
      name: data['raw_user_meta_data']?['name'] as String?,
      accountType: _parseAccountType(data),
      status: _parseUserStatus(data['status']),
      isEmailVerified: data['email_confirmed_at'] != null,
      createdAt: DateTime.parse(data['created_at']),
      lastSignIn: data['last_sign_in_at'] != null 
          ? DateTime.parse(data['last_sign_in_at']) 
          : null,
      premiumExpiresAt: data['premium_expires_at'] != null 
          ? DateTime.parse(data['premium_expires_at']) 
          : null,
      totalQuestions: data['total_questions'] ?? 0,
      dailyQuestions: data['daily_questions'] ?? 0,
      lastQuestionAt: data['last_question_at'] != null 
          ? DateTime.parse(data['last_question_at']) 
          : null,
      metadata: data['raw_user_meta_data'] as Map<String, dynamic>?,
    );
  }

  static AccountType _parseAccountType(Map<String, dynamic> data) {
    final metadata = data['raw_user_meta_data'] as Map<String, dynamic>?;
    
    if (metadata?['is_superadmin'] == true) {
      return AccountType.superadmin;
    }
    
    if (metadata?['is_premium'] == true || data['premium_expires_at'] != null) {
      return AccountType.premium;
    }
    
    if (data['email_confirmed_at'] != null) {
      return AccountType.registered;
    }
    
    return AccountType.guest;
  }

  static UserStatus _parseUserStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'suspended':
        return UserStatus.suspended;
      case 'deleted':
        return UserStatus.deleted;
      default:
        return UserStatus.active;
    }
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? name,
    AccountType? accountType,
    UserStatus? status,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastSignIn,
    DateTime? premiumExpiresAt,
    int? totalQuestions,
    int? dailyQuestions,
    DateTime? lastQuestionAt,
    Map<String, dynamic>? metadata,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      status: status ?? this.status,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      dailyQuestions: dailyQuestions ?? this.dailyQuestions,
      lastQuestionAt: lastQuestionAt ?? this.lastQuestionAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'account_type': accountType.name,
      'status': status.name,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in': lastSignIn?.toIso8601String(),
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'total_questions': totalQuestions,
      'daily_questions': dailyQuestions,
      'last_question_at': lastQuestionAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get accountTypeDisplay {
    switch (accountType) {
      case AccountType.guest:
        return 'Guest';
      case AccountType.registered:
        return 'Registered';
      case AccountType.premium:
        return 'Premium';
      case AccountType.superadmin:
        return 'Super Admin';
    }
  }

  String get statusDisplay {
    switch (status) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.deleted:
        return 'Deleted';
    }
  }

  bool get isPremiumActive {
    if (accountType != AccountType.premium) return false;
    if (premiumExpiresAt == null) return true; // Lifetime premium
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  String get premiumStatus {
    if (accountType != AccountType.premium) return 'Not Premium';
    if (premiumExpiresAt == null) return 'Lifetime Premium';
    
    final now = DateTime.now();
    if (premiumExpiresAt!.isAfter(now)) {
      final daysLeft = premiumExpiresAt!.difference(now).inDays;
      return 'Expires in $daysLeft days';
    } else {
      return 'Expired';
    }
  }

  int get dailyQuestionLimit {
    switch (accountType) {
      case AccountType.premium:
      case AccountType.superadmin:
        return -1; // Unlimited
      case AccountType.registered:
        return 60;
      case AccountType.guest:
        return 30;
    }
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        accountType,
        status,
        isEmailVerified,
        createdAt,
        lastSignIn,
        premiumExpiresAt,
        totalQuestions,
        dailyQuestions,
        lastQuestionAt,
        metadata,
      ];

  @override
  String toString() {
    return 'AdminUser(id: $id, email: $email, accountType: $accountType, status: $status)';
  }
}