import 'package:equatable/equatable.dart';

class Badge extends Equatable {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final BadgeCategory category;
  final int requirement;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.requirement,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Badge copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    BadgeCategory? category,
    int? requirement,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      requirement: requirement ?? this.requirement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'category': category.name,
      'requirement': requirement,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      category: BadgeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BadgeCategory.general,
      ),
      requirement: json['requirement'] as int,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        emoji,
        category,
        requirement,
        isUnlocked,
        unlockedAt,
      ];
}

enum BadgeCategory {
  general,
  streak,
  questions,
  subjects,
  timing,
}
