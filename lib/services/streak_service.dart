import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_data.dart';

class StreakService {
  static const String _streakDataKey = 'streak_data';

  // Singleton pattern
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  StreakData? _currentStreakData;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    try {
      final jsonString = _prefs?.getString(_streakDataKey);
      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        _currentStreakData = StreakData.fromJson(jsonData);
      } else {
        _currentStreakData = StreakData.initial();
        await _saveStreakData();
      }
    } catch (e) {
      debugPrint('Error loading streak data: $e');
      _currentStreakData = StreakData.initial();
    }
  }

  Future<void> _saveStreakData() async {
    if (_currentStreakData == null) return;

    try {
      final jsonString = jsonEncode(_currentStreakData!.toJson());
      await _prefs?.setString(_streakDataKey, jsonString);
    } catch (e) {
      debugPrint('Error saving streak data: $e');
    }
  }

  StreakData get streakData => _currentStreakData ?? StreakData.initial();

  /// Record app usage for today and update streak
  Future<StreakUpdateResult> recordUsage() async {
    if (_currentStreakData == null) {
      await _loadStreakData();
    }

    final now = DateTime.now();
    final data = _currentStreakData!;

    // Check if already used today
    if (data.hasUsedToday) {
      return StreakUpdateResult(
        streakData: data,
        wasStreakIncreased: false,
        milestoneReached: null,
      );
    }

    int newStreak;
    bool milestoneReached = false;
    int? milestone;

    // Check if used yesterday (continue streak) or break streak
    if (data.usedYesterday) {
      newStreak = data.currentStreak + 1;
    } else if (data.currentStreak == 0) {
      // First time or restarting streak
      newStreak = 1;
    } else {
      // Streak broken, reset
      newStreak = 1;
    }

    // Check for milestone
    if (_isMilestone(newStreak)) {
      milestoneReached = true;
      milestone = newStreak;
    }

    // Update longest streak
    final newLongestStreak = newStreak > data.longestStreak
        ? newStreak
        : data.longestStreak;

    // Add today to usage dates
    final updatedUsageDates = List<DateTime>.from(data.usageDates)..add(now);

    // Create updated streak data
    final updatedData = data.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastUsedDate: now,
      totalDaysUsed: data.totalDaysUsed + 1,
      usageDates: updatedUsageDates,
    );

    _currentStreakData = updatedData;
    await _saveStreakData();

    return StreakUpdateResult(
      streakData: updatedData,
      wasStreakIncreased: true,
      milestoneReached: milestoneReached ? milestone : null,
    );
  }

  /// Check if a streak number is a milestone
  bool _isMilestone(int streak) {
    return streak == 3 ||
           streak == 7 ||
           streak == 14 ||
           streak == 30 ||
           streak == 50 ||
           streak == 100;
  }

  /// Get milestone text for display
  String getMilestoneText(int milestone) {
    switch (milestone) {
      case 3:
        return '3 Day Streak! 🎉';
      case 7:
        return 'Week Warrior! 🔥';
      case 14:
        return '2 Week Streak! 🌟';
      case 30:
        return 'Month Master! 🏆';
      case 50:
        return '50 Day Streak! 💪';
      case 100:
        return '100 Day Legend! 👑';
      default:
        return '$milestone Day Streak! 🎊';
    }
  }

  /// Check if streak needs to be reset (called on app start)
  Future<bool> checkAndResetIfNeeded() async {
    if (_currentStreakData == null) {
      await _loadStreakData();
    }

    final data = _currentStreakData!;

    // If last used was today, no reset needed
    if (data.hasUsedToday) {
      return false;
    }

    // If last used was yesterday, streak is still valid
    if (data.usedYesterday) {
      return false;
    }

    // If last used was 2+ days ago and streak > 0, reset streak
    if (data.currentStreak > 0) {
      final resetData = data.copyWith(currentStreak: 0);
      _currentStreakData = resetData;
      await _saveStreakData();
      return true; // Streak was reset
    }

    return false;
  }

  /// Get days until next milestone
  int daysUntilNextMilestone() {
    final currentStreak = _currentStreakData?.currentStreak ?? 0;
    final milestones = [3, 7, 14, 30, 50, 100];

    for (final milestone in milestones) {
      if (currentStreak < milestone) {
        return milestone - currentStreak;
      }
    }

    return 0; // Already reached all milestones
  }

  /// Reset all streak data (for testing or user request)
  Future<void> resetAllData() async {
    _currentStreakData = StreakData.initial();
    await _saveStreakData();
  }
}

class StreakUpdateResult {
  final StreakData streakData;
  final bool wasStreakIncreased;
  final int? milestoneReached;

  const StreakUpdateResult({
    required this.streakData,
    required this.wasStreakIncreased,
    this.milestoneReached,
  });
}
