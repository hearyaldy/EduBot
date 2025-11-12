import 'package:equatable/equatable.dart';

class StreakData extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastUsedDate;
  final DateTime firstUsedDate;
  final int totalDaysUsed;
  final List<DateTime> usageDates;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastUsedDate,
    required this.firstUsedDate,
    required this.totalDaysUsed,
    required this.usageDates,
  });

  factory StreakData.initial() {
    final now = DateTime.now();
    return StreakData(
      currentStreak: 0,
      longestStreak: 0,
      lastUsedDate: now,
      firstUsedDate: now,
      totalDaysUsed: 0,
      usageDates: const [],
    );
  }

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastUsedDate,
    DateTime? firstUsedDate,
    int? totalDaysUsed,
    List<DateTime>? usageDates,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      firstUsedDate: firstUsedDate ?? this.firstUsedDate,
      totalDaysUsed: totalDaysUsed ?? this.totalDaysUsed,
      usageDates: usageDates ?? this.usageDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastUsedDate': lastUsedDate.toIso8601String(),
      'firstUsedDate': firstUsedDate.toIso8601String(),
      'totalDaysUsed': totalDaysUsed,
      'usageDates': usageDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastUsedDate: json['lastUsedDate'] != null
          ? DateTime.parse(json['lastUsedDate'] as String)
          : DateTime.now(),
      firstUsedDate: json['firstUsedDate'] != null
          ? DateTime.parse(json['firstUsedDate'] as String)
          : DateTime.now(),
      totalDaysUsed: json['totalDaysUsed'] as int? ?? 0,
      usageDates: (json['usageDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
    );
  }

  bool get hasUsedToday {
    final now = DateTime.now();
    return isSameDay(lastUsedDate, now);
  }

  bool get usedYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(lastUsedDate, yesterday);
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  List<Object?> get props => [
        currentStreak,
        longestStreak,
        lastUsedDate,
        firstUsedDate,
        totalDaysUsed,
        usageDates,
      ];
}
