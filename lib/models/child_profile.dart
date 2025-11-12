import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class ChildProfile extends Equatable {
  final String id;
  final String name;
  final int grade;
  final String emoji;
  final int questionCount;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final Set<String> subjectsUsed;
  final List<String> unlockedBadgeIds;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.grade,
    required this.emoji,
    this.questionCount = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.createdAt,
    required this.lastUsedAt,
    this.subjectsUsed = const {},
    this.unlockedBadgeIds = const [],
  });

  factory ChildProfile.create({
    required String name,
    required int grade,
    required String emoji,
  }) {
    final now = DateTime.now();
    return ChildProfile(
      id: const Uuid().v4(),
      name: name,
      grade: grade,
      emoji: emoji,
      questionCount: 0,
      currentStreak: 0,
      longestStreak: 0,
      createdAt: now,
      lastUsedAt: now,
      subjectsUsed: const {},
      unlockedBadgeIds: const [],
    );
  }

  ChildProfile copyWith({
    String? id,
    String? name,
    int? grade,
    String? emoji,
    int? questionCount,
    int? currentStreak,
    int? longestStreak,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    Set<String>? subjectsUsed,
    List<String>? unlockedBadgeIds,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      emoji: emoji ?? this.emoji,
      questionCount: questionCount ?? this.questionCount,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      subjectsUsed: subjectsUsed ?? this.subjectsUsed,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'emoji': emoji,
      'questionCount': questionCount,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'subjectsUsed': subjectsUsed.toList(),
      'unlockedBadgeIds': unlockedBadgeIds,
    };
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      grade: json['grade'] as int,
      emoji: json['emoji'] as String,
      questionCount: json['questionCount'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : DateTime.now(),
      subjectsUsed: json['subjectsUsed'] != null
          ? Set<String>.from(json['subjectsUsed'] as List)
          : const {},
      unlockedBadgeIds: json['unlockedBadgeIds'] != null
          ? List<String>.from(json['unlockedBadgeIds'] as List)
          : const [],
    );
  }

  String get gradeDisplay {
    if (grade == 0) return 'Kindergarten';
    if (grade == 13) return 'College';
    return 'Grade $grade';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        grade,
        emoji,
        questionCount,
        currentStreak,
        longestStreak,
        createdAt,
        lastUsedAt,
        subjectsUsed,
        unlockedBadgeIds,
      ];
}

// Common emojis for child profiles
class ProfileEmojis {
  static const List<String> all = [
    '😊', '🤓', '😎', '🥳', '🤗',
    '🧑‍🎓', '👨‍🎓', '👩‍🎓', '🧒', '👦',
    '👧', '🧑', '🚀', '⭐', '🌟',
    '🎨', '📚', '🎯', '🏆', '💡',
  ];
}
