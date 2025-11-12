import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';

class ProfileService {
  static const String _profilesKey = 'child_profiles';
  static const String _activeProfileKey = 'active_profile_id';
  static const int _maxFreeProfiles = 1;
  static const int _maxPremiumProfiles = 3;

  // Singleton pattern
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  List<ChildProfile> _profiles = [];
  String? _activeProfileId;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProfiles();
    await _loadActiveProfile();
  }

  Future<void> _loadProfiles() async {
    try {
      final jsonString = _prefs?.getString(_profilesKey);
      if (jsonString != null) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _profiles = jsonData
            .map((json) => ChildProfile.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      _profiles = [];
    }
  }

  Future<void> _saveProfiles() async {
    try {
      final jsonData = _profiles.map((profile) => profile.toJson()).toList();
      final jsonString = jsonEncode(jsonData);
      await _prefs?.setString(_profilesKey, jsonString);
    } catch (e) {
      debugPrint('Error saving profiles: $e');
    }
  }

  Future<void> _loadActiveProfile() async {
    _activeProfileId = _prefs?.getString(_activeProfileKey);

    // If no active profile but profiles exist, set first as active
    if (_activeProfileId == null && _profiles.isNotEmpty) {
      _activeProfileId = _profiles.first.id;
      await _saveActiveProfile();
    }
  }

  Future<void> _saveActiveProfile() async {
    if (_activeProfileId != null) {
      await _prefs?.setString(_activeProfileKey, _activeProfileId!);
    }
  }

  List<ChildProfile> get profiles => List.unmodifiable(_profiles);

  ChildProfile? get activeProfile {
    if (_activeProfileId == null) return null;
    try {
      return _profiles.firstWhere((p) => p.id == _activeProfileId);
    } catch (e) {
      return null;
    }
  }

  int get profileCount => _profiles.length;

  bool get hasProfiles => _profiles.isNotEmpty;

  bool canAddProfile(bool isPremium) {
    final maxProfiles = isPremium ? _maxPremiumProfiles : _maxFreeProfiles;
    return _profiles.length < maxProfiles;
  }

  int getMaxProfiles(bool isPremium) {
    return isPremium ? _maxPremiumProfiles : _maxFreeProfiles;
  }

  /// Add a new child profile
  Future<ChildProfile> addProfile({
    required String name,
    required int grade,
    required String emoji,
    required bool isPremium,
  }) async {
    if (!canAddProfile(isPremium)) {
      throw Exception(
        'Maximum profiles reached. ${isPremium ? 'Premium users' : 'Free users'} can have up to ${getMaxProfiles(isPremium)} profile(s).',
      );
    }

    final profile = ChildProfile.create(
      name: name,
      grade: grade,
      emoji: emoji,
    );

    _profiles.add(profile);
    await _saveProfiles();

    // Set as active if it's the first profile
    if (_profiles.length == 1) {
      await setActiveProfile(profile.id);
    }

    return profile;
  }

  /// Update an existing profile
  Future<void> updateProfile(ChildProfile updatedProfile) async {
    final index = _profiles.indexWhere((p) => p.id == updatedProfile.id);
    if (index != -1) {
      _profiles[index] = updatedProfile;
      await _saveProfiles();
    }
  }

  /// Delete a profile
  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((p) => p.id == profileId);
    await _saveProfiles();

    // If deleted profile was active, switch to first available or null
    if (_activeProfileId == profileId) {
      _activeProfileId = _profiles.isNotEmpty ? _profiles.first.id : null;
      await _saveActiveProfile();
    }
  }

  /// Set active profile
  Future<void> setActiveProfile(String profileId) async {
    if (_profiles.any((p) => p.id == profileId)) {
      _activeProfileId = profileId;
      await _saveActiveProfile();
    }
  }

  /// Increment question count for active profile
  Future<void> incrementQuestionCount() async {
    final profile = activeProfile;
    if (profile != null) {
      final updated = profile.copyWith(
        questionCount: profile.questionCount + 1,
        lastUsedAt: DateTime.now(),
      );
      await updateProfile(updated);
    }
  }

  /// Update streak for active profile
  Future<void> updateStreak(int currentStreak, int longestStreak) async {
    final profile = activeProfile;
    if (profile != null) {
      final updated = profile.copyWith(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastUsedAt: DateTime.now(),
      );
      await updateProfile(updated);
    }
  }

  /// Add subject to active profile
  Future<void> addSubject(String subject) async {
    final profile = activeProfile;
    if (profile != null) {
      final updatedSubjects = Set<String>.from(profile.subjectsUsed)
        ..add(subject);
      final updated = profile.copyWith(
        subjectsUsed: updatedSubjects,
      );
      await updateProfile(updated);
    }
  }

  /// Unlock badge for active profile
  Future<void> unlockBadge(String badgeId) async {
    final profile = activeProfile;
    if (profile != null && !profile.unlockedBadgeIds.contains(badgeId)) {
      final updatedBadges = List<String>.from(profile.unlockedBadgeIds)
        ..add(badgeId);
      final updated = profile.copyWith(
        unlockedBadgeIds: updatedBadges,
      );
      await updateProfile(updated);
    }
  }

  /// Get profile by ID
  ChildProfile? getProfileById(String profileId) {
    try {
      return _profiles.firstWhere((p) => p.id == profileId);
    } catch (e) {
      return null;
    }
  }

  /// Check if profile limit would be exceeded when downgrading
  bool wouldExceedLimitOnDowngrade() {
    return _profiles.length > _maxFreeProfiles;
  }

  /// Reset all profiles (for testing or user request)
  Future<void> resetAllProfiles() async {
    _profiles.clear();
    _activeProfileId = null;
    await _saveProfiles();
    await _prefs?.remove(_activeProfileKey);
  }
}
