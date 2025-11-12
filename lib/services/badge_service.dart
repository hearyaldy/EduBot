import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge.dart';

class BadgeService {
  static const String _badgesKey = 'user_badges';
  static const String _subjectsUsedKey = 'subjects_used';

  // Singleton pattern
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  List<Badge> _badges = [];
  Set<String> _subjectsUsed = {};
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _initializeBadges();
    await _loadBadgeData();
    await _loadSubjectsUsed();
  }

  void _initializeBadges() {
    _badges = [
      const Badge(
        id: 'first_question',
        title: 'First Question',
        description: 'Ask your first question',
        emoji: '🎯',
        category: BadgeCategory.questions,
        requirement: 1,
      ),
      const Badge(
        id: 'week_warrior',
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        emoji: '🔥',
        category: BadgeCategory.streak,
        requirement: 7,
      ),
      const Badge(
        id: 'subject_explorer',
        title: 'Subject Explorer',
        description: 'Use 3 different subjects',
        emoji: '🌟',
        category: BadgeCategory.subjects,
        requirement: 3,
      ),
      const Badge(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Use the app before 9 AM',
        emoji: '🌅',
        category: BadgeCategory.timing,
        requirement: 1,
      ),
      const Badge(
        id: 'helpful_parent',
        title: 'Helpful Parent',
        description: 'Ask 20 questions total',
        emoji: '🏆',
        category: BadgeCategory.questions,
        requirement: 20,
      ),
    ];
  }

  Future<void> _loadBadgeData() async {
    try {
      final jsonString = _prefs?.getString(_badgesKey);
      if (jsonString != null) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final savedBadges = jsonData
            .map((json) => Badge.fromJson(json as Map<String, dynamic>))
            .toList();

        // Merge saved data with initialized badges
        _badges = _badges.map((badge) {
          final savedBadge = savedBadges.firstWhere(
            (b) => b.id == badge.id,
            orElse: () => badge,
          );
          return savedBadge;
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading badge data: $e');
    }
  }

  Future<void> _loadSubjectsUsed() async {
    try {
      final jsonString = _prefs?.getString(_subjectsUsedKey);
      if (jsonString != null) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _subjectsUsed = Set<String>.from(jsonData.cast<String>());
      }
    } catch (e) {
      debugPrint('Error loading subjects used: $e');
    }
  }

  Future<void> _saveBadgeData() async {
    try {
      final jsonData = _badges.map((badge) => badge.toJson()).toList();
      final jsonString = jsonEncode(jsonData);
      await _prefs?.setString(_badgesKey, jsonString);
    } catch (e) {
      debugPrint('Error saving badge data: $e');
    }
  }

  Future<void> _saveSubjectsUsed() async {
    try {
      final jsonString = jsonEncode(_subjectsUsed.toList());
      await _prefs?.setString(_subjectsUsedKey, jsonString);
    } catch (e) {
      debugPrint('Error saving subjects used: $e');
    }
  }

  List<Badge> get badges => List.unmodifiable(_badges);

  List<Badge> get unlockedBadges =>
      _badges.where((badge) => badge.isUnlocked).toList();

  List<Badge> get lockedBadges =>
      _badges.where((badge) => !badge.isUnlocked).toList();

  int get unlockedCount => unlockedBadges.length;
  int get totalCount => _badges.length;

  double get completionPercentage => totalCount > 0
      ? (unlockedCount / totalCount) * 100
      : 0.0;

  /// Check and unlock badges based on current stats
  Future<List<Badge>> checkBadges({
    required int totalQuestions,
    required int currentStreak,
    String? subject,
  }) async {
    final newlyUnlocked = <Badge>[];

    // Track subject if provided
    if (subject != null && subject.isNotEmpty) {
      _subjectsUsed.add(subject);
      await _saveSubjectsUsed();
    }

    // Check each badge
    for (int i = 0; i < _badges.length; i++) {
      final badge = _badges[i];

      if (badge.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (badge.id) {
        case 'first_question':
          shouldUnlock = totalQuestions >= 1;
          break;

        case 'week_warrior':
          shouldUnlock = currentStreak >= 7;
          break;

        case 'subject_explorer':
          shouldUnlock = _subjectsUsed.length >= 3;
          break;

        case 'early_bird':
          final now = DateTime.now();
          shouldUnlock = now.hour < 9 && totalQuestions >= 1;
          break;

        case 'helpful_parent':
          shouldUnlock = totalQuestions >= 20;
          break;
      }

      if (shouldUnlock) {
        final unlockedBadge = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        _badges[i] = unlockedBadge;
        newlyUnlocked.add(unlockedBadge);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await _saveBadgeData();
    }

    return newlyUnlocked;
  }

  /// Manually unlock a badge (for testing)
  Future<void> unlockBadge(String badgeId) async {
    final index = _badges.indexWhere((b) => b.id == badgeId);
    if (index != -1 && !_badges[index].isUnlocked) {
      _badges[index] = _badges[index].copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      await _saveBadgeData();
    }
  }

  /// Get progress for a specific badge
  BadgeProgress getBadgeProgress(
    String badgeId, {
    required int totalQuestions,
    required int currentStreak,
  }) {
    final badge = _badges.firstWhere(
      (b) => b.id == badgeId,
      orElse: () => _badges.first,
    );

    if (badge.isUnlocked) {
      return BadgeProgress(
        current: badge.requirement,
        required: badge.requirement,
        percentage: 100.0,
      );
    }

    int current = 0;

    switch (badge.id) {
      case 'first_question':
      case 'helpful_parent':
        current = totalQuestions;
        break;

      case 'week_warrior':
        current = currentStreak;
        break;

      case 'subject_explorer':
        current = _subjectsUsed.length;
        break;

      case 'early_bird':
        current = 0; // This is a time-based badge
        break;
    }

    final percentage = (current / badge.requirement * 100).clamp(0.0, 100.0);

    return BadgeProgress(
      current: current,
      required: badge.requirement,
      percentage: percentage,
    );
  }

  /// Reset all badges (for testing or user request)
  Future<void> resetAllBadges() async {
    _initializeBadges();
    _subjectsUsed.clear();
    await _saveBadgeData();
    await _saveSubjectsUsed();
  }
}

class BadgeProgress {
  final int current;
  final int required;
  final double percentage;

  const BadgeProgress({
    required this.current,
    required this.required,
    required this.percentage,
  });
}
